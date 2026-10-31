#!/usr/bin/env bash
# Helpers for talking to the Prost Syncthing instance over its root-only unix
# socket. Shared by the prost command and the init service; Nix prepends the
# PROST_* variables. Paths passed to api are relative to /rest/.

api_setup() {
  if [ ! -r "$PROST_SYNCTHING_DIR/config.xml" ]; then
    echo "prost: this command needs root (sudo), or the prost-syncthing service has not started yet" >&2
    exit 1
  fi
  api_key=$(xmllint --xpath 'string(configuration/gui/apikey)' "$PROST_SYNCTHING_DIR/config.xml")
}

api() {
  local path=$1; shift
  curl -sS --fail --unix-socket "$PROST_GUI_SOCKET" -H "X-API-Key: $api_key" "$@" "http://localhost/rest/$path"
}
