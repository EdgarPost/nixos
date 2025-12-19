# NixOS Configuration Guide

This file tracks progress and provides context for building this NixOS configuration.
Claude can read this file to understand current state and continue where we left off.

## Project Status

**Current Phase:** Phase 6 - Applications
**Last Updated:** 2025-12-19

### Completed Steps
- [x] Initial planning and architecture design
- [x] UTM VM setup with NixOS (aarch64-linux)
- [x] Git repository initialized with first commit
- [x] Phase 1: Flake structure with home-manager
- [x] Phase 2: Skipped SOPS - using 1Password instead
- [x] Phase 3: Hyprland + greetd + rofi
- [x] 1Password + SSH Agent working
- [x] Framework laptop configured and working
- [x] Git push from Framework working
- [x] Zen browser added
- [x] Claude Code added
- [x] Waybar configured
- [x] Yazi file manager added
- [x] Neovim with LazyVim configured
- [x] Ghostty cursor smear shader
- [x] Tmux vim-navigator integration
- [x] Hyprland animations + window move/resize keybindings
- [x] Catppuccin theming (Hyprland, Rofi, Mako, Qt/Kvantum)
- [x] Framework: lid switch, 120Hz display, per-device input
- [x] Waybar notification module (mako integration)
- [x] Slack added (x86_64 only)
- [x] Multi-arch package handling (Zen on both, Slack x86_64 only)

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Nix approach | Flakes | Modern, reproducible, better multi-host |
| Username | `edgar` | User preference |
| Container runtime | Podman | Rootless, daemonless, Docker CLI compatible |
| Launcher | Rofi (wayland) | Feature-rich, mature ecosystem |
| Calendar | Calcurse + vdirsyncer | TUI-based, CalDAV/Gmail/Outlook support |
| Neovim config | LazyVim (standalone) | Lua in repo, Mason disabled (LSPs via Nix) |
| Shell history | Atuin (cloud sync) | Sync across machines, encrypted |
| Secrets | 1Password | SSH agent, browser integration, already using it |
| Browser | Zen | Firefox-based, privacy-focused |

---

## Target Hosts

| Host | Hardware | Status |
|------|----------|--------|
| `utm-vm` | UTM VM on macOS (aarch64) | Ready - for testing |
| `framework` | Framework 12" Intel 1280p | **Active** - daily driver |
| `asahi` | M1 Mac with Asahi Linux | Planned (aarch64 support ready) |
| `server` | Headless dev servers | Planned |

---

## Repository Structure

```
nixos-config/
├── flake.nix                    # Main entry point
├── flake.lock                   # Locked dependencies
├── .sops.yaml                   # SOPS configuration
├── secrets/
│   └── secrets.yaml             # Encrypted secrets
├── hosts/
│   ├── common/
│   │   ├── default.nix          # Shared config
│   │   └── users.nix            # User definitions
│   ├── utm-vm/
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   ├── framework/
│   └── asahi/
├── modules/
│   ├── nixos/                   # System modules
│   │   ├── hyprland.nix
│   │   ├── greetd.nix
│   │   ├── podman.nix
│   │   └── tailscale.nix
│   └── home/                    # Home-manager modules
│       ├── fish.nix
│       ├── nvim/
│       │   ├── default.nix      # nixCats config
│       │   └── lua/             # Lua config (in repo)
│       ├── tmux.nix
│       ├── ghostty.nix
│       ├── git.nix
│       ├── starship.nix
│       ├── atuin.nix
│       └── yazi.nix
└── home/
    └── default.nix              # Home-manager entry
```

---

## Secrets Management (1Password)

Using 1Password instead of SOPS for secrets:
- [x] SSH keys (via 1Password SSH Agent)
- [ ] Atuin encryption key (store in 1Password, reference in config)
- [ ] API tokens (store in 1Password)

**SSH Agent:** `~/.1password/agent.sock`

---

## Software Stack

### Desktop Environment
- **Window Manager:** Hyprland (Wayland)
- **Login Manager:** greetd + tuigreet
- **Launcher:** Rofi (wayland fork)
- **Theme:** Catppuccin (all apps)

