{ pkgs, ... }:

{
  # Laptop / desktop module: GNOME, audio, browsers, Steam, ThinkPad hardware.

  networking.networkmanager.enable = true;
  users.users.kevin.extraGroups = [ "networkmanager" ];

  # X11 + GNOME (the Wayland session runs on top of this).
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "no";
    variant = "";
  };
  console.keyMap = "no";

  # Trim default GNOME apps. Keep utilitarian ones (text editor, calculator,
  # system monitor, disks, screenshot, calendar, clocks, logs, file-roller).
  environment.gnome.excludePackages = with pkgs; [
    epiphany         # GNOME Web (using Edge/Chrome instead)
    geary            # email client
    gnome-music
    gnome-maps
    gnome-weather
    gnome-contacts
    gnome-tour       # welcome tour
    gnome-characters # character picker
    yelp             # GNOME help browser
    simple-scan
  ];

  # Audio via PipeWire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.printing.enable = true;

  # Intel ThinkPad hardware.
  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics.enable32Bit = true;        # 32-bit GL/Vulkan for Steam
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.fwupd.enable = true;                # `fwupdmgr update` for BIOS/firmware
  services.thermald.enable = true;             # Intel thermal management
  services.fprintd.enable = true;              # Fingerprint reader (no-op if absent)

  # Steam.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;

  # Flatpak + xdg portals (required for Flatpak apps to integrate with GNOME).
  services.flatpak.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  environment.systemPackages = with pkgs; [
    microsoft-edge
    google-chrome
    firefox
    vscode
    signal-desktop
    wireguard-tools
  ];

  # Add Flathub on activation so `flatpak install <app>` Just Works later.
  system.activationScripts.flatpakSetup = {
    text = ''
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo || true
    '';
    deps = [ ];
  };
}
