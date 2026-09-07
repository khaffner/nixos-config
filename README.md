# NixOS Config

Multi-host NixOS configuration without flakes. Traditional channel-based setup with Home Manager.

### Setting Up a New Host

For a new machine:
1. Generate hardware config: `sudo nixos-generate-config --show-hardware-config > hosts/NEWHOST/hardware-configuration.nix`
2. Create `configuration-NEWHOST.nix` based on an existing config
3. Add bootloader and LUKS values as needed
4. Use the Onboarding steps below to install and activate the desired host configuration


## Onboarding

These steps clone this repo into `/etc/nixos` and apply the `configuration-STEAM.nix` configuration. They can be used for any host.

```bash
# optional: backup any existing config
sudo mv /etc/nixos /etc/nixos.bak || true

# as root, clone using a temporary nix-shell with git
sudo -i
nix-shell -p git --run 'git clone https://github.com/khaffner/nixos-config /etc/nixos'

# make the user able to edit files without sudo
chown -R kevin:kevin /etc/nixos

# apply the configuration (runs as root)
nixos-rebuild switch -I nixos-config=/etc/nixos/configuration-STEAM.nix
```

Notes:
- Cloning into `/etc/nixos` will replace any existing system configuration; keep the backup if unsure.
- `nixos-rebuild` must be run as root.

## Making Changes

Edit files, then: `sudo nixos-rebuild switch`

## Structure

- `modules/` - Shared config modules
- `home/` - Home Manager user config
- See file comments for what each module provides