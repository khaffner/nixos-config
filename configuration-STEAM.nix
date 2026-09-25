# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hosts/STEAM/hardware-configuration.nix
      /etc/nixos/modules/common.nix
      /etc/nixos/modules/gaming.nix
      /etc/nixos/modules/ssh-server.nix
      <home-manager/nixos>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # AMD GPU passthrough guest: make sure the firmware for the passed-through card
  # is available inside the VM and load the real GPU driver instead of virtual
  # display drivers.
  hardware.enableRedistributableFirmware = true;
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Just because it's a VM
  services.qemuGuest.enable = true;

  networking.hostName = "STEAM"; # Define your hostname.

  # Remote-gaming-first desktop: use a lightweight session manager and disable any
  # lock/sleep behavior so the box stays ready for Steam remote play.
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = "kevin";
  };
  services.displayManager.defaultSession = "steam";

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  systemd.services."getty@tty1".enable = false;

  home-manager.users.kevin = {
    systemd.user.services.steam-autostart = {
      Unit = {
        Description = "Launch Steam after login";
        After = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 5; exec ${pkgs.steam}/bin/steam -silent'";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment? DO NOT EDIT

}
