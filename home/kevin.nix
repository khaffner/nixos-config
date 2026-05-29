# Home Manager Configuration for user 'kevin'
#
# This manages user-level configuration (dotfiles, shell, GNOME settings).
# Changes here apply after: sudo nixos-rebuild switch
#
# Useful options to add:
#   programs.git.* - Git config (userName, userEmail, aliases)
#   programs.vim.* or programs.neovim.* - Editor config
#   programs.firefox.* - Browser bookmarks/settings
#   programs.bash.shellAliases - More shell aliases
#   services.flatpak.packages - Add more flatpak apps

{ pkgs, ... }:

{
  home.username = "kevin";
  home.homeDirectory = "/home/kevin";

  home.stateVersion = "26.05";  # Don't change this

  programs.home-manager.enable = true;

  # Bash shell configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      cls = "clear";
      # Add more aliases here, e.g.:
      # ll = "ls -lah";
      # gs = "git status";
    };
  };                                                                                                                                                                                                                                         
                   

  # GNOME extensions - conditionally included if GNOME is installed
  home.packages = if config.services.xserver.enable && config.services.xserver.desktopManager.gnome.enable then with pkgs.gnomeExtensions; [
    dash-to-panel
    appindicator
    wireguard-vpn-extension
  ] else [];

  # GNOME settings via dconf - conditionally applied if GNOME is installed
  dconf.settings = if config.services.xserver.enable && config.services.xserver.desktopManager.gnome.enable then {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";  # Dark mode
    };
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-panel@jderose9.github.com"
        "appindicatorsupport@rgcjonas.gmail.com"
        "gnome-wireguard-extension@SJBERTRAND.github.com"
      ];
    };
  } else {};
}
