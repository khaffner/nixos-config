{
  description = "Kevin's NixOS configurations";

  inputs = {
    # The nixos-26.05 branch is cut at release (end of May 2026). Until then
    # this URL won't resolve — temporarily switch to nixos-unstable if you
    # need to build the config before the branch exists. The home-manager
    # release-26.05 branch is cut at the same time; same workaround applies.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, nix-flatpak, ... }: {
    nixosConfigurations = {
      # Daily-driver laptop (ThinkPad T570/T590).
      mainLaptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          {
            home-manager.sharedModules = [
              nix-flatpak.homeManagerModules.nix-flatpak
            ];
          }
          ./hosts/mainLaptop
        ];
      };

      # Headless Docker server (x86_64).
      dockerbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./hosts/dockerbox ];
      };

      # Raspberry Pi 4 Docker server (aarch64).
      pi4 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./hosts/pi4
        ];
      };
    };
  };
}
