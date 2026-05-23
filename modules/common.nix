# Common Module - Loaded by ALL machines
#
# Provides:
#   - User account (kevin)
#   - Timezone and locale
#   - Syncthing file sync
#   - Base packages (git, btop, openssh, powershell)
#   - Nix garbage collection

{ pkgs, ... }:

{
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;  # Allow proprietary software

  # Nix store optimization and cleanup
  nix.settings.auto-optimise-store = true;  # Deduplicate files
  nix.gc = {
    automatic = true;
    dates = "weekly";                      # Run garbage collection weekly
    options = "--delete-older-than 30d";   # Keep last 30 days
  };

  # User account - other modules add to extraGroups
  users.users.kevin = {
    isNormalUser = true;
    description = "Kevin";
    extraGroups = [ "wheel" ];  # wheel = sudo access
    shell = pkgs.bash;
  };

  # Syncthing - File sync across machines
  # Web UI: http://127.0.0.1:8384
  services.syncthing = {
    enable = true;
    user = "kevin";
    dataDir = "/home/kevin";
    configDir = "/home/kevin/.config/syncthing";
    openDefaultPorts = true;  # 22000 TCP/UDP, 21027 UDP
  };

  environment.systemPackages = with pkgs; [
    git
    btop
    openssh
    powershell
  ];
}
