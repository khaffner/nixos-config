# Report generation and the aggregated HTML overview.

{ config, lib, ... }:

let
  cfg = config.services.prost;
  inherit (import ./common.nix) stateDir syncthingDir reportsDir;
  prost = cfg.package;
in
{
  config = lib.mkIf cfg.enable {
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
  };
}
