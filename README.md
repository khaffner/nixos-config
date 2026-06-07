# NixOS Config

Multi-host NixOS configuration without flakes. Traditional channel-based setup with Home Manager.

## Quick Start

Run the setup script and select your host:

```bash
sudo ./setup.sh
```

The script will:
1. Add the home-manager channel
2. Update channels
3. Let you select a host interactively
4. Create all necessary symlinks
5. Optionally run `nixos-rebuild switch`

### Setting Up a New Host

For a new machine:
1. Generate hardware config: `sudo nixos-generate-config --show-hardware-config > hosts/NEWHOST/hardware-configuration.nix`
2. Create `configuration-NEWHOST.nix` based on an existing config
3. Add bootloader and LUKS values as needed
4. Run `sudo ./setup.sh` and select the new host

## Making Changes

Edit files, then: `sudo nixos-rebuild switch`

## Structure

- `modules/` - Shared config modules
- `home/` - Home Manager user config
- `temp/` - Current live T570 config snapshots
- See file comments for what each module provides
