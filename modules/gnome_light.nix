# GNOME light module
#
# Provides the base GNOME desktop without the extra gaming/browser stack.
# This is intentionally minimal so other hosts can add a clean GNOME desktop,
# and the Steam host can opt into GNOME without the rest of the desktop extras.

{ pkgs, lib, ... }:

{
  # Default keyboard layout
  services.xserver.xkb.layout = lib.mkDefault "no";
  console.keyMap = lib.mkDefault "no";

  # GNOME Desktop (with Wayland support)
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Remove unwanted default GNOME apps
  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    gnome-music
    gnome-maps
    gnome-weather
    gnome-contacts
    gnome-tour
    gnome-characters
    yelp
    simple-scan
  ];

  services.xserver.excludePackages = with pkgs; [
    xterm
  ];

  # Audio via PipeWire (replaces PulseAudio)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # WireGuard via NetworkManager for GNOME tray toggling.
  networking.wireguard.enable = true;
  programs.nm-applet.enable = true;

  # XDG portals for GNOME
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };
}
