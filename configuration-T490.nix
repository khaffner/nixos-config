# T490 host configuration
#
# Goal:
# - Keep T490 aligned with T570/shared module setup
# - Enable T490-specific fingerprint support
# - Fill in hardware/boot/LUKS values after generating config on T490

{ ... }:

{
  imports = [
    # TODO: replace with T490-generated hardware file before first rebuild.
    # Example:
    # ./hosts/T490/hardware-configuration.nix

    ./modules/common.nix
    ./modules/desktop.nix
    ./modules/hardware.nix
    <home-manager/nixos>
  ];

  # Host-specific identity
  networking.hostName = "T490";

  # Norwegian keyboard layout
  services.xserver.xkb.layout = "no";
  console.keyMap = "no";

  # T490 has a fingerprint reader.
  services.fprintd.enable = true;

  # TODO (T490 install-specific): set bootloader and any LUKS mappings here.
  # Example:
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  # boot.initrd.luks.devices."luks-<uuid>".device = "/dev/disk/by-uuid/<uuid>";

  system.stateVersion = "26.05";
}