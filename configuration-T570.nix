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
    <home-manager/nixos>
  ];

  # Host-specific identity
  networking.hostName = "T570";

  # Keep live bootloader setup
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep live swap LUKS device mapping
  boot.initrd.luks.devices."luks-30aa08b2-a9b6-4c81-93b4-7b2f8def3f91".device = "/dev/disk/by-uuid/30aa08b2-a9b6-4c81-93b4-7b2f8def3f91";

  # Keep hardware support from current laptop profile
  hardware.cpu.intel.updateMicrocode = true;
  services.fwupd.enable = true;
  services.thermald.enable = true;

  # Home Manager user config
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.kevin = import ./home/kevin.nix;

  system.stateVersion = "26.05";
}