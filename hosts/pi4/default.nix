{ modulesPath, ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/server.nix    # pulls in docker

    # SD image builder. Only consumed when you explicitly build the image:
    #   nix build .#nixosConfigurations.pi4.config.system.build.sdImage
    # Doesn't affect normal `nixos-rebuild switch` once the Pi is running.
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  networking.hostName = "REPLACEME";

  # Pi 4 boots via the Pi firmware → U-Boot → extlinux. No UEFI, no grub.
  # The `nixos-hardware.nixosModules.raspberry-pi-4` import in flake.nix handles
  # the kernel, firmware blobs, and GPU memory split.
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Don't waste minutes gzipping the image during builds.
  sdImage.compressImage = false;

  # Pin to the release you installed with and leave alone.
  system.stateVersion = "26.05";
}
