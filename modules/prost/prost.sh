#!/usr/bin/env bash
# The prost command. Nix prepends the PROST_* variables (see cli.nix) and api.sh.

usage() {
  cat <<USAGE
Usage: prost <command>

  overview               Table of every device's latest report
  html [FILE]            Write an HTML overview of all devices (default $PROST_STATE_DIR/overview.html)
  report                 Run the osquery queries now and write this device's report
  device-id              This device's Syncthing device ID
  add-device NAME ID     Pair with another Prost device (run on both devices the first time)
  remove-device NAME|ID  Unpair a device
  status                 Syncthing status: folder state, which devices are online, sync progress
  syncthing ARGS...      Run 'syncthing cli' against the Prost Syncthing instance

Reports live in $PROST_REPORTS_DIR. Pairings live in $PROST_SYNCTHING_DIR.
USAGE
}

cmd_report() {
  mkdir -p "$PROST_REPORTS_DIR"
  tmp=$(mktemp -p "$PROST_REPORTS_DIR" ".$PROST_NAME.json.XXXXXX")
  trap 'rm -f "$tmp"' EXIT

  report=$(jq -n \
    --arg name "$PROST_NAME" \
    --arg hostname "$(uname -n)" \
    --arg generatedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{name: $name, hostname: $hostname, generatedAt: $generatedAt, queries: {}}')

  while IFS= read -r key; do
    sql=$(jq -r --arg k "$key" '.[$k]' "$PROST_QUERIES_FILE")
    if ! result=$(osqueryi --json "$sql" 2>/dev/null) || ! jq -e . >/dev/null 2>&1 <<<"$result"; then
      echo "prost: query '$key' failed" >&2
      result=null
    fi
    report=$(jq --arg k "$key" --argjson r "$result" '.queries[$k] = $r' <<<"$report")
  done < <(jq -r 'keys[]' "$PROST_QUERIES_FILE")

  jq . <<<"$report" > "$tmp"
  chmod 0644 "$tmp"
  mv "$tmp" "$PROST_REPORTS_DIR/$PROST_NAME.json"
  trap - EXIT
}

cmd_overview() {
  shopt -s nullglob
  files=("$PROST_REPORTS_DIR"/*.json)
  if [ ${#files[@]} -eq 0 ]; then
    echo "No reports in $PROST_REPORTS_DIR yet." >&2
    exit 1
  fi
  {
    printf 'NAME\tHOST\tAGE_MIN\tOS\tKERNEL\tUP_DAYS\tLOAD1\tMEM%%\tROOT%%\tBAT%%\tIPV4\n'
    jq -c -f "$PROST_SUMMARY_JQ" "${files[@]}" \
      | jq -r '[.name, .host, .age, .os, .kernel, .up, .load, .mem, .disk, .battery, (.ipv4 | join(","))] | @tsv'
  } | column -t -s $'\t'
}

cmd_html() {
  local out=${1:-$PROST_STATE_DIR/overview.html} tmp
  shopt -s nullglob
  files=("$PROST_REPORTS_DIR"/*.json)
  if [ ${#files[@]} -eq 0 ]; then
    echo "No reports in $PROST_REPORTS_DIR yet." >&2
    exit 1
  fi
  tmp=$(mktemp "$out.XXXXXX")
  trap 'rm -f "$tmp"' EXIT
  {
    jq -c -f "$PROST_SUMMARY_JQ" "${files[@]}" \
      | jq -r -s --arg generated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg host "$(uname -n)" -f "$PROST_HTML_JQ"
    for f in "${files[@]}"; do
      printf '<details><summary>%s</summary><pre>' "$(jq -r '.name | @html' "$f")"
      jq . "$f" | jq -Rr '@html'
      printf '</pre></details>\n'
    done
    printf '</body></html>\n'
  } > "$tmp"
  chmod 0644 "$tmp"
  mv "$tmp" "$out"
  trap - EXIT
}

cmd_add_device() {
  local name=$1 id=$2
  api_setup
  api config/devices -X POST --json "$(jq -n --arg id "$id" --arg name "$name" \
    '{deviceID: $id, name: $name, introducer: true}')" >/dev/null
  api "config/folders/$PROST_FOLDER_ID" \
    | jq --arg id "$id" '.devices |= (map(select(.deviceID != $id)) + [{deviceID: $id}])' \
    | api "config/folders/$PROST_FOLDER_ID" -X PUT --json @- >/dev/null
  echo "Paired with $name ($id). Run 'sudo prost add-device' for this device on $name too if it has not been done."
}

cmd_remove_device() {
  local target=$1 id
  api_setup
  id=$(api config/devices | jq -r --arg t "$target" '.[] | select(.name == $t or .deviceID == $t) | .deviceID' | head -n1)
  if [ -z "$id" ]; then
    echo "prost: no paired device named '$target'" >&2
    exit 1
  fi
  api "config/devices/$id" -X DELETE >/dev/null
  echo "Removed $target ($id)."
}

cmd_status() {
  local status version folder conns stats devices my_id
  api_setup
  status=$(api system/status)
  version=$(api system/version | jq -r .version)
  folder=$(api "db/status?folder=$PROST_FOLDER_ID")
  conns=$(api system/connections)
  stats=$(api stats/device)
  devices=$(api config/devices)
  my_id=$(jq -r .myID <<<"$status")

  printf 'Syncthing %s, device ID %s, up %s\n' "$version" "$my_id" \
    "$(jq -r '.uptime | "\(. / 86400 | floor)d \((. % 86400) / 3600 | floor)h"' <<<"$status")"
  jq -r --arg folder "$PROST_FOLDER_ID" '"Folder \($folder): \(.state), \(.localFiles) local files, \(.globalFiles) global, \(.needFiles) needed, \((.errors // 0) + (.pullErrors // 0)) errors"' <<<"$folder"
  echo
  {
    printf 'NAME\tCONNECTED\tADDRESS\tLAST_SEEN\tSYNC%%\tVERSION\n'
    jq -r --arg me "$my_id" '.[] | select(.deviceID != $me) | .deviceID' <<<"$devices" | while IFS= read -r id; do
      completion=$(api "db/completion?folder=$PROST_FOLDER_ID&device=$id" | jq -r '.completion | round')
      jq -r --arg id "$id" --arg comp "$completion" --argjson conns "$conns" --argjson stats "$stats" '
        def dash: if . == null or . == "" then "-" else . end;
        .[] | select(.deviceID == $id)
        | $conns.connections[$id] as $conn | $stats[$id] as $stat
        | [ .name,
            (if $conn.connected then "yes" else "no" end),
            ($conn.address | dash),
            (($stat.lastSeen // "") | if . == "" or startswith("1970") then "never" else .[0:16] | sub("T"; " ") end),
            $comp,
            ($conn.clientVersion | dash) ] | @tsv' <<<"$devices"
    done
  } | column -t -s $'\t'
}

cmd_device_id() {
  api_setup
  api system/status | jq -r .myID
}

case "${1:-}" in
  overview)      cmd_overview ;;
  html)          cmd_html "${2:-}" ;;
  report)        cmd_report ;;
  device-id)     cmd_device_id ;;
  add-device)    [ $# -eq 3 ] || { usage >&2; exit 2; }; cmd_add_device "$2" "$3" ;;
  remove-device) [ $# -eq 2 ] || { usage >&2; exit 2; }; cmd_remove_device "$2" ;;
  status)        cmd_status ;;
  syncthing)     shift; syncthing cli "--home=$PROST_SYNCTHING_DIR" "--gui-address=unix://$PROST_GUI_SOCKET" "$@" ;;
  -h|--help|help|"") usage ;;
  *) usage >&2; exit 2 ;;
esac
