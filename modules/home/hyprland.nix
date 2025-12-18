{ config, pkgs, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;  # Use NixOS module's package
    portalPackage = null;

    settings = {
      # Monitor config (auto-detect)
      monitor = ",preferred,auto,1";

      # Mod key (SUPER = Windows key)
      "$mod" = "SUPER";

      # Default apps
      "$terminal" = "foot";  # We'll switch to ghostty later
      "$menu" = "rofi -show drun";

      # Startup
      exec-once = [
        "1password --silent"  # Start 1Password in background
      ];

      # Basic keybindings
      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, D, exec, $menu"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"

        # Move focus
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"

        # Move to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Appearance
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(89b4faee)";  # Catppuccin blue
        "col.inactive_border" = "rgba(313244aa)";
      };

      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 5;
          passes = 2;
        };
      };

      animations = {
        enabled = true;
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
      };

      # Override deprecated gestures section (empty to prevent home-manager defaults)
      gestures = {};

      # Touchpad gestures (new syntax)
      gesture = [
        "3, horizontal, workspace"  # 3-finger swipe for workspace switching
      ];
    };
  };

  # Foot terminal (simple, fast, works out of box)
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
      };
      colors = {
        # Catppuccin Mocha
        background = "1e1e2e";
        foreground = "cdd6f4";
      };
    };
  };

  # Essential Wayland packages
  home.packages = with pkgs; [
    rofi              # App launcher (Wayland support merged upstream)
    wl-clipboard      # Clipboard
    grim              # Screenshots
    slurp             # Screen region select
    mako              # Notifications
  ];
}
