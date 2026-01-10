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
  # Niri configuration via niri-flake's declarative settings
  programs.niri = {
    settings = {
      # =======================================================================
      # MONITOR CONFIGURATION
      # =======================================================================
      outputs = {
        "eDP-1" = {
          scale = 1.0;
        };
        "Dell Inc. DELL U4025QW" = {
          scale = 1.25;
          mode = {
            width = 5120;
            height = 2160;
            refresh = 60.0;
          };
        };
      };

      # =======================================================================
      # INPUT CONFIGURATION
      # =======================================================================
      input = {
        keyboard.xkb.layout = "us";
        mouse = {
          accel-profile = "flat";
        };
        touchpad = {
          natural-scroll = true;
          accel-profile = "adaptive";
        };
      };

      # =======================================================================
      # LAYOUT
      # =======================================================================
      layout = {
        gaps = 15;
        center-focused-column = "never";
        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        default-column-width = { proportion = 1.0 / 2.0; };
        focus-ring = {
          enable = true;
          width = 2;
          active.color = "#89b4fa";  # Catppuccin Mocha blue
          inactive.color = "#00000000";  # Transparent
        };
        border = {
          enable = false;
        };
      };

      # =======================================================================
      # APPEARANCE
      # =======================================================================
      prefer-no-csd = true;  # Server-side decorations

      # =======================================================================
      # SPAWN AT STARTUP
      # =======================================================================
      spawn-at-startup = [
        { command = [ "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" ]; }
        { command = [ "wl-paste" "--watch" "cliphist" "store" ]; }
        { command = [ "1password" "--silent" ]; }
        { command = [ "pasystray" ]; }
        { command = [ "swww-daemon" ]; }
        # Set wallpaper after swww-daemon starts
        { command = [ "sh" "-c" "sleep 1 && swww clear 11111b && swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1" ]; }
      ];

      # =======================================================================
      # KEYBINDINGS (Niri defaults - arrow keys)
      # =======================================================================
      binds = with config.lib.niri.actions; {
        # Terminal and launcher
        "Mod+Return".action = spawn "ghostty";
        "Mod+D".action = spawn "rofi" "-show" "drun";
        "Mod+C".action = spawn "ghostty" "-e" "khal" "interactive";
        "Mod+Q".action = close-window;
        "Mod+Shift+E".action = quit;

        # Focus (arrow keys - Niri default)
        "Mod+Left".action = focus-column-left;
        "Mod+Right".action = focus-column-right;
        "Mod+Up".action = focus-window-up;
        "Mod+Down".action = focus-window-down;

        # Move window
        "Mod+Shift+Left".action = move-column-left;
        "Mod+Shift+Right".action = move-column-right;
        "Mod+Shift+Up".action = move-window-up;
        "Mod+Shift+Down".action = move-window-down;

        # Workspaces (1-10)
        "Mod+1".action = focus-workspace 1;
        "Mod+2".action = focus-workspace 2;
        "Mod+3".action = focus-workspace 3;
        "Mod+4".action = focus-workspace 4;
        "Mod+5".action = focus-workspace 5;
        "Mod+6".action = focus-workspace 6;
        "Mod+7".action = focus-workspace 7;
        "Mod+8".action = focus-workspace 8;
        "Mod+9".action = focus-workspace 9;
        "Mod+0".action = focus-workspace 10;

        # Move to workspace
        "Mod+Shift+1".action = move-column-to-workspace 1;
        "Mod+Shift+2".action = move-column-to-workspace 2;
        "Mod+Shift+3".action = move-column-to-workspace 3;
        "Mod+Shift+4".action = move-column-to-workspace 4;
        "Mod+Shift+5".action = move-column-to-workspace 5;
        "Mod+Shift+6".action = move-column-to-workspace 6;
        "Mod+Shift+7".action = move-column-to-workspace 7;
        "Mod+Shift+8".action = move-column-to-workspace 8;
        "Mod+Shift+9".action = move-column-to-workspace 9;
        "Mod+Shift+0".action = move-column-to-workspace 10;

        # Window sizing
        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;
        "Mod+V".action = toggle-window-floating;
        "Mod+R".action = switch-preset-column-width;
        "Mod+Minus".action = set-column-width "-10%";
        "Mod+Equal".action = set-column-width "+10%";

        # Media controls
        "XF86AudioPlay".action = spawn "playerctl" "play-pause";
        "XF86AudioNext".action = spawn "playerctl" "next";
        "XF86AudioPrev".action = spawn "playerctl" "previous";
        "XF86AudioStop".action = spawn "playerctl" "stop";

        # Volume (allow when locked)
        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          action = spawn "sh" "-c" "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ && pkill -RTMIN+10 waybar";
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          action = spawn "sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && pkill -RTMIN+10 waybar";
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action = spawn "sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && pkill -RTMIN+10 waybar";
        };
        "XF86AudioMicMute" = {
          allow-when-locked = true;
          action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
        };

        # Brightness
        "XF86MonBrightnessUp".action = spawn "brightnessctl" "set" "5%+";
        "XF86MonBrightnessDown".action = spawn "brightnessctl" "set" "5%-";

        # Lock and sleep
        "Mod+Escape".action = spawn "swaylock";
        "Mod+Shift+Escape".action = spawn "systemctl" "suspend";

        # Screenshots
        "Print".action = spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy";
        "Shift+Print".action = spawn "sh" "-c" "grim - | wl-copy";

        # Clipboard history
        "Mod+Shift+V".action = spawn "sh" "-c" "cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy && wtype -M ctrl -k v";

        # Wallpaper change
        "Mod+W".action = spawn "sh" "-c" "swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1";

        # Audio menu
        "Mod+A".action = spawn "audio-menu";

        # Power menu
        "XF86PowerOff".action = spawn "sh" "-c" "echo -e 'Shutdown\\nReboot\\nSuspend\\nLock\\nCancel' | rofi -dmenu -p 'Power' | xargs -I {} sh -c 'case {} in Shutdown) systemctl poweroff ;; Reboot) systemctl reboot ;; Suspend) systemctl suspend ;; Lock) swaylock ;; esac'";
      };
    };
  };

  # ==========================================================================
  # SWAYLOCK - Screen Locker (replaces hyprlock)
  # ==========================================================================
  programs.swaylock = {
    enable = true;
    settings = {
      daemonize = true;
      show-failed-attempts = true;
      indicator-caps-lock = true;
      # Catppuccin Mocha colors
      color = "1e1e2e";
      inside-color = "1e1e2e";
      ring-color = "89b4fa";
      key-hl-color = "a6e3a1";
      bs-hl-color = "f38ba8";
      text-color = "cdd6f4";
      ring-ver-color = "89b4fa";
      inside-ver-color = "1e1e2e";
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
  # MAKO - Notification Daemon (temporary, will be replaced by SwayNC)
  # ==========================================================================
  services.mako = {
    enable = true;
    settings = {
      anchor = "top-center";
      default-timeout = 5000;
      width = 400;
      margin = "10";
      padding = "15";
      border-radius = 8;
      border-size = 2;
    };
  };

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
