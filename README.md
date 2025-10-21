# NixOS Configuration for Framework Laptop

This repository contains a complete, declarative NixOS configuration designed for a Framework laptop with the following setup:

- **Window Manager**: niri (scrollable-tiling Wayland compositor)
- **Status Bar**: waybar
- **Shell**: fish with starship prompt
- **Terminal**: alacritty with tmux auto-start
- **Editor**: Neovim with LazyVim configuration
- **User**: Edgar Post-Buijs (edgar)

## Table of Contents

1. [What is NixOS?](#what-is-nixos)
2. [Repository Structure](#repository-structure)
3. [Installation Guide](#installation-guide)
4. [Post-Installation Setup](#post-installation-setup)
5. [Configuration Overview](#configuration-overview)
6. [SSH Keys Setup](#ssh-keys-setup)
7. [Password Management](#password-management)
8. [Daily Usage](#daily-usage)
9. [Updating the System](#updating-the-system)
10. [Troubleshooting](#troubleshooting)
11. [Additional Resources](#additional-resources)

## What is NixOS?

NixOS is a Linux distribution built on the Nix package manager. Unlike traditional Linux distributions:

- **Declarative**: Your entire system is defined in configuration files
- **Reproducible**: The same configuration always produces the same system
- **Rollback-friendly**: You can always boot into previous configurations
- **Isolated**: Different projects can have different dependencies without conflicts

### Key Concepts

- **Flakes**: Modern way to manage NixOS configurations with pinned dependencies
- **Home Manager**: Tool to manage user-specific configurations (dotfiles, user packages)
- **Nix Store**: Where all packages are stored (`/nix/store`)
- **Generations**: Each system update creates a new generation; you can rollback anytime

## Repository Structure

```
.
├── flake.nix                    # Main entry point, defines inputs and outputs
├── flake.lock                   # Lock file with pinned dependency versions
├── hardware-configuration.nix   # Hardware-specific configuration (template)
├── configuration.nix            # System-wide configuration
├── home.nix                     # User configuration (Home Manager)
├── config/                      # Dotfiles and program configurations
│   ├── fish.fish               # Fish shell configuration
│   ├── starship.toml           # Starship prompt configuration
│   ├── tmux.conf               # Tmux configuration
│   ├── alacritty.toml          # Alacritty terminal configuration
│   ├── nvim/                   # Neovim/LazyVim configuration
│   ├── niri/                   # Niri compositor configuration
│   ├── waybar/                 # Waybar status bar configuration
│   └── swaylock/               # Swaylock screen locker configuration
└── README.md                    # This file
```

## Installation Guide

### Prerequisites

1. Download the NixOS installation ISO from [nixos.org/download](https://nixos.org/download)
2. Create a bootable USB drive
3. Boot from the USB drive

### Step 1: Partition the Disk

The configuration expects the following partition layout on your 2TB drive:

```
/dev/nvme0n1p1   512MB    EFI System Partition  (/boot)
/dev/nvme0n1p2   1GB      Linux Swap
/dev/nvme0n1p3   300GB    Linux Filesystem      (/)
/dev/nvme0n1p4   ~1.7TB   Linux Filesystem      (/home)
```

Use `gdisk` or `fdisk` to create these partitions:

```bash
# Example using fdisk
sudo fdisk /dev/nvme0n1

# Create GPT partition table: g
# Create partitions using 'n' command
# Set partition types using 't' command:
#   - EFI System (1)
#   - Linux swap (19)
#   - Linux filesystem (20)
# Write changes: w
```

### Step 2: Format Partitions

```bash
# Format EFI partition
sudo mkfs.fat -F 32 /dev/nvme0n1p1

# Create swap
sudo mkswap /dev/nvme0n1p2
sudo swapon /dev/nvme0n1p2

# Format root partition
sudo mkfs.ext4 /dev/nvme0n1p3

# Format home partition
sudo mkfs.ext4 /dev/nvme0n1p4
```

### Step 3: Mount Partitions

```bash
# Mount root
sudo mount /dev/nvme0n1p3 /mnt

# Create and mount boot
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot

# Create and mount home
sudo mkdir -p /mnt/home
sudo mount /dev/nvme0n1p4 /mnt/home
```

### Step 4: Generate Initial Configuration

```bash
# Generate hardware configuration
sudo nixos-generate-config --root /mnt

# This creates:
# - /mnt/etc/nixos/hardware-configuration.nix
# - /mnt/etc/nixos/configuration.nix
```

### Step 5: Clone This Repository

```bash
# Install git in the installer environment
nix-shell -p git

# Clone this repository
cd /mnt/etc/nixos
sudo mv configuration.nix configuration.nix.bak
sudo mv hardware-configuration.nix hardware-configuration.nix.bak
sudo git clone <your-repo-url> .
```

### Step 6: Update Hardware Configuration

The `hardware-configuration.nix` in this repo is a template. You need to merge the UUIDs from the generated file:

```bash
# Copy UUIDs from the generated file
sudo nano /mnt/etc/nixos/hardware-configuration.nix.bak

# Look for lines like:
# fileSystems."/" = { device = "/dev/disk/by-uuid/XXXXX"; ... };

# Update hardware-configuration.nix with these actual UUIDs
sudo nano /mnt/etc/nixos/hardware-configuration.nix
```

### Step 7: Customize Configuration

Before installing, update these files:

1. **configuration.nix**: Set your timezone
2. **home.nix**: Update git email address
3. **configuration.nix**: Set initial password or use hashed password (see Password Management section)

### Step 8: Install NixOS

```bash
# Install the system
sudo nixos-install

# This will:
# 1. Download and install all packages
# 2. Set up the bootloader
# 3. Create user accounts
# 4. Apply all configurations

# When prompted, you can set a root password (or skip if you disabled root login)

# Reboot
sudo reboot
```

## Post-Installation Setup

### First Login

1. Boot into your new system
2. You'll see the greetd login screen (tuigreet)
3. Log in as `edgar` with the initial password (default: "changeme")
4. You'll automatically enter niri (the Wayland compositor)

### Change Your Password

```bash
# Change password immediately after first login
passwd

# You'll be prompted for:
# - Current password (changeme)
# - New password
# - Confirm new password
```

### Initial Window Manager Setup

After logging in to niri, you'll see waybar at the top. Useful key bindings:

- `Super + Return`: Open terminal (alacritty)
- `Super + D`: Open application launcher (fuzzel)
- `Super + L`: Lock screen
- `Super + Q`: Close window
- `Super + 1-5`: Switch workspaces
- `Super + Shift + E`: Exit niri

### First Terminal Session

When you open a terminal, it will automatically start tmux:

```bash
# You're now in tmux with fish shell
# The session is named "main"

# Useful tmux commands (prefix is Ctrl+a):
# Ctrl+a + |  : Split vertically
# Ctrl+a + -  : Split horizontally
# Ctrl+a + r  : Reload config
# Alt + arrows: Navigate between panes
```

## Configuration Overview

### System Configuration (configuration.nix)

- **Networking**: NetworkManager enabled
- **Audio**: PipeWire (modern audio server)
- **Display Manager**: greetd with tuigreet
- **Window Manager**: niri
- **Bootloader**: systemd-boot
- **Firmware Updates**: fwupd enabled (important for Framework laptops!)

### User Configuration (home.nix)

Managed by Home Manager, includes:

- **Shell**: fish with tmux auto-start
- **Prompt**: starship
- **Editor**: Neovim with LazyVim
- **Terminal**: alacritty
- **Version Control**: git, lazygit
- **Utilities**: fzf, ripgrep, yq, jq, bat, eza, fd
- **Communication**: Slack

### Window Manager (niri)

Niri is a scrollable-tiling compositor. Key features:

- Windows automatically tile
- Scroll smoothly between workspaces
- Animations for window operations
- Configuration in `~/.config/niri/config.kdl`

See [niri documentation](https://github.com/YaLTeR/niri/wiki) for more details.

## SSH Keys Setup

### Option 1: Public Keys Only (Recommended)

Add your SSH public keys to `configuration.nix`:

```nix
users.users.edgar = {
  # ... other config ...
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxyz... your_email@example.com"
  ];
};
```

Your private keys should be:
1. Generated on your machine after installation
2. Backed up securely (encrypted external drive, password manager)
3. **Never** committed to git

### Option 2: Encrypted Private Keys with agenix

For managing secrets (like private SSH keys) in NixOS:

1. Use [agenix](https://github.com/ryantm/agenix) for encrypted secrets
2. Install agenix in your flake
3. Store encrypted secrets in the repository
4. They're only decrypted on the target machine

**Basic agenix setup:**

```nix
# In flake.nix, add to inputs:
agenix.url = "github:ryantm/agenix";

# Add to your configuration:
imports = [ agenix.nixosModules.age ];

# Create encrypted secrets:
# 1. Install agenix: nix-shell -p agenix
# 2. Create a secret: agenix -e secret.age
# 3. Reference it in configuration
```

### Generating SSH Keys

```bash
# After installation, generate a new SSH key
ssh-keygen -t ed25519 -C "edgar@framework"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key to clipboard
wl-copy < ~/.ssh/id_ed25519.pub
# Or display it
cat ~/.ssh/id_ed25519.pub
```

## Password Management

### Initial Password

The configuration sets `initialPassword = "changeme"`. This is only used when the user is first created.

**⚠️ Security Warning**: Change this immediately after first login!

### Option 1: Hashed Password (More Secure)

Generate a hashed password and use it in the configuration:

```bash
# Generate a hashed password
mkpasswd -m sha-512

# Copy the output and use it in configuration.nix:
users.users.edgar = {
  # ... other config ...
  hashedPassword = "$6$rounds=656000$..."; # paste the hash here
  # Remove initialPassword line
};
```

### Option 2: Password File

Store password hash in a file outside the configuration:

```nix
users.users.edgar = {
  # ... other config ...
  hashedPasswordFile = "/etc/nixos/secrets/edgar-password";
};
```

### Changing Password

```bash
# Change your password anytime
passwd

# Changes are persistent but not in the configuration
# This is normal - passwords are stored in /etc/shadow
```

## Daily Usage

### Making Configuration Changes

```bash
# Edit configuration
cd /etc/nixos
sudo nvim configuration.nix  # or home.nix, or any config file

# Apply changes
sudo nixos-rebuild switch

# Or test without making permanent:
sudo nixos-rebuild test

# Or build without activating:
sudo nixos-rebuild build
```

### Installing New Software

**System-wide packages** (in `configuration.nix`):
```nix
environment.systemPackages = with pkgs; [
  git
  firefox  # Add this
];
```

**User packages** (in `home.nix`):
```nix
home.packages = with pkgs; [
  lazygit
  htop  # Add this
];
```

**Temporary environment** (using nix-shell):
```bash
# Run Node.js in isolated environment
nix-shell -p nodejs

# Multiple packages
nix-shell -p nodejs yarn python3

# Exit with 'exit' - packages are gone
```

### Using direnv for Project Environments

The configuration includes direnv. Create a `.envrc` in your project:

```bash
# .envrc
use nix
```

Create a `shell.nix`:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs
    yarn
    postgresql
  ];
}
```

When you `cd` into the directory, the environment automatically loads!

## Updating the System

### Update Flake Inputs

```bash
cd /etc/nixos

# Update all inputs (nixpkgs, home-manager, etc.)
sudo nix flake update

# Update specific input
sudo nix flake lock --update-input nixpkgs

# Apply updates
sudo nixos-rebuild switch
```

### Cleaning Up Old Generations

```bash
# List all generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Delete generations older than 30 days
sudo nix-collect-garbage --delete-older-than 30d

# Delete all old generations (keep only current)
sudo nix-collect-garbage -d

# Optimize nix store (hard-link identical files)
sudo nix-store --optimise
```

### Automatic Garbage Collection

The configuration includes automatic weekly garbage collection. See `configuration.nix`:

```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
};
```

## Troubleshooting

### System Won't Boot After Update

NixOS keeps previous generations in the bootloader menu:

1. Reboot
2. In the bootloader menu, select an older generation
3. Your system boots into the previous working state
4. Fix the configuration issue
5. Run `sudo nixos-rebuild switch` again

### Configuration Build Fails

```bash
# Check for syntax errors
sudo nix-build '<nixpkgs/nixos>' -A config.system.build.toplevel -I nixos-config=/etc/nixos/configuration.nix

# More detailed error output
sudo nixos-rebuild switch --show-trace
```

### Rollback to Previous Generation

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Switch to specific generation
sudo nix-env --switch-generation 42 --profile /nix/var/nix/profiles/system

# Make it permanent
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

### Can't Find a Package

```bash
# Search for packages
nix search nixpkgs <package-name>

# Example
nix search nixpkgs firefox

# Search on the web
# https://search.nixos.org/packages
```

### Niri Issues

```bash
# Check niri logs
journalctl --user -u niri

# Restart niri (logs out)
# Super + Shift + E (exit niri)
# Then log back in
```

## Additional Resources

### Official Documentation

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix from the ground up
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/packages)

### Community Resources

- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Wiki](https://nixos.wiki/)
- [r/NixOS](https://reddit.com/r/NixOS)
- [NixOS Matrix Chat](https://matrix.to/#/#community:nixos.org)

### Tool Documentation

- [niri](https://github.com/YaLTeR/niri/wiki)
- [waybar](https://github.com/Alexays/Waybar/wiki)
- [fish shell](https://fishshell.com/docs/current/)
- [starship](https://starship.rs/)
- [tmux](https://github.com/tmux/tmux/wiki)
- [LazyVim](https://www.lazyvim.org/)
- [Framework Laptop NixOS Guide](https://github.com/NixOS/nixos-hardware#framework)

### Helpful Blog Posts & Videos

- [Zero to Nix](https://zero-to-nix.com/) - Interactive introduction
- [Xe Iaso's NixOS Guide](https://xeiaso.net/blog/series/nixos)

### Example Configurations

- [NixOS Configuration Gallery](https://nixos.wiki/wiki/Configuration_Collection)
- Search GitHub for "nixos dotfiles" to see real-world configurations

---

## Quick Reference Card

### Key Bindings

**Niri (Window Manager):**
- `Super + Return` - Terminal
- `Super + D` - App launcher
- `Super + L` - Lock screen
- `Super + Q` - Close window
- `Super + F` - Fullscreen
- `Super + 1-5` - Workspaces
- `Super + Arrows` - Navigate windows

**Tmux (Prefix: Ctrl+a):**
- `Ctrl+a |` - Split vertical
- `Ctrl+a -` - Split horizontal
- `Alt + Arrows` - Navigate panes
- `Ctrl+a r` - Reload config
- `Ctrl+a d` - Detach

**Neovim (Leader: Space):**
- `Space w` - Save
- `Space q` - Quit
- `Space ?` - Show all keymaps

### Commands

```bash
# Rebuild system
sudo nixos-rebuild switch

# Update system
cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch

# Temporary environment
nix-shell -p <package>

# Search packages
nix search nixpkgs <name>

# Garbage collection
sudo nix-collect-garbage -d

# Change password
passwd
```

---

**Questions?** Check the troubleshooting section or ask on NixOS Discourse!

**Enjoy your declarative, reproducible NixOS system! 🎉**
