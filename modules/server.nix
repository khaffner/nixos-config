# Server Module - SSH + Docker
#
# Imported by: configuration-server.nix, configuration-pi.nix
#
# Provides:
#   - SSH server
#   - Docker (via docker.nix)

{ ... }:

{
  imports = [ ./docker.nix ];

  # SSH server (not in common.nix so laptop doesn't expose SSH)
  services.openssh.enable = true;
}
