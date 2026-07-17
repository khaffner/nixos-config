# HTPC module - for living-room use on the GPD MicroPC 2
#
# Provides:
#   - a separate HTPC user account
#   - Kodi media center
#   - HDMI-CEC tooling
#   - normal GNOME login kept available alongside a dedicated HTPC login

{ pkgs, ... }:

{
  # Keep the regular GNOME login path intact and let the user choose
  # the dedicated HTPC account from GDM when they want Kodi.
  services.displayManager.autoLogin.enable = false;

  # Dedicated account for couch/TV use.
  # Use a temporary initial password so GDM can list and authenticate
  # the account cleanly. Change it after first login.
  users.users.htpc = {
    isNormalUser = true;
    createHome = true;
    description = "HTPC";
    home = "/home/htpc";
    extraGroups = [ "audio" "video" ];
    shell = pkgs.bash;
    initialPassword = "htpc";
  };

  # Media center components for Kodi + CEC remote support
  environment.systemPackages = with pkgs; [
    kodi
    libcec
  ];
}
