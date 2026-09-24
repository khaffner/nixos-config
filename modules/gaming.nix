# Gaming module
#
# Provides the Steam/gaming stack as a dedicated opt-in module.
# Hosts that want Steam or other gaming support can import this module
# without dragging in the rest of the desktop package set.

{ pkgs, ... }:

{
  # Graphics and 32-bit OpenGL support required by Steam
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Gaming - Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    steamcmd
  ];
}
