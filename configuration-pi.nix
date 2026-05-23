# Raspberry Pi 4 Configuration (aarch64 Docker server)
#
# This config imports:
#   - modules/common.nix  (user, timezone, syncthing, base packages)
#   - modules/server.nix  (SSH, Docker)
#
# Setup: Same as server - see configuration-server.nix comments

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/common.nix
    ./modules/server.nix
  ];

  networking.hostName = "pi4";

  # Pi-specific bootloader (extlinux, not systemd-boot)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  system.stateVersion = "26.05";  # Don't change this
}
