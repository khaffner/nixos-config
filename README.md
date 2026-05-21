# NixOS configs — multi-host

Flake-based NixOS configuration for multiple machines. One repo, shared base,
per-host overrides. Encrypted root (LUKS) on the laptops.

## Hosts

| Host | Arch | Role | Imports |
|---|---|---|---|
| `mainLaptop` | x86_64 | ThinkPad T570/T590 daily driver — GNOME, Steam, browsers | common + desktop + docker |
| `dockerbox` | x86_64 | Headless Docker server | common + server (server.nix pulls in docker) |
| `pi4` | aarch64 | Raspberry Pi 4 Docker server | common + server + `nixos-hardware` pi-4 module |

Add more by dropping a new directory into `hosts/` and registering it in
`flake.nix`. See *Adding a new host* below.

## Repository layout

```
.
├── flake.nix                       # declares nixosConfigurations.<host>
├── flake.lock                      # pinned inputs (generated on first build)
├── modules/
│   ├── common.nix                  # git, syncthing, nix.gc, user, locale
│   ├── desktop.nix                 # GNOME, audio, browsers, Steam, ThinkPad HW
│   ├── server.nix                  # headless extras (imports docker.nix)
│   └── docker.nix                  # virtualisation.docker + docker group
└── hosts/
    ├── mainLaptop/
    │   ├── default.nix             # imports + hostname + boot + stateVersion
    │   └── hardware-configuration.nix
    ├── dockerbox/
    │   ├── default.nix
    │   └── hardware-configuration.nix   # generated per-machine, not in repo yet
    └── pi4/
        └── default.nix                  # Pi 4 — no hwc, the SD image is self-contained
```

`common.nix` has things that go on **every** machine: git, syncthing,
the `kevin` user, nix garbage collection, timezone. `desktop.nix` and
`server.nix` are role modules. Hosts pick the modules they need. SSH lives
in `server.nix` only — the laptop doesn't run sshd.

User group memberships compose: `common.nix` puts kevin in `wheel`,
`desktop.nix` adds `networkmanager`, `docker.nix` adds `docker`. NixOS merges
list-typed options across modules.

## What each machine gets

**Every host (`common.nix`):**
- User `kevin` with sudo (in `wheel`)
- Git, OpenSSH client (`ssh`, `scp`, `sftp`)
- Syncthing as `kevin`, web UI on `http://127.0.0.1:8384`
- Flakes + `nix` CLI enabled
- Automatic Nix store GC (weekly, drops generations older than 30 days)
- Timezone Europe/Oslo, locale en_US.UTF-8

**Laptops (`desktop.nix`):**
- GNOME on Wayland (via GDM), NetworkManager, Norwegian keymap
- PipeWire audio, printing, Bluetooth
- Steam (with 32-bit graphics, GameMode), Microsoft Edge, Google Chrome, Firefox,
  VS Code, PowerShell, Signal
- Flatpak with Flathub pre-added
- Intel microcode, thermald, fwupd (BIOS updates), fingerprint reader

**Servers (`server.nix`):**
- OpenSSH (sshd). Servers only — laptops do not run sshd.
- Docker (via `docker.nix`). Servers in this repo get Docker by default — if
  you ever want a server without it, pull docker out of `server.nix` and into
  the individual host instead.

## Prerequisites

- **NixOS 26.05 GNOME graphical ISO** from <https://nixos.org/download>
  (the version matters — `system.stateVersion` in each host is `26.05`)
- USB stick (≥ 4 GB)
- Internet on the target machine (Ethernet or WiFi)

Flash the ISO with `dd` or balenaEtcher.

In BIOS:
- **Boot → UEFI/Legacy → UEFI Only**.
- Disable Secure Boot for the install (NixOS doesn't sign its bootloader by
  default; can be enabled later via `lanzaboote` if you want).

## Install (laptop)

### 1. Boot the installer

Boot from the USB. After a few seconds the GNOME live environment loads and
**Calamares** (the graphical installer) launches automatically. If it doesn't,
there's an "Install NixOS" icon on the desktop.

### 2. Click through Calamares

Most steps are obvious. The ones that matter:

| Step | What to pick |
|---|---|
| Language / region / timezone | Whatever you want — `common.nix` sets `Europe/Oslo` later anyway. |
| Keyboard | Norwegian (or whatever you actually use) |
| **Partitions** | **"Erase disk"** and **tick "Encrypt system"**. Enter a LUKS passphrase — keep this somewhere safe; it's the only way into the disk. |
| **Users** | Username **`kevin`** (lowercase, exact match). Set a login password. |
| Desktop | GNOME (should be the default on this ISO) |
| Summary | Review, then **Install**. |

