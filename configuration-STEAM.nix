# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hosts/STEAM/hardware-configuration.nix
      /etc/nixos/modules/common.nix
      /etc/nixos/modules/gnome_light.nix
      /etc/nixos/modules/gaming.nix
      <home-manager/nixos>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "STEAM"; # Define your hostname.

  # Configure console keymap
  console.keyMap = "no";

  nixpkgs.config.allowUnfree = true;  # Allow proprietary software such as Steam

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment? DO NOT EDIT

}
