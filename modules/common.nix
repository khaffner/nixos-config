{ pkgs, ... }:

{
  # Things every machine gets: user account, shared services, nix settings.

  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  # Flakes + nix CLI on every host so `nixos-rebuild switch --flake` works.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  users.users.kevin = {
    isNormalUser = true;
    description = "Kevin";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
  };

  # Syncthing — runs as kevin, web UI at http://127.0.0.1:8384.
  services.syncthing = {
    enable = true;
    user = "kevin";
    dataDir = "/home/kevin";
    configDir = "/home/kevin/.config/syncthing";
    openDefaultPorts = true;
  };

  environment.systemPackages = with pkgs; [
    git
    btop
    openssh
    powershell
  ];
}
