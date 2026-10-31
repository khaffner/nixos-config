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

{
  imports = [
    ./options.nix
    ./queries.nix
    ./cli.nix
    ./report.nix
    ./syncthing.nix
  ];
}
