# The dedicated Syncthing instance and its Nix-managed configuration.

{ config, lib, pkgs, ... }:

let
  cfg = config.services.prost;
  inherit (import ./common.nix)
    syncthingDir reportsDir guiSocket folderId shellVars apiScript;

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
in
{
  config = lib.mkIf cfg.enable {
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
        ${shellVars}
        ${apiScript}
        api_setup

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
