# Paths and helpers shared by the other modules. Not a NixOS module itself.

let
  stateDir = "/var/lib/prost";
  syncthingDir = "${stateDir}/syncthing";
in
rec {
  inherit stateDir syncthingDir;
  reportsDir = "${stateDir}/reports";
  guiSocket = "${syncthingDir}/gui.sock";
  folderId = "prost-reports";

  # Shell variables the scripts (api.sh, prost.sh) expect. Prepended to them
  # by the modules that use them.
  shellVars = ''
    PROST_STATE_DIR="${stateDir}"
    PROST_SYNCTHING_DIR="${syncthingDir}"
    PROST_REPORTS_DIR="${reportsDir}"
    PROST_GUI_SOCKET="${guiSocket}"
    PROST_FOLDER_ID="${folderId}"
  '';

  apiScript = builtins.readFile ./api.sh;
}
