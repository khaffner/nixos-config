{ ... }:

{
  virtualisation.docker.enable = true;
  users.users.kevin.extraGroups = [ "docker" ];
}
