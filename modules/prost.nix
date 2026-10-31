# Prost module - hourly osquery device reports, shared over Syncthing
#
# Provides:
#   - osquery, and an hourly timer that writes /var/lib/prost/reports/<host>.json
#   - A dedicated root Syncthing instance (own home, own ports, unix-socket API)
#     that syncs the reports folder with the other devices in the setup
#   - The `prost` command: overview, html, report, status, device-id, add-device
#   - /var/lib/prost/overview.html, regenerated whenever any device's report changes
#
# Peers are NOT part of the Nix config. Pair devices at runtime with
# `sudo prost add-device NAME ID`; the pairing is stored in
# /var/lib/prost/syncthing and survives rebuilds.
#
# Active when imported. Set services.prost.enable = false on a host to opt out.

{ config, lib, pkgs, ... }:

let
  cfg = config.services.prost;

  stateDir = "/var/lib/prost";
  syncthingDir = "${stateDir}/syncthing";
  reportsDir = "${stateDir}/reports";
  guiSocket = "${syncthingDir}/gui.sock";
  folderId = "prost-reports";

  # Queries set to null are dropped; everything else is run as-is.
  queries = lib.filterAttrs (_: sql: sql != null) cfg.queries;
  queriesFile = pkgs.writeText "prost-queries.json" (builtins.toJSON queries);

  # One summary object per report file. Shared by `prost overview` (terminal)
  # and `prost html` so the two never drift apart.
  summaryJq = pkgs.writeText "prost-summary.jq" ''
    def row0(q): (q // [])[0] // {};
    def num: tonumber? // 0;
    def pct(used; total): if total > 0 then ((used / total * 100) | round) else "-" end;
    {
      name: .name,
      host: .hostname,
      generatedAt: .generatedAt,
      age: (((now - (.generatedAt | fromdateiso8601)) / 60) | floor),
      os: ((row0(.queries.os_version) | "\(.name // "?") \(.version // "")") | gsub("\\s+$"; "")),
      kernel: (row0(.queries.kernel).version // "-"),
      up: (row0(.queries.uptime).days // "-"),
      load: (([.queries.load_average // [] | .[] | select(.period == "1m") | .average][0]) // "-"),
      mem: (row0(.queries.memory) | pct((.memory_total | num) - (.memory_available | num); (.memory_total | num))),
      disk: (([.queries.disks // [] | .[] | select(.path == "/")][0] // {}) | pct((.size_bytes | num) - (.available_bytes | num); (.size_bytes | num))),
      ipv4: [.queries.interfaces // [] | .[] | select(.address | test("^[0-9.]+$")) | .address],
      ports: [.queries.listening_ports // [] | .[] | "\(.port)/\(.protocol) \(.process // "?")"] | unique,
      battery: (row0(.queries.battery).percent_remaining // "-")
    }
  '';

  # Turns the slurped summaries into a single self-contained HTML page.
  htmlJq = pkgs.writeText "prost-html.jq" ''
    def cell: "<td>\(tostring | @html)</td>";
    def pct_cell:
      if . == "-" then "<td>-</td>"
      else "<td class=\"\(if . >= 90 then "bad" elif . >= 75 then "warn" else "" end)\">\(.)%</td>" end;
    def list_cell: "<td class=\"list\">\(map(@html) | join("<br>"))</td>";
    def row:
      "<tr class=\"\(if .age > 120 then "stale" else "" end)\">"
      + (.name | cell) + (.host | cell) + (.age | cell) + (.os | cell) + (.kernel | cell)
      + (.up | cell) + (.load | cell) + (.mem | pct_cell) + (.disk | pct_cell) + (.battery | cell)
      + (.ipv4 | list_cell) + (.ports | list_cell)
      + "</tr>";
    "<!doctype html>
    <html lang=\"en\"><head><meta charset=\"utf-8\"><title>Prost</title>
    <style>
      body { background: #1e1e1e; color: #d4d4d4; font-family: system-ui, sans-serif; margin: 2em; }
      h1 { font-weight: 600; } p { color: #9a9a9a; }
      table { border-collapse: collapse; background: #252526; }
      th, td { border: 1px solid #3e3e42; padding: 6px 10px; text-align: left; vertical-align: top; white-space: nowrap; }
      th { background: #2d2d30; color: #cccccc; font-weight: 600; }
      tr:hover { background: #2a2d2e; }
      tr.stale td:first-child { color: #f48771; }
      td.warn { color: #e5c07b; } td.bad { color: #f48771; font-weight: 600; }
      td.list { font-family: monospace; font-size: 0.9em; }
      details { margin-top: 1em; } summary { cursor: pointer; }
      pre { background: #252526; padding: 1em; overflow-x: auto; }
    </style></head><body>
    <h1>&#127867; Prost</h1>
    <p>Generated \($generated) on \($host | @html). \(length) device(s). Name shown in red: report older than two hours.</p>
    <table><thead><tr>
    <th>Name</th><th>Host</th><th>Age (min)</th><th>OS</th><th>Kernel</th><th>Up (days)</th><th>Load</th><th>Mem</th><th>Root</th><th>Battery</th><th>IPv4</th><th>Listening ports</th>
    </tr></thead><tbody>
    \(sort_by(.name) | map(row) | join("\n"))
    </tbody></table>
    <h2>Raw reports</h2>"
  '';

  folderJson = builtins.toJSON {
    id = folderId;
    label = "Prost reports";
    path = reportsDir;
    type = "sendreceive";
    fsWatcherEnabled = true;
    rescanIntervalS = 3600;
    devices = [ ];
  };

  optionsJson = builtins.toJSON {
    listenAddresses = [
      "tcp://0.0.0.0:${toString cfg.syncthing.port}"
      "quic://0.0.0.0:${toString cfg.syncthing.port}"
      "dynamic+https://relays.syncthing.net/endpoint"
    ];
    localAnnouncePort = cfg.syncthing.discoveryPort;
    localAnnounceMCAddr = "[ff12::8384]:${toString cfg.syncthing.discoveryPort}";
    urAccepted = -1;
    crashReportingEnabled = false;
  };

  # Shared by the CLI and the init service: talk to the Prost Syncthing
  # instance over its root-only unix socket. Paths are relative to /rest/.
  apiHelper = ''
    if [ ! -r ${syncthingDir}/config.xml ]; then
      echo "prost: this command needs root (sudo), or the prost-syncthing service has not started yet" >&2
      exit 1
    fi
    api_key=$(xmllint --xpath 'string(configuration/gui/apikey)' ${syncthingDir}/config.xml)
    api() {
      local path=$1; shift
      curl -sS --fail --unix-socket ${guiSocket} -H "X-API-Key: $api_key" "$@" "http://localhost/rest/$path"
    }
  '';

  prost = pkgs.writeShellApplication {
    name = "prost";
    runtimeInputs = [ cfg.osqueryPackage cfg.syncthingPackage pkgs.curl pkgs.jq pkgs.libxml2 pkgs.coreutils pkgs.util-linux ];
    text = ''
      usage() {
        cat <<USAGE
      Usage: prost <command>

        overview               Table of every device's latest report
        html [FILE]            Write an HTML overview of all devices (default ${stateDir}/overview.html)
        report                 Run the osquery queries now and write this device's report
        device-id              This device's Syncthing device ID
        add-device NAME ID     Pair with another Prost device (run on both devices the first time)
        remove-device NAME|ID  Unpair a device
        status                 Syncthing status: folder state, which devices are online, sync progress
        syncthing ARGS...      Run 'syncthing cli' against the Prost Syncthing instance

      Reports live in ${reportsDir}. Pairings live in ${syncthingDir}.
      USAGE
      }

      cmd_report() {
        mkdir -p ${reportsDir}
        tmp=$(mktemp -p ${reportsDir} .${cfg.name}.json.XXXXXX)
        trap 'rm -f "$tmp"' EXIT

        report=$(jq -n \
          --arg name ${lib.escapeShellArg cfg.name} \
          --arg hostname "$(uname -n)" \
          --arg generatedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
          '{name: $name, hostname: $hostname, generatedAt: $generatedAt, queries: {}}')

        while IFS= read -r key; do
          sql=$(jq -r --arg k "$key" '.[$k]' ${queriesFile})
          if ! result=$(osqueryi --json "$sql" 2>/dev/null) || ! jq -e . >/dev/null 2>&1 <<<"$result"; then
            echo "prost: query '$key' failed" >&2
            result=null
          fi
          report=$(jq --arg k "$key" --argjson r "$result" '.queries[$k] = $r' <<<"$report")
        done < <(jq -r 'keys[]' ${queriesFile})

        jq . <<<"$report" > "$tmp"
        chmod 0644 "$tmp"
        mv "$tmp" ${reportsDir}/${cfg.name}.json
        trap - EXIT
      }

      cmd_overview() {
        shopt -s nullglob
        files=(${reportsDir}/*.json)
        if [ ''${#files[@]} -eq 0 ]; then
          echo "No reports in ${reportsDir} yet." >&2
          exit 1
        fi
        {
          printf 'NAME\tHOST\tAGE_MIN\tOS\tKERNEL\tUP_DAYS\tLOAD1\tMEM%%\tROOT%%\tBAT%%\tIPV4\n'
          jq -c -f ${summaryJq} "''${files[@]}" \
            | jq -r '[.name, .host, .age, .os, .kernel, .up, .load, .mem, .disk, .battery, (.ipv4 | join(","))] | @tsv'
        } | column -t -s $'\t'
      }

      cmd_html() {
        local out=''${1:-${stateDir}/overview.html} tmp
        shopt -s nullglob
        files=(${reportsDir}/*.json)
        if [ ''${#files[@]} -eq 0 ]; then
          echo "No reports in ${reportsDir} yet." >&2
          exit 1
        fi
        tmp=$(mktemp "$out.XXXXXX")
        trap 'rm -f "$tmp"' EXIT
        {
          jq -c -f ${summaryJq} "''${files[@]}" \
            | jq -r -s --arg generated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg host "$(uname -n)" -f ${htmlJq}
          for f in "''${files[@]}"; do
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
        ${apiHelper}
        api config/devices -X POST --json "$(jq -n --arg id "$id" --arg name "$name" \
          '{deviceID: $id, name: $name, introducer: true}')" >/dev/null
        api config/folders/${folderId} \
          | jq --arg id "$id" '.devices |= (map(select(.deviceID != $id)) + [{deviceID: $id}])' \
          | api config/folders/${folderId} -X PUT --json @- >/dev/null
        echo "Paired with $name ($id). Run 'sudo prost add-device' for this device on $name too if it has not been done."
      }

      cmd_remove_device() {
        local target=$1 id
        ${apiHelper}
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
        ${apiHelper}
        status=$(api system/status)
        version=$(api system/version | jq -r .version)
        folder=$(api "db/status?folder=${folderId}")
        conns=$(api system/connections)
        stats=$(api stats/device)
        devices=$(api config/devices)
        my_id=$(jq -r .myID <<<"$status")

        printf 'Syncthing %s, device ID %s, up %s\n' "$version" "$my_id" \
          "$(jq -r '.uptime | "\(. / 86400 | floor)d \((. % 86400) / 3600 | floor)h"' <<<"$status")"
        jq -r '"Folder ${folderId}: \(.state), \(.localFiles) local files, \(.globalFiles) global, \(.needFiles) needed, \((.errors // 0) + (.pullErrors // 0)) errors"' <<<"$folder"
        echo
        {
          printf 'NAME\tCONNECTED\tADDRESS\tLAST_SEEN\tSYNC%%\tVERSION\n'
          jq -r --arg me "$my_id" '.[] | select(.deviceID != $me) | .deviceID' <<<"$devices" | while IFS= read -r id; do
            completion=$(api "db/completion?folder=${folderId}&device=$id" | jq -r '.completion | round')
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
        ${apiHelper}
        api system/status | jq -r .myID
      }

      case "''${1:-}" in
        overview)      cmd_overview ;;
        html)          cmd_html "''${2:-}" ;;
        report)        cmd_report ;;
        device-id)     cmd_device_id ;;
        add-device)    [ $# -eq 3 ] || { usage >&2; exit 2; }; cmd_add_device "$2" "$3" ;;
        remove-device) [ $# -eq 2 ] || { usage >&2; exit 2; }; cmd_remove_device "$2" ;;
        status)        cmd_status ;;
        syncthing)     shift; syncthing cli --home=${syncthingDir} --gui-address=unix://${guiSocket} "$@" ;;
        -h|--help|help|"") usage ;;
        *) usage >&2; exit 2 ;;
      esac
    '';
  };
in
{
  options.services.prost = {
    enable = lib.mkEnableOption "Prost: hourly osquery reports shared over a dedicated Syncthing instance" // {
      default = true;
    };

    osqueryPackage = lib.mkPackageOption pkgs "osquery" { };
    syncthingPackage = lib.mkPackageOption pkgs "syncthing" { };

    name = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      defaultText = lib.literalExpression "config.networking.hostName";
      description = "Name of this device. Its report is written as <name>.json, so it must be unique across the setup.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "How often to generate the report, as a systemd OnCalendar expression.";
    };

    queries = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
      default = { };
      example = lib.literalExpression ''
        {
          users = "SELECT username, uid, shell FROM users WHERE uid >= 1000;";
          battery = null;
        }
      '';
      description = ''
        osquery SQL queries to run, keyed by the name they get in the report.
        Merged with the built-in defaults; set a name to null to drop a
        built-in query.
      '';
    };

    syncthing = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 22001;
        description = "TCP and UDP (QUIC) port the Prost Syncthing instance listens on. Deliberately not Syncthing's default 22000.";
      };

      discoveryPort = lib.mkOption {
        type = lib.types.port;
        default = 21028;
        description = "UDP port for LAN discovery between Prost instances. Deliberately not Syncthing's default 21027, which a regular instance on the same host may own.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open the sync and LAN discovery ports in the firewall. Not required: devices also find each other through global discovery and relays.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Built-in queries. Each is mkDefault so a host can override or null them
    # per name through services.prost.queries.
    services.prost.queries = lib.mapAttrs (_: lib.mkDefault) {
      osquery = "SELECT version FROM osquery_info;";
      system_info = "SELECT hostname, uuid, hardware_vendor, hardware_model, cpu_brand, cpu_physical_cores, cpu_logical_cores, physical_memory FROM system_info;";
      os_version = "SELECT name, version, platform, arch FROM os_version;";
      kernel = "SELECT version FROM kernel_info;";
      uptime = "SELECT days, hours, minutes, total_seconds FROM uptime;";
      load_average = "SELECT period, average FROM load_average;";
      memory = "SELECT memory_total, memory_free, memory_available, swap_total, swap_free FROM memory_info;";
      disks = "SELECT path, device, type, blocks * blocks_size AS size_bytes, blocks_available * blocks_size AS available_bytes FROM mounts WHERE blocks > 0 AND (device LIKE '/dev/%' OR type IN ('zfs', 'btrfs')) ORDER BY path;";
      interfaces = "SELECT interface, address, mask FROM interface_addresses WHERE interface != 'lo' ORDER BY interface;";
      listening_ports = "SELECT p.port, CASE p.protocol WHEN 6 THEN 'tcp' WHEN 17 THEN 'udp' ELSE p.protocol END AS protocol, p.address, pr.name AS process FROM listening_ports p LEFT JOIN processes pr ON p.pid = pr.pid WHERE p.port > 0 AND p.address NOT IN ('127.0.0.1', '::1') ORDER BY p.port;";
      battery = "SELECT percent_remaining, state, cycle_count, health FROM battery;";
    };

    environment.systemPackages = [ prost ];

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 root root -"
      "d ${syncthingDir} 0700 root root -"
      "d ${reportsDir} 0755 root root -"
    ];

    # The report job.
    systemd.services.prost-report = {
      description = "Prost: generate osquery device report";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe prost} report";
      };
    };

    systemd.timers.prost-report = {
      description = "Prost: generate osquery device report (${cfg.interval})";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnCalendar = cfg.interval;
        RandomizedDelaySec = "5min";
        Persistent = true;
      };
    };

    # Keep the aggregated HTML overview current: regenerate it whenever a
    # report (ours or a synced one) changes in the reports folder.
    systemd.paths.prost-overview = {
      description = "Prost: watch the reports folder";
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathChanged = reportsDir;
        Unit = "prost-overview.service";
      };
    };

    systemd.services.prost-overview = {
      description = "Prost: regenerate the HTML overview";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe prost} html";
      };
    };

    # The dedicated Syncthing instance. It generates its own identity and
    # config in ${syncthingDir} on first start.
    systemd.services.prost-syncthing = {
      description = "Prost: dedicated Syncthing instance";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = {
        HOME = syncthingDir;
        STNOUPGRADE = "1";
        STNODEFAULTFOLDER = "1";
      };
      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          "${lib.getExe cfg.syncthingPackage} serve"
          "--home=${syncthingDir}"
          "--gui-address=unix://${guiSocket}"
          "--no-browser"
          "--no-restart"
          "--no-upgrade"
        ];
        # Syncthing exits with 3 (restart) or 4 (upgrade) when asked to
        # restart through its API; let systemd bring it back.
        Restart = "on-failure";
        RestartSec = 5;
        SuccessExitStatus = "3 4";
        RestartForceExitStatus = "3 4";
      };
    };

    # Apply the parts of the Syncthing config that come from Nix (ports,
    # the shared folder) on every start and rebuild. Peers are left alone.
    systemd.services.prost-syncthing-init = {
      description = "Prost: configure the dedicated Syncthing instance";
      wantedBy = [ "multi-user.target" ];
      after = [ "prost-syncthing.service" ];
      bindsTo = [ "prost-syncthing.service" ];
      path = [ pkgs.curl pkgs.jq pkgs.libxml2 pkgs.coreutils ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail

        until [ -s ${syncthingDir}/config.xml ]; do sleep 1; done
        ${apiHelper}

        # Wait until the API answers.
        api noauth/health --retry 60 --retry-delay 2 --retry-all-errors >/dev/null

        api config/options -X PATCH --json ${lib.escapeShellArg optionsJson} >/dev/null

        # Create the shared folder once; after that its device list belongs
        # to `prost add-device` and must not be reset here.
        if ! api config/folders/${folderId} >/dev/null 2>&1; then
          api config/folders -X POST --json ${lib.escapeShellArg folderJson} >/dev/null
        fi

        if [ "$(api config/restart-required | jq -r .requiresRestart)" = true ]; then
          api system/restart -X POST >/dev/null
        fi
      '';
    };

    networking.firewall = lib.mkIf cfg.syncthing.openFirewall {
      allowedTCPPorts = [ cfg.syncthing.port ];
      allowedUDPPorts = [ cfg.syncthing.port cfg.syncthing.discoveryPort ];
    };
  };
}
