{ ... }:

{
  imports = [
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/docker.nix
    ./hardware-configuration.nix
  ];

  # Home Manager runs as part of `nixos-rebuild switch` for this host.
  # useGlobalPkgs shares the system nixpkgs (no duplicate evaluation);
  # useUserPackages installs HM packages into /etc/profiles so they show up
  # for every login shell instead of just ~/.nix-profile.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.kevin = import ../../home/kevin.nix;

  networking.hostName = "REPLACEME";

  # Bootloader (systemd-boot for UEFI; switch to grub if BIOS).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # NixOS state version — set to the release you installed with and leave alone.
  system.stateVersion = "26.05";
}
