# T570 host configuration
#
# Goal:
# - Keep T570 machine-specific hardware/boot/LUKS settings from the live config
# - Reuse shared modules so T570 and T490 stay logically identical

{ pkgs, ... }:

{
  imports = [
    ./hosts/T570/hardware-configuration.nix
    ./modules/common.nix
    ./modules/desktop.nix
    ./modules/hardware.nix
    <home-manager/nixos>
  ];

  # Host-specific identity
  networking.hostName = "T570";

  # Norwegian keyboard layout
  services.xserver.xkb.layout = "no";
  console.keyMap = "no";

  # Keep live bootloader setup
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep live swap LUKS device mapping
  boot.initrd.luks.devices."luks-30aa08b2-a9b6-4c81-93b4-7b2f8def3f91".device = "/dev/disk/by-uuid/30aa08b2-a9b6-4c81-93b4-7b2f8def3f91";

  system.stateVersion = "26.05";
}