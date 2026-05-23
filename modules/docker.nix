# Docker Module
#
# Imported by: configuration-laptop.nix, server.nix (which is used by servers)

{ ... }:

{
  virtualisation.docker.enable = true;
  users.users.kevin.extraGroups = [ "docker" ];  # Allow kevin to use docker
}
