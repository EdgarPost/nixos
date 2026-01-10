# ============================================================================
# NIRI HOME MODULE - Window Manager Configuration
# ============================================================================
#
# Niri is a scrollable-tiling Wayland compositor with per-monitor workspaces.
# Configuration uses Niri's default keybindings (arrow keys, not HJKL).
#
# Key differences from Hyprland:
#   - Scrollable tiling: windows scroll horizontally in columns
#   - Per-monitor workspaces: each monitor has its own workspace set
#   - Built-in lid switch handling: auto-disables internal monitor
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
  # NIRI CONFIG FILE (KDL format)
  # ==========================================================================
  xdg.configFile."niri/config.kdl".text = ''
    // =======================================================================
    // MONITOR CONFIGURATION
    // =======================================================================
    output "eDP-1" {
        scale 1.0
    }

    output "Dell Inc. DELL U4025QW" {
        mode "5120x2160@60"
        scale 1.25
    }

    // =======================================================================
    // INPUT CONFIGURATION
    // =======================================================================
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }

        mouse {
            accel-profile "flat"
        }

        touchpad {
            tap
            natural-scroll
            accel-profile "adaptive"
        }

        // Focus follows mouse
        focus-follows-mouse
    }

    // =======================================================================
    // LAYOUT
    // =======================================================================
    layout {
        gaps 15

        center-focused-column "never"

        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }

        focus-ring {
            width 2
            active-color "#89b4fa"
            inactive-color "#00000000"
        }

        border {
            off
        }
    }

    // =======================================================================
    // APPEARANCE
    // =======================================================================
    prefer-no-csd

    // =======================================================================
    // SPAWN AT STARTUP
    // =======================================================================
    spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"
    spawn-at-startup "wl-paste" "--watch" "cliphist" "store"
    spawn-at-startup "1password" "--silent"
    spawn-at-startup "swaync"
    spawn-at-startup "swww-daemon"
    spawn-at-startup "sh" "-c" "sleep 1 && swww clear 11111b && swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1"

    // =======================================================================
    // KEYBINDINGS
    // =======================================================================
    binds {
        // Terminal and launcher
        Mod+Return { spawn "ghostty"; }
        Mod+D { spawn "rofi" "-show" "drun"; }
        Mod+C { spawn "ghostty" "-e" "khal" "interactive"; }
        Mod+Q { close-window; }
        Mod+Shift+E { quit; }

        // Focus (arrow keys + HJKL)
        Mod+Left { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up { focus-window-up; }
        Mod+Down { focus-window-down; }
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-up; }
        Mod+J { focus-window-down; }

        // Move window (arrow keys + HJKL)
        Mod+Shift+Left { move-column-left; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+Up { move-window-up; }
        Mod+Shift+Down { move-window-down; }
        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+K { move-window-up; }
        Mod+Shift+J { move-window-down; }

        // Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+0 { focus-workspace 10; }

        // Move to workspace
        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }
        Mod+Shift+0 { move-column-to-workspace 10; }

        // Window sizing
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+V { toggle-window-floating; }
        Mod+R { switch-preset-column-width; }
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }

        // Media controls
        XF86AudioPlay { spawn "playerctl" "play-pause"; }
        XF86AudioNext { spawn "playerctl" "next"; }
        XF86AudioPrev { spawn "playerctl" "previous"; }
        XF86AudioStop { spawn "playerctl" "stop"; }

        // Volume
        XF86AudioRaiseVolume allow-when-locked=true { spawn "sh" "-c" "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ && pkill -RTMIN+10 waybar"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && pkill -RTMIN+10 waybar"; }
        XF86AudioMute allow-when-locked=true { spawn "sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && pkill -RTMIN+10 waybar"; }
        XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

        // Brightness
        XF86MonBrightnessUp { spawn "brightnessctl" "set" "5%+"; }
        XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }

        // Lock and sleep
        Mod+Escape { spawn "swaylock"; }
        Mod+Shift+Escape { spawn "systemctl" "suspend"; }

        // Screenshots
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
