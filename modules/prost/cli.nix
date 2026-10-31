# The `prost` command.

{ config, lib, pkgs, ... }:

let
  cfg = config.services.prost;
  inherit (import ./common.nix) shellVars apiScript;

  # Queries set to null are dropped; everything else is run as-is.
  queries = lib.filterAttrs (_: sql: sql != null) cfg.queries;
  queriesFile = pkgs.writeText "prost-queries.json" (builtins.toJSON queries);

  # One summary object per report file. Shared by `prost overview` (terminal)
  # and `prost html` so the two never drift apart.
  summaryJq = ./jq/summary.jq;

  # Turns the slurped summaries into a single self-contained HTML page.
  htmlJq = ./jq/html.jq;

  prost = pkgs.writeShellApplication {
    name = "prost";
    runtimeInputs = [ cfg.osqueryPackage cfg.syncthingPackage pkgs.curl pkgs.jq pkgs.libxml2 pkgs.coreutils pkgs.util-linux ];
    text = ''
      ${shellVars}
      PROST_NAME=${lib.escapeShellArg cfg.name}
      PROST_QUERIES_FILE=${queriesFile}
      PROST_SUMMARY_JQ=${summaryJq}
      PROST_HTML_JQ=${htmlJq}
      ${apiScript}
      ${builtins.readFile ./prost.sh}
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    services.prost.package = prost;
    environment.systemPackages = [ prost ];
  };
}
