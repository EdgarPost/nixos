# NixOS Configuration

My personal NixOS configuration using flakes and Home Manager.

## Quick Start

```bash
# Apply configuration
sudo nixos-rebuild switch --flake .#framework

# Test without making default boot entry
sudo nixos-rebuild test --flake .#framework

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
│   ├── framework/            # Framework laptop
│   │   ├── default.nix       # Host-specific: bootloader, hardware features
│   │   └── hardware-configuration.nix  # Auto-generated hardware config
│   └── utm-vm/               # UTM VM (aarch64 testing)
├── home/
│   └── default.nix           # Home Manager entry point
└── modules/
    ├── nixos/                # System-level modules (require sudo)
    │   ├── hyprland.nix      # Compositor, portals, fonts
    │   ├── greetd.nix        # Login manager
    │   └── 1password.nix     # Password manager + SSH agent
    └── home/                 # User-level modules (no sudo)
        ├── hyprland.nix      # Keybindings, appearance, Rofi, Mako
        ├── ghostty.nix       # Terminal emulator
        ├── tmux.nix          # Terminal multiplexer
        ├── nvim.nix          # Neovim + LSPs (Nix-managed)
        ├── catppuccin.nix    # Unified theming
        ├── waybar.nix        # Status bar
        ├── atuin.nix         # Shell history sync
        ├── yazi.nix          # File manager
        └── claude-code.nix   # AI assistant config
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
| `framework` | x86_64-linux | Framework Laptop 12" (12th gen Intel) |
| `utm-vm` | aarch64-linux | UTM VM on Apple Silicon for testing |

## Features

- **Hyprland** - Wayland compositor with animations
- **Catppuccin Mocha** - Consistent theming across 10+ apps
- **Neovim** - LSPs and formatters managed by Nix (not Mason)
- **Ghostty** - GPU-accelerated terminal with cursor smear shader
- **Tmux** - Vim-tmux-navigator integration (Ctrl+hjkl)
- **1Password** - SSH agent integration (no key files)
- **Atuin** - Shell history with cloud sync

## Common Tasks

```bash
# Rebuild and switch
sudo nixos-rebuild switch --flake .#framework

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
