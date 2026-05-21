{ pkgs, ... }:

{
  # Per-user config managed by Home Manager. Loaded from
  # hosts/mainLaptop/default.nix; if you add HM to other hosts later,
  # extract the GNOME-only bits into a separate file.

  home.username = "kevin";
  home.homeDirectory = "/home/kevin";

  # Pin to the release you first activated HM with and leave alone — same
  # idea as system.stateVersion.
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.bash = {                                                                                                                                                                                                                          
    enable = true;                                                                                                                                                                                                                           
    shellAliases = {                                                                                                                                                                                                                         
      cls = "clear";                                                                                                                                                                                                                         
    };                                                                                                                                                                                                                                       
  };                                                                                                                                                                                                                                         
                   

  # GNOME Shell extensions need both the package installed AND the UUID
  # listed in enabled-extensions below. The UUIDs are stable identifiers
  # from extensions.gnome.org; don't confuse them with the nixpkgs attr.
  home.packages = with pkgs.gnomeExtensions; [
    dash-to-panel
  ];

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-panel@jderose9.github.com"
      ];
    };
  };

  # Declarative flatpak management.
  services.flatpak = {
    packages = [
      "org.raspberrypi.rpi-imager"
      "com.bitwarden.desktop"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}
