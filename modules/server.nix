{ ... }:

{
  # Headless server module. common.nix has the shared bits (git, syncthing,
  # nix.gc); this adds the things only servers get. Add server-specific
  # hardening or services here as needed (fail2ban, monitoring agents,
  # hardened SSH, ...).

  imports = [ ./docker.nix ];

  # SSH server lives here (not common.nix) so the laptop doesn't expose sshd.
  services.openssh.enable = true;
}
