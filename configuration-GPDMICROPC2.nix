# GPDMICROPC2 host configuration
#
# Goal:
# - Keep GPDMICROPC2 machine-specific hardware/boot/LUKS settings from the live config
# - Reuse shared modules so all hosts stay logically identical

{ pkgs, ... }:

{
  imports = [
    ./hosts/GPDMICROPC2/hardware-configuration.nix
    ./modules/common.nix
    ./modules/desktop.nix
    ./modules/hardware.nix
    <home-manager/nixos>
  ];

  # Host-specific identity
  networking.hostName = "GPDMICROPC2";

  # GPDMICROPC2 has a fingerprint reader.
  services.fprintd.enable = true;

  # US keyboard layout
  services.xserver.xkb.layout = "us";
  console.keyMap = "us";

  # Rotate screen. Consider changing to kernelParams like this https://nixos.wiki/wiki/GPD_Pocket
  services.xserver.monitorSection = ''
  Option "Rotate" "right"
  '';

  # Keep live bootloader setup
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep live swap LUKS device mapping
  boot.initrd.luks.devices."luks-7b3a601d-bd5c-4fbd-82ea-ba60adfaec7f".device = "/dev/disk/by-uuid/7b3a601d-bd5c-4fbd-82ea-ba60adfaec7f";

  system.stateVersion = "26.05";
}
