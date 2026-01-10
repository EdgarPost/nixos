# ============================================================================
# NIRI HOME MODULE - Window Manager Configuration
# ============================================================================
#
# Niri is a scrollable-tiling Wayland compositor with per-monitor workspaces.
# This config uses niri defaults with minimal additions.
#
# Config file: ~/.config/niri/config.kdl
# Docs: https://github.com/YaLTeR/niri/wiki/Configuration
#
# ============================================================================

{ config, pkgs, lib, ... }:

let
  catppuccin-wallpapers = pkgs.fetchFromGitHub {
    owner = "zhichaoh";
    repo = "catppuccin-wallpapers";
    rev = "1023077979591cdeca76aae94e0359da1707a60e";
    sha256 = "sha256-h+cFlTXvUVJPRMpk32jYVDDhHu1daWSezFcvhJqDpmU=";
  };
in
{
  # ==========================================================================
  # NIRI CONFIG FILE (KDL format) - Defaults + must-haves only
  # ==========================================================================
  xdg.configFile."niri/config.kdl".text = ''
    // =======================================================================
    // MONITOR CONFIGURATION (hardware-specific)
    // =======================================================================
    output "eDP-1" {
        scale 1.0
    }

    output "Dell Inc. DELL U4025QW" {
        mode "5120x2160@60"
        scale 1.25
    }

    // =======================================================================
    // INPUT - Only non-default settings
    // =======================================================================
    input {
        touchpad {
            tap
            natural-scroll
        }
        focus-follows-mouse
    }

    // =======================================================================
    // SPAWN AT STARTUP
    // =======================================================================
    spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"
    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"
    spawn-at-startup "1password" "--silent"
    spawn-at-startup "swaync"
    spawn-at-startup "swww-daemon"
    spawn-at-startup "sh" "-c" "sleep 1 && swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1"

    // =======================================================================
    // KEYBINDINGS - HJKL additions + custom launchers
    // All other keybindings use niri defaults (arrow keys, workspaces, etc.)
    // =======================================================================
    binds {
        // HJKL navigation (in addition to default arrow keys)
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-up; }
        Mod+J { focus-window-down; }
        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+K { move-window-up; }
        Mod+Shift+J { move-window-down; }

        // Custom launchers
        Mod+D { spawn "rofi" "-show" "drun"; }
        Mod+C { spawn "ghostty" "-e" "khal" "interactive"; }

        // Lock and sleep
        Mod+Escape { spawn "swaylock"; }
        Mod+Shift+Escape { spawn "systemctl" "suspend"; }

        // Screenshots (to clipboard)
        Print { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }
        Shift+Print { spawn "sh" "-c" "grim - | wl-copy"; }

        // Clipboard history
        Mod+Shift+V { spawn "sh" "-c" "cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy && wtype -M ctrl -k v"; }

        // Wallpaper change
        Mod+W { spawn "sh" "-c" "swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1"; }

        // Audio menu
        Mod+A { spawn "audio-menu"; }

        // Notification center toggle
        Mod+N { spawn "swaync-client" "-t" "-sw"; }

        // Power menu
        XF86PowerOff { spawn "sh" "-c" "echo -e 'Shutdown\\nReboot\\nSuspend\\nLock\\nCancel' | rofi -dmenu -p 'Power' | xargs -I {} sh -c 'case {} in Shutdown) systemctl poweroff ;; Reboot) systemctl reboot ;; Suspend) systemctl suspend ;; Lock) swaylock ;; esac'"; }
    }
  '';

  # ==========================================================================
  # SWAYLOCK - Screen Locker (replaces hyprlock)
  # ==========================================================================
  programs.swaylock = {
    enable = true;
    settings = {
      daemonize = true;
      show-failed-attempts = true;
      indicator-caps-lock = true;
      # Colors handled by catppuccin.swaylock.enable
    };
  };
  catppuccin.swaylock.enable = true;

  # ==========================================================================
  # ROFI - Application Launcher
  # ==========================================================================
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      display-drun = " Apps";
      display-run = " Run";
      display-window = " Windows";
      drun-display-format = "{name}";
    };
  };
  catppuccin.rofi.enable = true;

  # ==========================================================================
  # WALLPAPERS
  # ==========================================================================
  home.file.".wallpapers".source = "${catppuccin-wallpapers}/landscapes";

  # ==========================================================================
  # WAYLAND UTILITIES
  # ==========================================================================
  home.packages = with pkgs; [
    wl-clipboard
    cliphist
    wtype
    grim
    slurp
    brightnessctl
    playerctl
    swww
  ];
}
