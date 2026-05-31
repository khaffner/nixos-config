# Desktop Module - GNOME, Steam, browsers
#
# Provides:
#   - GNOME desktop environment
#   - Audio (PipeWire)
#   - Steam gaming
#   - Browsers (Edge, Chrome, Firefox)

{ pkgs, ... }:

{

  # Network management
  networking.networkmanager.enable = true;
  users.users.kevin.extraGroups = [ "networkmanager" ];

  # GNOME Desktop (with Wayland support)
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Norwegian keyboard layout
  services.xserver.xkb.layout = "no";
  console.keyMap = "no";

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
  security.rtkit.enable = true;  # Realtime priority
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;  # For Steam games
    pulse.enable = true;       # PulseAudio compatibility
  };

  services.printing.enable = true;

  # Graphics and Bluetooth
  hardware.graphics.enable32Bit = true;       # 32-bit graphics for Steam
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Gaming - Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;  # Performance mode for games

  # Programs with dedicated modules
  programs.firefox.enable = true;
  programs.vscode.enable = true;

  # XDG portals for GNOME
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];  # GNOME integration
  };

  environment.systemPackages = with pkgs; [
    microsoft-edge
    google-chrome
    signal-desktop
    wireguard-tools
    gnome-tweaks
    rpi-imager
    #bitwarden-desktop
  ];
}
