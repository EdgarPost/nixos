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
        warp-mouse-to-focus
    }

    // =======================================================================
    // LAYOUT
    // =======================================================================
    layout {
        default-column-width { proportion 0.5; }
    }

    // =======================================================================
    // NAMED WORKSPACES
    // =======================================================================
    workspace "browser"
    workspace "terminal"
    workspace "communication"
    workspace "other"

    // =======================================================================
    // WINDOW RULES - assign apps to workspaces
    // =======================================================================
    window-rule {
        match app-id="zen"
        open-on-workspace "browser"
    }

    window-rule {
        match app-id="com.mitchellh.ghostty"
        open-on-workspace "terminal"
    }

    window-rule {
        match app-id="Slack"
        open-on-workspace "communication"
    }

    window-rule {
        match app-id="signal"
        open-on-workspace "communication"
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
    // KEYBINDINGS - niri defaults + custom overrides
    // =======================================================================
    binds {
        // ===== CUSTOM OVERRIDES =====
        Mod+T { spawn "ghostty"; }
        Mod+D { spawn "rofi" "-show" "drun"; }
        Mod+Escape { spawn "swaylock"; }
        Mod+Shift+Escape { spawn "systemctl" "suspend"; }
        Mod+A { spawn "audio-menu"; }
        Mod+N { spawn "swaync-client" "-t" "-sw"; }
        Mod+Shift+C { spawn "ghostty" "-e" "khal" "interactive"; }
        Mod+Shift+W { spawn "sh" "-c" "swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1"; }
        Mod+Shift+B { spawn "sh" "-c" "cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy && wtype -M ctrl -k v"; }
        XF86PowerOff { spawn "sh" "-c" "echo -e 'Shutdown\\nReboot\\nSuspend\\nLock\\nCancel' | rofi -dmenu -p 'Power' | xargs -I {} sh -c 'case {} in Shutdown) systemctl poweroff ;; Reboot) systemctl reboot ;; Suspend) systemctl suspend ;; Lock) swaylock ;; esac'"; }

        // ===== NIRI DEFAULTS =====
        Mod+Shift+Slash { show-hotkey-overlay; }
        Mod+O repeat=false { toggle-overview; }
        Mod+Q repeat=false { close-window; }

        // Focus
        Mod+Left { focus-column-left; }
        Mod+Down { focus-window-down; }
        Mod+Up { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+H { focus-column-left; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+L { focus-column-right; }
        Mod+Home { focus-column-first; }
        Mod+End { focus-column-last; }

        // Move columns/windows
        Mod+Ctrl+Left { move-column-left; }
        Mod+Ctrl+Down { move-window-down; }
        Mod+Ctrl+Up { move-window-up; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+J { move-window-down; }
        Mod+Ctrl+K { move-window-up; }
        Mod+Ctrl+L { move-column-right; }
        Mod+Ctrl+Home { move-column-to-first; }
        Mod+Ctrl+End { move-column-to-last; }

        // Monitor focus/move
        Mod+Shift+Left { focus-monitor-left; }
        Mod+Shift+Down { focus-monitor-down; }
        Mod+Shift+Up { focus-monitor-up; }
        Mod+Shift+Right { focus-monitor-right; }
        Mod+Shift+H { focus-monitor-left; }
        Mod+Shift+J { focus-monitor-down; }
        Mod+Shift+K { focus-monitor-up; }
        Mod+Shift+L { focus-monitor-right; }
        Mod+Shift+Ctrl+Left { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+Down { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+Up { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
        Mod+Shift+Ctrl+H { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+J { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+K { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+L { move-column-to-monitor-right; }

        // Workspaces
        Mod+Page_Down { focus-workspace-down; }
        Mod+Page_Up { focus-workspace-up; }
        Mod+U { focus-workspace-down; }
        Mod+I { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
        Mod+Ctrl+U { move-column-to-workspace-down; }
        Mod+Ctrl+I { move-column-to-workspace-up; }
        Mod+Shift+Page_Down { move-workspace-down; }
        Mod+Shift+Page_Up { move-workspace-up; }
        Mod+Shift+U { move-workspace-down; }
        Mod+Shift+I { move-workspace-up; }
        // Named workspaces
        Mod+1 { focus-workspace "browser"; }
        Mod+2 { focus-workspace "terminal"; }
        Mod+3 { focus-workspace "communication"; }
        Mod+4 { focus-workspace "other"; }
        Mod+Ctrl+1 { move-column-to-workspace "browser"; }
        Mod+Ctrl+2 { move-column-to-workspace "terminal"; }
        Mod+Ctrl+3 { move-column-to-workspace "communication"; }
        Mod+Ctrl+4 { move-column-to-workspace "other"; }

        // Scroll wheel
        Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
        Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
        Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }
        Mod+WheelScrollRight { focus-column-right; }
        Mod+WheelScrollLeft { focus-column-left; }
        Mod+Ctrl+WheelScrollRight { move-column-right; }
        Mod+Ctrl+WheelScrollLeft { move-column-left; }
        Mod+Shift+WheelScrollDown { focus-column-right; }
        Mod+Shift+WheelScrollUp { focus-column-left; }
        Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
        Mod+Ctrl+Shift+WheelScrollUp { move-column-left; }

        // Column/window management
        Mod+BracketLeft { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }
        Mod+Comma { consume-window-into-column; }
        Mod+Period { expel-window-from-column; }
        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { switch-preset-window-height; }
        Mod+Ctrl+R { reset-window-height; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+M { maximize-window-to-edges; }
        Mod+Ctrl+F { expand-column-to-available-width; }
        Mod+C { center-column; }
        Mod+Ctrl+C { center-visible-columns; }
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }
        Mod+V { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }
        Mod+W { toggle-column-tabbed-display; }

        // Media keys
        XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+" "-l" "1.0"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
        XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }
        XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
        XF86AudioStop allow-when-locked=true { spawn "playerctl" "stop"; }
        XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
        XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
        XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "+10%"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "--class=backlight" "set" "10%-"; }

        // Screenshots
        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }

        // System
        Mod+Shift+E { quit; }
        Ctrl+Alt+Delete { quit; }
        Mod+Shift+P { power-off-monitors; }
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
