# Gaming module
#
# Provides the Steam/gaming stack as a dedicated opt-in module.
# Hosts that want Steam or other gaming support can import this module
# without dragging in the rest of the desktop package set.

{ pkgs, ... }:

{
  # Graphics and 32-bit OpenGL support required by Steam
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  hardware.graphics.enable32Bit = true;

  # Video drivers: include modesetting and qxl (useful for VMs); add specific drivers
  # (intel/amdgpu/nvidia) if you passthrough a GPU.
  services.xserver.videoDrivers = [ "modesetting" "qxl" "amdgpu" ];

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
