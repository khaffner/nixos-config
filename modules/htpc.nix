# HTPC module - for living-room use on the GPD MicroPC 2
#
# Provides:
#   - a separate HTPC user account
#   - Kodi media center
#   - HDMI-CEC tooling
#   - normal GNOME login kept available alongside a dedicated HTPC login

{ pkgs, ... }:

{
  # Media center components for Kodi + CEC remote support
  environment.systemPackages = with pkgs; [
    kodi
    libcec
  ];
}
