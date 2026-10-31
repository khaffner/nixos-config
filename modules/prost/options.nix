# Options for services.prost.

{ config, lib, pkgs, ... }:

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

  # The built `prost` command, set by cli.nix for the other modules to use.
  options.services.prost.package = lib.mkOption {
    type = lib.types.package;
    internal = true;
    readOnly = true;
    description = "The prost command.";
  };
}
