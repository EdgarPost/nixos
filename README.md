# NixOS Configuration

My personal NixOS configuration using flakes and Home Manager.

## Quick Start

```bash
# Apply configuration
sudo nixos-rebuild switch --flake .#framework-laptop

# Test without making default boot entry
sudo nixos-rebuild test --flake .#framework-laptop

# Apply standalone Home Manager config on a server
home-manager switch --flake .#edgar@server

# Update all dependencies
nix flake update

# Update single input
nix flake lock --update-input nixpkgs
```

## Structure

```
.
├── flake.nix                 # Entry point - inputs, outputs, system definitions
├── flake.lock                # Locked dependency versions (reproducibility)
├── hosts/
│   ├── common/               # Shared system configuration
│   │   ├── default.nix       # Nix settings, packages, services
│   │   └── users.nix         # User accounts and groups
│   ├── framework-laptop/     # Framework laptop
│   │   ├── default.nix       # Host-specific: bootloader, hardware features
│   │   └── hardware-configuration.nix  # Auto-generated hardware config
│   └── utm-vm/               # UTM VM (aarch64 testing)
│       ├── default.nix
│       └── hardware-configuration.nix
├── home/
│   ├── default.nix           # Home Manager entry point (desktop)
│   └── server.nix            # Standalone Home Manager for headless servers
└── modules/
    ├── nixos/                # System-level modules (require sudo)
    │   ├── 1password.nix     # Password manager + SSH agent
    │   ├── bluetooth.nix     # Bluetooth audio (SBC-XQ, mSBC codecs)
    │   ├── greetd.nix        # Login manager (tuigreet)
    │   ├── hyprland.nix      # Compositor, portals, fonts
    │   ├── podman.nix        # Rootless containers (Docker compat)
    │   ├── roon-bridge.nix   # Roon audio bridge
    │   ├── syncthing.nix     # File sync with PARA folder support
    │   └── tailscale.nix     # Mesh VPN
    └── home/                 # User-level modules (no sudo)
        ├── aliases.nix       # Fish shell aliases
        ├── atuin.nix         # Shell history sync
        ├── audio.nix         # Audio device selection (rofi menus)
        ├── catppuccin.nix    # Unified theming (Mocha)
        ├── claude-code.nix   # AI assistant config
        ├── gardener.nix      # SAP Gardener CLI tools
        ├── ghostty.nix       # Terminal emulator + cursor smear shader
        ├── github.nix        # GitHub CLI with 1Password
        ├── hyprland.nix      # Keybindings, appearance, wallpapers
        ├── kubernetes.nix    # Kubie + kubectx
        ├── mistral.nix       # Mistral API + Vibe CLI
        ├── nvim.nix          # Neovim + LSPs (Nix-managed)
        ├── openstack.nix     # OpenStack CLI with 1Password
        ├── roon-cli.nix      # Roon CLI service
        ├── swaync.nix        # Notification center
        ├── tmux.nix          # Terminal multiplexer
        ├── waybar.nix        # Status bar
        ├── workspaces.nix    # Project workspace management
        └── yazi.nix          # File manager
```

## Key Concepts

### Flakes

Flakes provide reproducible builds by pinning exact dependency versions:
- `inputs` = dependencies (like package.json)
- `flake.lock` = locked versions (like package-lock.json)
- `outputs` = what the flake produces (system configurations)

### NixOS vs Home Manager

| NixOS | Home Manager |
|-------|--------------|
| System-level config | User-level config |
| Requires `sudo` | No sudo needed |
| `/etc`, services, kernel | `~/.config`, dotfiles |
| `environment.systemPackages` | `home.packages` |

Both are managed together via `nixos-rebuild switch` (Home Manager as NixOS module).

Standalone Home Manager configs (`home/server.nix`) can also be used on non-NixOS servers.

### Module System

Modules are functions that return configuration:

```nix
{ config, pkgs, lib, ... }:  # Standard arguments
{
  # Configuration options
  programs.git.enable = true;
}
```

NixOS merges all modules: lists concatenate, attrsets merge recursively.

### Special Args

Custom data flows through `specialArgs` in flake.nix:

```nix
specialArgs = { inherit inputs user; };
```

Then available in any module:

```nix
{ inputs, user, ... }:  # Access custom args
{
  home.username = user.name;
}
```

## Hosts

| Host | Architecture | Description |
|------|--------------|-------------|
| `framework-laptop` | x86_64-linux | Framework Laptop 12" (12th gen Intel) |
| `utm-vm` | aarch64-linux | UTM VM on Apple Silicon for testing |
| `edgar@server` | x86_64-linux | Standalone Home Manager for servers |
| `edgar@server-arm` | aarch64-linux | Standalone Home Manager for ARM servers |

## Features

- **Hyprland** - Wayland compositor with ultrawide + laptop multi-monitor
- **Catppuccin Mocha** - Consistent theming across 15+ apps
- **Neovim** - LSPs and formatters managed by Nix (not Mason)
- **Ghostty** - GPU-accelerated terminal with cursor smear shader
- **Tmux** - Vim-style pane navigation, Fish shell
- **1Password** - SSH agent + CLI secret injection (GitHub, OpenStack, Gardener, Mistral)
- **Atuin** - Shell history with cloud sync
- **Waybar** - Status bar with CPU temp, battery, Bluetooth, notifications
- **Podman** - Rootless containers with Docker compatibility
- **Tailscale** - Mesh VPN with MagicDNS
- **Syncthing** - File sync with PARA folder support
- **Zoxide** - Smart directory jumping
- **Project workspaces** - Hyprland workspace management with ghq repos

## Common Tasks

```bash
# Rebuild and switch
sudo nixos-rebuild switch --flake .#framework-laptop

# Garbage collect old generations
sudo nix-collect-garbage -d

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Search packages
nix search nixpkgs firefox

# Open nix repl with flake
nix repl --expr 'builtins.getFlake (toString ./.)'
```

## Adding a New Host

1. Create `hosts/<hostname>/default.nix`:
   ```nix
   { config, pkgs, ... }:
   {
     imports = [ ../common ./hardware-configuration.nix ];
     networking.hostName = "<hostname>";
     boot.loader.systemd-boot.enable = true;
     system.stateVersion = "25.05";
   }
   ```

2. Generate hardware config:
   ```bash
   nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
   ```

3. Add to `flake.nix`:
   ```nix
   nixosConfigurations.<hostname> = mkSystem {
     hostname = "<hostname>";
     system = "x86_64-linux";
   };
   ```

## Adding Packages

**System-wide** (all users, requires rebuild):
```nix
# hosts/common/default.nix
environment.systemPackages = with pkgs; [ package-name ];
```

**User-only** (just your user):
```nix
# home/default.nix
home.packages = with pkgs; [ package-name ];
```

**With configuration**:
```nix
# Create modules/home/app.nix
programs.app = {
  enable = true;
  settings = { ... };
};
```

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [Nix Package Search](https://search.nixos.org/packages)
- [NixOS Hardware](https://github.com/NixOS/nixos-hardware)
- [Catppuccin Nix](https://github.com/catppuccin/nix)
