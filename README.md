# NixOS Configuration

My personal NixOS configuration using flakes and Home Manager.

The `.nix` files are the source of truth — this README only covers the general
layout and the common workflows.

## Quick Start

```bash
# Apply configuration
sudo nixos-rebuild switch --flake .#<hostname>

# Test without making default boot entry
sudo nixos-rebuild test --flake .#<hostname>

# Apply standalone Home Manager config on a non-NixOS server
home-manager switch --flake .#edgar@server

# Update all dependencies
nix flake update

# Update single input
nix flake lock --update-input nixpkgs

# Show what this flake produces
nix flake show
```

## How It's Set Up

### Flakes

Flakes provide reproducible builds by pinning exact dependency versions:

- `inputs` = dependencies (declared in `flake.nix`, like package.json)
- `flake.lock` = locked versions (like package-lock.json)
- `outputs` = what the flake produces (system configurations)

### NixOS + Home Manager

|NixOS|Home Manager|
|-|-|
|System-level config|User-level config|
|Requires `sudo`|No sudo needed|
|`/etc`, services, kernel|`~/.config`, dotfiles|
|`environment.systemPackages`|`home.packages`|

Both are managed together via `nixos-rebuild switch` (Home Manager is imported
as a NixOS module). Standalone Home Manager configs (`home/server.nix`) can also
be used on non-NixOS servers.

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

Custom data flows through `specialArgs` in `flake.nix`:

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

### Secrets

Secrets are handled via **1Password** (not SOPS): the 1Password CLI acts as the
SSH agent (`~/.1password/agent.sock`) and provides secret injection for various
CLIs. No secrets are stored in this repo.

## Structure

```text
.
├── flake.nix                 # Entry point: inputs, user config, system definitions
├── flake.lock                # Locked dependency versions (reproducibility)
├── hosts/                    # System-level config, per host
│   ├── common/               # Shared config (all hosts): users, services, hardening
│   └── <hostname>/           # One dir per machine
│       ├── default.nix       # Host-specific: bootloader, import of modules
│       ├── hardware-configuration.nix  # Machine-generated
│       └── home.nix          # Host-specific home-manager bits (monitors, devices)
├── home/                     # Home Manager entry points
│   ├── default.nix           # Desktop (composes the profiles below)
│   └── server.nix            # Standalone Home Manager for headless servers
├── profiles/                 # Composable home-manager profiles
│   ├── base.nix              # Shell, theming, common tools
│   ├── desktop.nix           # GUI / Wayland stack
│   └── dev.nix               # Development tooling
└── modules/
    ├── nixos/                # System-level modules (require sudo) — one per feature
    └── home/                 # User-level modules (no sudo) — one per program
```

## Common Tasks

```bash
# Rebuild and switch
sudo nixos-rebuild switch --flake .#<hostname>

# Garbage collect old generations
sudo nix-collect-garbage -d

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Search packages
nix search nixpkgs firefox

# Open nix repl with this flake
nix repl --expr 'builtins.getFlake (toString ./.)'
```

## Bootstrapping a Fresh Machine

```bash
# Get git temporarily on a minimal install
nix-shell -p git

# Clone repo
git clone <repo-url> nixos && cd nixos

# Copy the machine-generated hardware config into the new host dir
cp /etc/nixos/hardware-configuration.nix hosts/<hostname>/

# Build and switch
sudo nixos-rebuild switch --flake .#<hostname>
```

## Adding a New Host

1. Create `hosts/<hostname>/default.nix`:

   ```nix
   { config, pkgs, ... }:
   {
     imports = [ ../common ./hardware-configuration.nix ];
     networking.hostName = "<hostname>";
     boot.loader.systemd-boot.enable = true;
     system.stateVersion = "25.05";  # set once, don't bump afterwards
   }
   ```

2. Generate the hardware config:

   ```bash
   nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
   ```

3. Add the configuration to `flake.nix`:

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

**With configuration** (create `modules/home/<app>.nix`):

```nix
programs.app = {
  enable = true;
  settings = { ... };
};
```

**Architecture-gated packages** (use `lib.optionals`, not `lib.mkIf`, inside lists):

```nix
home.packages =
  with pkgs;
  [ universal-package ]
  ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [
    x86-only-package
  ];
```

## Resources

- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [Nix Starter Configs](https://github.com/Misterio77/nix-starter-configs)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [Nix Package Search](https://search.nixos.org/packages)
- [NixOS Hardware](https://github.com/NixOS/nixos-hardware)