Calamares does the partitioning, formats with LUKS, installs a base GNOME
system, and writes `/etc/nixos/configuration.nix` +
`/etc/nixos/hardware-configuration.nix`.

When it finishes, reboot and pull the USB.

### 3. First boot

You'll be prompted for the LUKS passphrase — type it. Then log in as `kevin`
via GDM.

### 4. Apply the flake

Clone this repo (git was installed by Calamares):

```bash
git clone <repo-url> ~/code/nix
cd ~/code/nix
```

Copy the hardware config Calamares generated into the host directory:

```bash
sudo cp /etc/nixos/hardware-configuration.nix hosts/mainLaptop/
sudo chown kevin:users hosts/mainLaptop/hardware-configuration.nix
```

Check `system.stateVersion`. If Calamares wrote something other than `"26.05"`
in `/etc/nixos/configuration.nix`, edit `hosts/mainLaptop/default.nix` to match
(then leave it alone forever — see *stateVersion* below).

Build and switch to the flake:

```bash
sudo nixos-rebuild switch --flake ~/code/nix#mainLaptop
```

`nixos-rebuild` can also auto-pick the host from `hostname`:

```bash
sudo nixos-rebuild switch --flake ~/code/nix
```

That rebuild pulls in Steam, Edge, Chrome, Firefox, VS Code, PowerShell, syncthing,
gamemode, fwupd, thermald, and the Flatpak setup. First run takes a while.

When it's done, log out and back in (or reboot) so GNOME picks up the new
session configuration.

### 5. Firmware updates (ThinkPad)

Lenovo publishes BIOS/firmware via LVFS:

```bash
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update
```

## Adding a new host

1. **Install NixOS** on the new machine the usual way (Calamares for desktops,
   manual install for headless boxes — see *Manual install* below).
2. **Make a host directory:**
   ```bash
   mkdir -p hosts/<name>
   ```
3. **Copy its hardware config in:**
   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix hosts/<name>/
   ```
4. **Write `hosts/<name>/default.nix`** — copy `hosts/dockerbox/default.nix` as
   a template, swap the hostname, and import the modules you want.
5. **Register it in `flake.nix`:**
   ```nix
   <name> = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     modules = [ ./hosts/<name> ];
   };
   ```
6. **Build:** `sudo nixos-rebuild switch --flake ~/code/nix#<name>`

## Daily use

| Task | Command |
|---|---|
| Apply config changes | `sudo nixos-rebuild switch --flake ~/code/nix` |
| Try changes without persisting | `sudo nixos-rebuild test --flake ~/code/nix` |
| Build for a different host | `sudo nixos-rebuild switch --flake ~/code/nix#<host>` |
| Update inputs (nixpkgs, etc.) | `nix flake update` (then rebuild) |
| Roll back to previous generation | `sudo nixos-rebuild switch --rollback` |
| List generations | `sudo nix-env --list-generations -p /nix/var/nix/profiles/system` |
| Garbage-collect now | `sudo nix-collect-garbage -d` |
| BIOS / firmware update | `fwupdmgr refresh && fwupdmgr update` |

## Updating

### `stateVersion` is not the version you're running

`system.stateVersion = "26.05";` is a marker pinning the *semantics of stateful
defaults* (PostgreSQL default version, file layouts, etc.) to what was current
when you first installed. **You set it once per host and leave it alone forever**,
even when upgrading to 26.11, 27.05, etc.

What controls the version you run is the `nixpkgs` flake input.

### Minor updates (within 26.05)

```bash
nix flake update             # pull latest commits from nixos-26.05
sudo nixos-rebuild switch --flake ~/code/nix
```

Each rebuild creates a new boot-menu entry you can roll back to.

### Major upgrade (e.g. 26.05 → 26.11)

Edit `flake.nix`:

```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.11";
```

Then:

```bash
nix flake update
sudo nixos-rebuild switch --flake ~/code/nix
```

**Do not touch `stateVersion`.** It stays at 26.05 forever.

Before a major upgrade:
- Read the release notes for the new version.
- Make sure `/home` is actually backed up somewhere. Syncthing replicates, it
  doesn't back up.
- Commit `flake.lock` so you can revert by checking out the old commit.

