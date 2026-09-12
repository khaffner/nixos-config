#!/usr/bin/env bash
set -u

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

run_git_pull() {
  if command -v git >/dev/null 2>&1; then
    echo "Pulling latest changes..."
    git pull --ff-only
    return $?
  fi

  if ! command -v nix >/dev/null 2>&1; then
    echo "Error: neither git nor nix is installed. Install one of them first." >&2
    exit 1
  fi

  echo "git is not installed; using nix-shell to run git pull..."
  nix-shell -p git --run "git -C '$repo_root' pull --ff-only"
}

ensure_home_manager_channel() {
  if nix-channel --list 2>/dev/null | grep -q '^home-manager'; then
    echo "Home Manager channel already present."
    return 0
  fi

  local version
  if command -v nixos-version >/dev/null 2>&1; then
    version="$(nixos-version 2>/dev/null | cut -d. -f1-2)"
  else
    version="$(grep '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d'"' -f2 | cut -d. -f1-2)"
  fi

  if [[ -z "$version" ]]; then
    echo "Unable to detect the current NixOS version to add the Home Manager channel." >&2
    exit 1
  fi

  echo "Adding Home Manager channel for NixOS $version..."
  nix-channel --add "https://github.com/nix-community/home-manager/archive/release-${version}.tar.gz" home-manager
  nix-channel --update
}

choose_config_file() {
  local host_name="${1:-$(hostname 2>/dev/null || uname -n 2>/dev/null || echo unknown)}"
  local default_candidate="configuration-${host_name}.nix"
  local -a configs=(configuration-*.nix)

  if [[ -f "$default_candidate" ]]; then
    printf '%s\n' "$default_candidate"
    return 0
  fi

  if [[ ${#configs[@]} -eq 0 ]]; then
    echo "No configuration files found in $repo_root" >&2
    exit 1
  fi

  echo "No configuration file found for hostname '$host_name'."
  echo "Available configuration files:"
  for cfg in "${configs[@]}"; do
    printf '  - %s\n' "$cfg"
  done

  local choice
  while true; do
    read -rp "Which configuration file should be used? [${configs[0]}]: " choice
    choice="${choice:-${configs[0]}}"
    if [[ -f "$choice" ]]; then
      printf '%s\n' "$choice"
      return 0
    fi
    echo "File not found: $choice"
  done
}

main() {
  run_git_pull || exit 1
  ensure_home_manager_channel || exit 1

  local host_name
  host_name="$(hostname 2>/dev/null || uname -n 2>/dev/null || echo unknown)"
  local config_name
  config_name="$(choose_config_file "$host_name")"

  local config_path="$repo_root/$config_name"
  if [[ -f "/etc/nixos/$config_name" ]]; then
    config_path="/etc/nixos/$config_name"
  fi

  echo "Using configuration: $config_path"
  sudo nixos-rebuild switch --impure -I "nixos-config=$config_path"
}

main "$@"
