# Laptop Configuration (ThinkPad T570/T590)
# 
# This config imports:
#   - modules/common.nix   (user, timezone, syncthing, base packages)
#   - modules/desktop.nix  (GNOME, Steam, browsers, flatpak)
#   - modules/docker.nix   (Docker + docker group)
#   - home/kevin.nix       (user-level config via Home Manager)
#
# Setup:
#   1. Add Home Manager channel:
#      sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager
#      sudo nix-channel --update
#   2. Copy hardware config:
#      sudo cp /etc/nixos/hardware-configuration.nix ~/code/nixos-config/
#   3. Create symlinks:
#      sudo ln -sf ~/code/nixos-config/configuration-laptop.nix /etc/nixos/configuration.nix
#      sudo ln -sf ~/code/nixos-config/hardware-configuration.nix /etc/nixos/hardware-configuration.nix
#      sudo ln -sf ~/code/nixos-config/modules /etc/nixos/modules
#      sudo ln -sf ~/code/nixos-config/home /etc/nixos/home
#   4. Apply:
#      sudo nixos-rebuild switch

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/common.nix
    ./modules/desktop.nix
    ./modules/docker.nix
    <home-manager/nixos>  # Channel-based Home Manager (no flakes)
  ];

  networking.hostName = "nixos-laptop";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Home Manager - manages user-level config (see home/kevin.nix)
  home-manager.useGlobalPkgs = true;      # Share system nixpkgs
  home-manager.useUserPackages = true;    # Install to /etc/profiles
  home-manager.users.kevin = import ./home/kevin.nix;

  system.stateVersion = "26.05";  # Don't change this
}