### If an update breaks something

NixOS rollback is the best feature it has.

1. **Boot menu** — every generation shows as a boot entry. Pick the previous one.
2. **CLI rollback:** `sudo nixos-rebuild switch --rollback`
3. **List generations:**
   `sudo nix-env --list-generations -p /nix/var/nix/profiles/system`
4. **Revert the flake:** `git revert <commit>` (or check out the old `flake.lock`)
   and rebuild.

Generations stick around until garbage-collected (this config drops anything
older than 30 days, weekly).

## Install (Raspberry Pi 4)

The Pi doesn't use Calamares. Build an SD image from the flake, flash it,
boot the Pi.

### What's special about the Pi

- **aarch64** — `system = "aarch64-linux"` in `flake.nix`.
- **No UEFI / grub** — boots via the Pi firmware → U-Boot → `extlinux`.
- **`nixos-hardware`** — the `raspberry-pi-4` module from the
  [`nixos-hardware`](https://github.com/NixOS/nixos-hardware) flake handles
  kernel, firmware, and GPU memory split. Added to the flake inputs.
- **No `hardware-configuration.nix`** — the SD image builder bakes everything
  in. If you ever install via the aarch64 ISO instead, you'd generate one with
  `nixos-generate-config` and drop it into `hosts/pi4/`.

### Build the SD image

You need an aarch64 builder. Three options:

1. **On the Pi itself** (slowest, but works) — install NixOS aarch64 from the
   official ISO, then `sudo nixos-rebuild switch --flake .#pi4` on the device.
2. **Cross-build / binfmt emulation from an x86 machine.** On `mainLaptop`, add:
   ```nix
   boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
   ```
   to `hosts/mainLaptop/default.nix`, rebuild, then:
   ```bash
   nix build .#nixosConfigurations.pi4.config.system.build.sdImage
   ```
3. **Borrow another aarch64 machine / remote builder** — same `nix build`
   command on any aarch64 host.

The resulting image lands in `result/sd-image/`.

### Flash and boot

```bash
sudo dd if=result/sd-image/*.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

Eject, put the SD card in the Pi, power on. First boot resizes the rootfs and
brings up SSH. Find the Pi's IP (router, `arp -a`, or `avahi-browse`), log in
as `kevin` over SSH (password is `nixos` on the default image — change it
immediately).

### Apply config changes

```bash
ssh kevin@<pi-ip>
sudo nixos-rebuild switch --flake github:youruser/yourrepo#pi4
```

…or clone the repo locally on the Pi and rebuild from there. Compiling on
the Pi is slow; do major upgrades via cross-build from `mainLaptop` with
`--target-host kevin@<pi-ip>` if you want to keep the Pi snappy.

## Manual install (e.g. headless dockerbox)

When Calamares can't help (no GUI, complex partitioning, custom encryption):

```bash
# Boot the minimal ISO, then:
parted /dev/sdX ...                                 # partition
cryptsetup luksFormat /dev/sdX2                     # encrypt root (optional)
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mkfs.fat -F32 /dev/sdX1 && mkdir -p /mnt/boot && mount /dev/sdX1 /mnt/boot

nixos-generate-config --root /mnt                   # writes hardware-configuration.nix

# Clone the repo, copy hwc in, register the host in flake.nix.
nixos-install --flake /mnt/etc/nixos#<hostname>
```

## Notes and gotchas

- **`hardware-configuration.nix` is per-machine.** Don't commit one host's hwc
  to another's directory. Regenerate with `nixos-generate-config` on the actual
  hardware.
- **List options compose across modules.** `users.users.kevin.extraGroups`
  appears in three modules (`common.nix`, `desktop.nix`, `docker.nix`) and
  NixOS concatenates them. Same goes for `environment.systemPackages`.
- **Flathub setup needs network.** Adding the Flathub remote runs on every
  `nixos-rebuild switch`. If a switch happens offline it'll skip silently
  (`|| true` in the activation script).
- **Steam controllers.** Bluetooth and most USB controllers work out of the
  box. Steam Input handles the rest.
- **GNOME on Wayland.** `services.xserver.enable = true;` is still required —
  it sets up the session infrastructure even though sessions run on Wayland.
- **Username must be `kevin`.** `common.nix` declares `users.users.kevin`. If
  Calamares created a different username, the rebuild will create a *second*
  user named kevin alongside it. Easiest fix: redo Calamares and name the user
  kevin.
