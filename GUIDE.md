# NixOS Configuration Guide

This file tracks progress and provides context for building this NixOS configuration.
Claude can read this file to understand current state and continue where we left off.

## Project Status

**Current Phase:** Phase 0 - Prerequisites
**Last Updated:** 2024-12-18

### Completed Steps
- [x] Initial planning and architecture design
- [ ] UTM VM setup with NixOS
- [ ] Age keypair generation
- [ ] Git repository initialized with first commit

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Nix approach | Flakes | Modern, reproducible, better multi-host |
| Username | `edgar` | User preference |
| Container runtime | Podman | Rootless, daemonless, Docker CLI compatible |
| Launcher | Rofi (wayland) | Feature-rich, mature ecosystem |
| Calendar | Calcurse + vdirsyncer | TUI-based, CalDAV/Gmail/Outlook support |
| Neovim config | Nix-managed | Fully reproducible, all plugins declarative |
| Shell history | Atuin (cloud sync) | Sync across machines, encrypted |
| Secrets | SOPS + age | Generate new keypair |

---

## Target Hosts

| Host | Hardware | Status |
|------|----------|--------|
| `utm-vm` | UTM VM on macOS (x86_64) | **Active** - for testing |
| `framework` | Framework 12" Intel 1280p | Planned |
| `asahi` | M1 Mac with Asahi Linux | Planned |
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
│       ├── nvim.nix
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

## Secrets to Encrypt (SOPS)

- [ ] Git user email
- [ ] Git signing key (SSH)
- [ ] SSH private keys
- [ ] Atuin encryption key
- [ ] CalDAV/Gmail/Outlook credentials
- [ ] Any API tokens

**Age public key:** `<not yet generated>`

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
- **Browsers:** Zen Browser, Slack, MS Teams (web)
- **VPN:** Tailscale
- **Media:** Roon client

---

## Phase Checklist

### Phase 0: Prerequisites
- [ ] Download NixOS ISO
- [ ] Create UTM VM (x86_64, 8GB RAM, 50GB disk, UEFI)
- [ ] Install minimal NixOS
- [ ] Generate hardware-configuration.nix
- [ ] Generate age keypair: `age-keygen -o ~/.config/sops/age/keys.txt`
- [ ] Create GitHub repo and push initial commit

### Phase 1: Foundation
- [ ] 1.1 Create flake.nix with minimal bootable system
- [ ] 1.2 Add home-manager as flake module
- [ ] 1.3 Create common host module

### Phase 2: SOPS Secrets
- [ ] 2.1 Set up SOPS infrastructure (.sops.yaml, initial secrets)
- [ ] 2.2 First secret: git user email

### Phase 3: Wayland Desktop
- [ ] 3.1 Hyprland + Wayland base
- [ ] 3.2 greetd + tuigreet
- [ ] 3.3 Rofi launcher

### Phase 4: Terminal Environment
- [ ] 4.1 Ghostty terminal
- [ ] 4.2 Fish + Starship
- [ ] 4.3 Atuin (cloud sync)
- [ ] 4.4 Tmux + Yazi

### Phase 5: Development Tools
- [ ] 5.1 Neovim (Nix-managed)
- [ ] 5.2 Git with encrypted identity
- [ ] 5.3 Podman + Claude Code

### Phase 6: Applications
- [ ] 6.1 1Password
- [ ] 6.2 Browsers (Zen, Slack, Teams)
- [ ] 6.3 Obsidian + Calcurse
- [ ] 6.4 Tailscale + Roon

### Phase 7: Catppuccin Theming
- [ ] 7.1 Apply Catppuccin to all apps

### Phase 8: Multi-Host
- [ ] 8.1 Framework laptop profile
- [ ] 8.2 Server profile template

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
