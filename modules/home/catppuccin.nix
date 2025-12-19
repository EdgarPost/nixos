# ============================================================================
# CATPPUCCIN - Unified Color Theme
# ============================================================================
#
# WHAT IS CATPPUCCIN?
# A pastel color scheme with 4 flavors (Latte, Frappe, Macchiato, Mocha)
# The catppuccin/nix flake provides Home Manager modules that apply the
# theme consistently across 10+ applications from a single config.
#
# HOW IT WORKS:
#   1. Set global flavor and accent color
#   2. Enable per-program theming
#   3. catppuccin module generates proper config for each program
#
# FLAVORS (light to dark):
#   - Latte: Light theme
#   - Frappe: Light-ish dark theme
#   - Macchiato: Medium dark theme
#   - Mocha: Darkest theme (used here)
#
# ACCENT COLORS:
#   rosewater, flamingo, pink, mauve, red, maroon,
#   peach, yellow, green, teal, sky, sapphire, blue, lavender
#
# ============================================================================

{ pkgs, ... }:

{
  # ==========================================================================
  # GLOBAL CATPPUCCIN SETTINGS
  # ==========================================================================
  # These are inherited by all catppuccin.*.enable modules below
  catppuccin = {
    enable = true;      # Master switch for catppuccin module
    flavor = "mocha";   # Darkest flavor
    accent = "blue";    # Accent color for highlights, selections, etc.
  };

  # ==========================================================================
  # BAT - cat with syntax highlighting
  # ==========================================================================
  # Required: bat must be enabled for catppuccin.bat to work
  programs.bat.enable = true;

  # Shell alias: use bat instead of cat
  programs.fish.shellAliases.cat = "bat";

  # ==========================================================================
  # PER-PROGRAM THEMING
  # ==========================================================================
  # Each of these generates the appropriate config file for that program
  # All inherit flavor and accent from catppuccin.flavor and catppuccin.accent
  catppuccin.bat.enable = true;       # ~/.config/bat/config
  catppuccin.fish.enable = true;      # Fish shell colors
  catppuccin.starship.enable = true;  # Prompt colors
  catppuccin.tmux.enable = true;      # Status bar colors
  catppuccin.ghostty.enable = true;   # Terminal colors
  catppuccin.waybar.enable = true;    # Status bar CSS variables
  catppuccin.yazi.enable = true;      # File manager colors
  catppuccin.hyprland.enable = true;  # Window border colors
  catppuccin.mako.enable = true;      # Notification colors

  # ==========================================================================
  # QT THEMING (for KDE/Qt apps like KeePassXC, VLC)
  # ==========================================================================
  # Qt apps need special handling - they don't read GTK themes
  # Kvantum: A Qt theme engine that can use SVG-based themes
  qt = {
    enable = true;
    platformTheme.name = "kvantum";  # Tell Qt to use Kvantum
    style.name = "kvantum";
  };
  catppuccin.kvantum.enable = true;  # Apply catppuccin to Kvantum
}
