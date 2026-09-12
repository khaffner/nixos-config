# Desktop Module - non-GNOME desktop extras
#
# Provides:
#   - Boot/graphics defaults for desktop hosts
#   - Steam gaming setup
#   - Browsers and desktop apps
#
# The GNOME-specific setup lives in gnome_light.nix so a host can opt into a
# clean GNOME desktop without the extra desktop applications stack.

{ pkgs, ... }:

{
  # Graphical boot splash + graphical LUKS unlock
  boot.plymouth.enable = true;
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "quiet" "splash" "rd.udev.log_level=3" ];

  # Graphics and Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Programs with dedicated modules
  programs.firefox.enable = true;
  programs.vscode.enable = true;

  environment.systemPackages = with pkgs; [
    vlc
    gparted
    xarchiver
    fastfetch
    rpi-imager
    firefoxpwa
    qbittorrent
    gnome-tweaks
    google-chrome
    signal-desktop
    microsoft-edge
    wireguard-tools
    bitwarden-desktop # Has EOL electron version, waiting for update
    nixos-artwork.wallpapers.binary-black
  ];
}
