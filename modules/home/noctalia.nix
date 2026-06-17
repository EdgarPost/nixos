# ============================================================================
# NOCTALIA - Wayland Desktop Shell (bar, notifications, launcher, dock, etc.)
# ============================================================================
#
# Noctalia is the unified shell layer on top of Hyprland. It replaces the
# previous waybar + swaync stack: status bar, notifications, launcher,
# clipboard, control center, and wallpaper picker all come from Noctalia.
#
# Settings live in `noctalia-settings.toml` next to this file. The TOML is
# noctalia's native format, so the home-module just points at it and the
# `noctalia config validate` step (run at build time) catches any issues.
#
# v5 is alpha. Config schema may break on flake update.
#
# WORKFLOW for changing settings:
#   1. Tweak in Noctalia's GUI until you like it
#   2. cp ~/.local/state/noctalia/settings.toml modules/home/noctalia-settings.toml
#   3. sudo nixos-rebuild switch --flake .#<host>
#   4. git add modules/home/noctalia-settings.toml && git commit
#
# Docs: https://docs.noctalia.dev/v5/
#
# ============================================================================

{ ... }:

{
  programs.noctalia = {
    enable = true;

    # Systemd service auto-starts on hyprland-session.target
    systemd.enable = true;

    # Path to a tracked TOML file. The home-module validates it at build
    # time and copies it to ~/.config/noctalia/config.toml on activation.
    settings = ./noctalia-settings.toml;
  };
}
