# NixOS Config

Multi-host NixOS configuration without flakes. Traditional channel-based setup with Home Manager.

## Hosts

- **configuration-T570.nix**
- **configuration-T490.nix**

## Quick Start

### 1) Add channels
```bash
sudo nix-channel --add https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager
sudo nix-channel --update
```

### 2) Example T570 config
```bash
sudo ln -sf ~/code/nixos-config/configuration-T570.nix /etc/nixos/configuration.nix
sudo ln -sf ~/code/nixos-config/hosts/T570/hardware-configuration.nix /etc/nixos/hardware-configuration.nix
sudo ln -sf ~/code/nixos-config/modules /etc/nixos/modules
sudo ln -sf ~/code/nixos-config/home /etc/nixos/home
sudo nixos-rebuild switch
```

### 3) Bring up T490 later
- Use `configuration-T490.nix`
- Generate hardware config on T490 and import that file in the T490 config
- Add T490 bootloader and LUKS values in `configuration-T490.nix`
- Then symlink `/etc/nixos/configuration.nix` to `configuration-T490.nix` and rebuild

## Making Changes

Edit files, then: `sudo nixos-rebuild switch`

## Structure

- `modules/` - Shared config modules
- `home/` - Home Manager user config
- `temp/` - Current live T570 config snapshots
- See file comments for what each module provides
