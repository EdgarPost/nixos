# ============================================================================
# NOCTALIA - Wayland Desktop Shell (bar, notifications, launcher, dock, etc.)
# ============================================================================
#
# Noctalia is the unified shell layer on top of Hyprland. It replaces the
# previous waybar + swaync stack: status bar, notifications, launcher,
# clipboard, control center, and wallpaper picker all come from Noctalia.
#
# The home-module:
#   - Installs the noctalia package
#   - Generates ~/.config/noctalia/config.toml from the `settings` attrset
#     (validates the config at build time by running `noctalia config validate`)
#   - Sets up a systemd user service that auto-starts with the Wayland session
#     (wired to wayland.systemd.target, which Hyprland's systemd.enable creates)
#
# v5 is alpha. Config schema may break on flake update. Settings can be
# tweaked at runtime via the Noctalia settings UI; the build-time `settings`
# block is just the starting defaults.
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

    # Starting defaults. Override anything here at runtime via Noctalia's GUI.
    #
    # WORKFLOW for changing settings (GUI changes are wiped on every rebuild):
    #   1. Tweak in Noctalia's GUI until you like it
    #   2. cat ~/.config/noctalia/config.toml
    #   3. Paste the values into `settings` below
    #   4. sudo nixos-rebuild switch --flake .#<host>
    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin"; # Matches the catppuccin.nix theme used elsewhere
      };

      # Wallpaper handling is done by Noctalia itself.
      # Point it at the existing catppuccin wallpaper collection.
      wallpaper = {
        enabled = true;
        default = {
          path = "$HOME/.wallpapers";
        };
      };
    };
  };
}