### Terminal
- **Emulator:** Ghostty
- **Shell:** Fish
- **Prompt:** Starship
- **History:** Atuin (cloud sync)
- **Multiplexer:** Tmux
- **File Manager:** Yazi

### Development
- **Editor:** Neovim (Nix-managed, LazyVim-style)
- **Git:** With SOPS-encrypted identity
- **Containers:** Podman (rootless)
- **AI:** Claude Code

### Applications
- **Password Manager:** 1Password
- **Notes:** Obsidian
- **Calendar:** Calcurse + vdirsyncer
- **Browsers:** Zen Browser (x86_64 + aarch64)
- **Communication:** Slack (x86_64 only), MS Teams (web)
- **VPN:** Tailscale
- **Media:** Roon client

---

## Phase Checklist

### Phase 0: Prerequisites
- [x] Download NixOS ISO
- [x] Create UTM VM (aarch64, 8GB RAM, 50GB disk, UEFI)
- [x] Install minimal NixOS
- [x] Generate hardware-configuration.nix
- [x] Generate age keypair: `age-keygen -o ~/.config/sops/age/keys.txt`
- [x] Create GitHub repo and push initial commit

### Phase 1: Foundation
- [x] 1.1 Create flake.nix with minimal bootable system
- [x] 1.2 Add home-manager as flake module
- [x] 1.3 Create common host module

### Phase 2: Secrets (1Password)
- [x] 2.1 ~~SOPS~~ → Using 1Password instead
- [x] 2.2 1Password GUI + SSH Agent configured

### Phase 3: Wayland Desktop
- [x] 3.1 Hyprland + Wayland base
- [x] 3.2 greetd + tuigreet
- [x] 3.3 Rofi launcher
- [x] 3.4 Waybar

### Phase 4: Terminal Environment
- [x] 4.1 Ghostty terminal (with tmux auto-attach + cursor smear shader)
- [x] 4.2 Fish + Starship
- [x] 4.3 Atuin (cloud sync)
- [x] 4.4 Tmux (vim-navigator integration)
- [x] 4.5 Yazi

### Phase 5: Development Tools
- [x] 5.1 Neovim (LazyVim, LSPs via Nix)
- [x] 5.2 Git configured
- [ ] 5.3 Podman
- [x] 5.4 Claude Code

### Phase 6: Applications
- [x] 6.1 1Password
- [x] 6.2 Zen Browser
- [ ] 6.3 Obsidian + Calcurse
- [ ] 6.4 Tailscale + Roon

### Phase 7: Catppuccin Theming
- [x] 7.1 Catppuccin flake added
- [x] 7.2 Themed: Ghostty, Tmux, Fish, Starship, Bat, Yazi, Waybar, Neovim
- [x] 7.3 Theme: Hyprland, Rofi, Mako, Qt/Kvantum (GTK archived upstream)

### Phase 8: Multi-Host
- [x] 8.1 Framework laptop profile (lid switch, 120Hz, touchpad sensitivity)
- [x] 8.2 Multi-arch support (x86_64 + aarch64-linux)
- [ ] 8.3 Server profile template

---

## Quick Reference

### Bootstrapping Fresh NixOS

```bash
# Get git temporarily on minimal install
nix-shell -p git

# Clone repo
git clone https://github.com/<username>/nixos-config.git
cd nixos-config

# Copy hardware config (generated during install)
cp /etc/nixos/hardware-configuration.nix hosts/utm-vm/

# Build and switch
sudo nixos-rebuild switch --flake .#utm-vm
```

### SOPS Commands

```bash
# Edit secrets (will encrypt on save)
sops secrets/secrets.yaml

# Re-encrypt after adding new key
sops updatekeys secrets/secrets.yaml
```

### Common Nix Commands

```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#<hostname>

# Rebuild home-manager only
home-manager switch --flake .#edgar@<hostname>

# Update flake inputs
nix flake update

# Show flake outputs
nix flake show
```

---

## Notes for Claude

When continuing this project:
1. Read this GUIDE.md first to understand current state
2. Check the Phase Checklist for next steps
3. Each completed step should be committed to git
4. Update this file after completing steps
5. All secrets go in `secrets/secrets.yaml` encrypted with SOPS
6. User wants to learn - explain each step

