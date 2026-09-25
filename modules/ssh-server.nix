# SSH server module
#
# Enables remote admin access for hosts that need it, while keeping the rest of
# the system configuration shared and reusable across machines.

{ ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };
}
