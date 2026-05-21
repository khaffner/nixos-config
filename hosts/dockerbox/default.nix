{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/server.nix    # pulls in docker
    # Drop the machine's hardware-configuration.nix next to this file after
    # running `nixos-generate-config` on the target hardware, then uncomment:
    # ./hardware-configuration.nix
  ];

  networking.hostName = "REPLACEME";

  # Assumes UEFI. For BIOS-only hardware, switch to GRUB:
  #   boot.loader.grub.enable = true;
  #   boot.loader.grub.device = "/dev/sda";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Pin to the release you installed with and leave alone.
  system.stateVersion = "26.05";
}
