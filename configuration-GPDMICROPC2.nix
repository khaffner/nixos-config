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
    ./modules/htpc.nix
    ./modules/hardware.nix
    #./modules/fingerprint-mafp8800.nix # Temporary until proper/native support
    <home-manager/nixos>
  ];

  # Host-specific identity
  networking.hostName = "GPDMICROPC2";

  # US keyboard layout
  services.xserver.xkb.layout = "us";
  console.keyMap = "us";

  # Internal panel (DSI-1) is physically mounted rotated 90°. Rotate at the kernel
  # level so the boot console, GDM, and the GNOME/Wayland session all come up upright.
  # (The old services.xserver.monitorSection only affected Xorg — ignored under Wayland.)
  boot.kernelParams = [
    "fbcon=rotate:1"                               # text console / early boot: 90° clockwise
    "video=DSI-1:panel_orientation=right_side_up"  # DRM panel orientation: honored by Wayland + Xorg + GDM
  ];

  # Keep live bootloader setup
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Keep live swap LUKS device mapping
  boot.initrd.luks.devices."luks-7b3a601d-bd5c-4fbd-82ea-ba60adfaec7f".device = "/dev/disk/by-uuid/7b3a601d-bd5c-4fbd-82ea-ba60adfaec7f";

  system.stateVersion = "26.05";
}
