# Server Configuration (x86_64 headless Docker server)
#
# This config imports:
#   - modules/common.nix  (user, timezone, syncthing, base packages)
#   - modules/server.nix  (SSH, Docker)
#
# Setup:
#   1. Copy hardware config: sudo cp /etc/nixos/hardware-configuration.nix ~/code/nixos-config/
#   2. Create symlinks:
#      sudo ln -sf ~/code/nixos-config/configuration-server.nix /etc/nixos/configuration.nix
#      sudo ln -sf ~/code/nixos-config/hardware-configuration.nix /etc/nixos/hardware-configuration.nix
#      sudo ln -sf ~/code/nixos-config/modules /etc/nixos/modules
#   3. Apply: sudo nixos-rebuild switch

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/common.nix
    ./modules/server.nix
  ];

  networking.hostName = "dockerbox";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "26.05";  # Don't change this
}
