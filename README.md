# NixOS Config

Multi-host NixOS configuration without flakes. Traditional channel-based setup with Home Manager.

## Hosts

- **configuration-laptop.nix** - GNOME desktop, Steam, Docker, Home Manager
- **configuration-server.nix** - Headless x86_64 server, SSH, Docker
- **configuration-pi.nix** - Raspberry Pi 4 server, SSH, Docker

## Quick Start

See comments in each `.nix` file for detailed setup instructions.

**Laptop:**
```bash
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager
sudo nix-channel --add https://github.com/gmodena/nix-flatpak/archive/main.tar.gz nix-flatpak
sudo nix-channel --update
sudo cp /etc/nixos/hardware-configuration.nix ~/code/nixos-config/
sudo ln -sf ~/code/nixos-config/configuration-laptop.nix /etc/nixos/configuration.nix
sudo ln -sf ~/code/nixos-config/hardware-configuration.nix /etc/nixos/hardware-configuration.nix
sudo ln -sf ~/code/nixos-config/modules /etc/nixos/modules
sudo ln -sf ~/code/nixos-config/home /etc/nixos/home
sudo nixos-rebuild switch
```

**Server/Pi:** Same as laptop but skip Home Manager channel and use `configuration-server.nix` or `configuration-pi.nix`.

## Making Changes

Edit files, then: `sudo nixos-rebuild switch`

## Structure

- `modules/` - Shared config modules
- `home/` - Home Manager user config (laptop only)
- See file comments for what each module provides