**User preferences:**
- Explain each step thoroughly
- One git commit per logical step
- Challenge decisions when appropriate
- Follow TDD/SOLID/KISS principles

---

## Research & References (December 2025)

### Flake Inputs (Recommended)

```nix
{
  inputs = {
    # Core
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Hardware profiles
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Zen Browser (NixOS wiki recommended)
    zen-browser.url = "github:youwen5/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    # Theming (future)
    catppuccin.url = "github:catppuccin/nix";
  };
}
```

### Key Documentation Links

| Resource | URL |
|----------|-----|
| NixOS & Flakes Book | https://nixos-and-flakes.thiscute.world/ |
| Nix Starter Configs | https://github.com/Misterio77/nix-starter-configs |
| Home Manager Manual | https://nix-community.github.io/home-manager/ |
| SOPS-nix | https://github.com/Mic92/sops-nix |
| Catppuccin Nix | https://nix.catppuccin.com/ |
| Hyprland Wiki | https://wiki.hypr.land/ |
| Framework NixOS | https://wiki.nixos.org/wiki/Hardware/Framework/Laptop_13 |
| NixOS Wiki | https://wiki.nixos.org/ |
| nixCats-nvim | https://nixcats.org/ |

### Best Practices Discovered

**SOPS with Age:**
- Use age over GPG (ed25519 > RSA)
- Generate with: `age-keygen -o ~/.config/sops/age/keys.txt`
- Can convert SSH host keys: `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`
- Keep backup age key in password manager

**Hyprland on NixOS:**
```nix
# System config
{ programs.hyprland.enable = true; }

# Home Manager (when using NixOS module)
{ wayland.windowManager.hyprland = {
    enable = true;
    package = null;  # Use NixOS module's package
    portalPackage = null;
  };
}
```

**greetd + tuigreet:**
```nix
{ pkgs, ... }: {
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };
}
```

**Atuin with SOPS:**
```nix
{ config, ... }: {
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh";
      key_path = config.sops.secrets.atuin_key.path;
    };
  };
}
```

**Ghostty:**
- Available in nixpkgs-unstable as `pkgs.ghostty`
- Or use official flake: `github:ghostty-org/ghostty`

**Zen Browser:**
- Use `github:youwen5/zen-browser-flake` (NixOS wiki recommended)
- Supports both x86_64-linux and aarch64-linux
- Add to home.packages: `inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default`
- For 1Password: add "zen" to `/etc/1password/custom_allowed_browsers`

**Multi-Architecture Packages:**
```nix
# Conditional packages (use lib.optionals, NOT lib.mkIf in lists)
home.packages = with pkgs; [
  # Universal packages
  somePackage
] ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [
  # x86_64-only packages (no aarch64 builds)
  slack
];
```

**Neovim (nixCats + LazyVim):**
- nixCats-nvim with LazyVim template recommended over nixvim
- Nix handles plugin installation (reproducible)
- Lua config files live in repo (familiar, portable)
- Clone anywhere → rebuild → exact same editor

**Framework 12th Gen:**
- Use nixos-hardware module: `nixos-hardware.nixosModules.framework-12th-gen-intel`
- Everything works out of box including fingerprint
- No custom kernel needed on current NixOS

**Catppuccin:**
- Use `github:catppuccin/nix` flake
- Provides modules for: Hyprland, Fish, Starship, Tmux, Nvim, GTK, etc.
- Cachix: `catppuccin.cachix.org`

### Sources

- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [Nix Starter Configs](https://github.com/Misterio77/nix-starter-configs)
- [SOPS-nix GitHub](https://github.com/Mic92/sops-nix)
- [Hyprland Wiki - NixOS](https://wiki.hypr.land/Nix/)
- [Catppuccin Nix](https://nix.catppuccin.com/)
- [Framework Laptop 13 NixOS Wiki](https://wiki.nixos.org/wiki/Hardware/Framework/Laptop_13)
- [Atuin NixOS Wiki](https://wiki.nixos.org/wiki/Atuin)
- [Zen Browser Flake](https://github.com/0xc000022070/zen-browser-flake)
- [nixCats-nvim](https://nixcats.org/)
