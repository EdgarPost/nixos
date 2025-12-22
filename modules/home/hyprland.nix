# ============================================================================
# HYPRLAND HOME MODULE - Window Manager Configuration
# ============================================================================
#
# SYSTEM VS HOME MANAGER:
# System module (modules/nixos/hyprland.nix): Installs Hyprland, portals, fonts
# This module: User preferences - keybindings, appearance, startup apps
#
# HYPRLAND KEYBINDING TYPES:
#   bind   - Normal binding, executes once per keypress
#   binde  - Repeating binding, executes while held (volume, resize)
#   bindl  - Locked binding, works on lockscreen too
#   bindm  - Mouse binding (drag to move/resize windows)
#
# VARIABLE SYNTAX:
#   $varname = "value"     # Define a variable
#   $varname, action       # Use the variable
#
# ============================================================================

{ config, pkgs, ... }:

let
  # Catppuccin wallpapers - fetched at build time
  catppuccin-wallpapers = pkgs.fetchFromGitHub {
    owner = "zhichaoh";
    repo = "catppuccin-wallpapers";
    rev = "1023077979591cdeca76aae94e0359da1707a60e";
    sha256 = "sha256-h+cFlTXvUVJPRMpk32jYVDDhHu1daWSezFcvhJqDpmU=";
  };
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # Use the Hyprland package from NixOS module (avoid duplicate installations)
    package = null;
    portalPackage = null;

    settings = {
      # =======================================================================
      # MONITOR CONFIGURATION
      # =======================================================================
      # Format: name,resolution,position,scale
      # "highrr" = prefer highest refresh rate available
      # "auto" = let Hyprland position the monitor
      # Use `hyprctl monitors` to see detected monitors
      monitor = ",highrr,auto,1";

      # Define variables for use throughout config
      # Similar to shell variables, but Hyprland-specific
      "$mod" = "SUPER"; # Windows/Super key as modifier
      "$terminal" = "ghostty"; # Default terminal emulator
      "$menu" = "rofi -show drun"; # Application launcher

      # =======================================================================
      # ENVIRONMENT VARIABLES
      # =======================================================================
      # Required for XDG portals and Wayland apps to work correctly
      env = [
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];

      # =======================================================================
      # STARTUP APPLICATIONS
      # =======================================================================
      # exec-once: Run once when Hyprland starts (not on config reload)
      # exec: Run on every config reload
      exec-once = [
        # CRITICAL: Update DBus environment so portals and apps can access Wayland
        # This MUST run first, before any apps that depend on DBus/portals
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "wl-paste --watch cliphist store" # Clipboard history daemon
        "1password --silent" # Start 1Password daemon for SSH agent
        "waybar" # Status bar
        "swww-daemon" # Wallpaper daemon (supports animated transitions)
        # Set random wallpaper from ~/.wallpapers on login (wait for daemon, then animate)
        # First set Catppuccin Mocha crust color, then transition to wallpaper
        "until swww clear 11111b 2>/dev/null; do sleep 0.1; done && swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1"
      ];

      # =======================================================================
      # KEYBINDINGS - bind (normal, single press)
      # =======================================================================
      # Format: "MODIFIERS, key, action, args"
      # Modifiers: SUPER, SHIFT, CTRL, ALT (combine with space: "SUPER SHIFT")
      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, D, exec, $menu"
        "$mod, C, exec, $terminal -e khal interactive"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, F, fullscreen"
        "$mod, W, exec, swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1"

        # Move focus
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Move window
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

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

        # Media controls
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioStop, exec, playerctl stop"

        # Lock and sleep
        "$mod, Escape, exec, hyprlock" # Lock screen
        "$mod SHIFT, Escape, exec, systemctl suspend" # Sleep/suspend

        # Screenshots (to clipboard)
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy" # Select region
        "SHIFT, Print, exec, grim - | wl-copy" # Full screen

        # Clipboard history
        #"CTRL SHIFT, V, exec, cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy"
      ];

      # =======================================================================
      # KEYBINDINGS - binde (repeating, held keys)
      # =======================================================================
      # These trigger repeatedly while the key is held down
      # Perfect for volume, brightness, and window resizing
      binde = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ && pkill -RTMIN+10 waybar"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && pkill -RTMIN+10 waybar"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"

        # Resize window
        "$mod CTRL, H, resizeactive, -20 0"
        "$mod CTRL, L, resizeactive, 20 0"
        "$mod CTRL, K, resizeactive, 0 -20"
        "$mod CTRL, J, resizeactive, 0 20"
      ];

      # =======================================================================
      # KEYBINDINGS - bindl (locked, work on lockscreen)
      # =======================================================================
      # These work even when the screen is locked
      # Useful for mute and hardware switches
      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && pkill -RTMIN+10 waybar"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        # Lid close: disable laptop screen and move workspaces to external
        ", switch:on:Lid Switch, exec, hyprctl keyword monitor eDP-1,disable"
        # Lid open: re-enable laptop screen
        ", switch:off:Lid Switch, exec, hyprctl keyword monitor eDP-1,preferred,auto,1"
      ];

      # =======================================================================
      # KEYBINDINGS - bindm (mouse bindings)
      # =======================================================================
      # Mod + click/drag to move or resize windows
      # mouse:272 = left click, mouse:273 = right click
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # =======================================================================
      # APPEARANCE
      # =======================================================================
      # Visual settings for windows and gaps
      # Border colors are set by the catppuccin module automatically
      general = {
        gaps_in = 15;
        gaps_out = 30;
        border_size = 2;
        "col.inactive_border" = "rgba(00000000)"; # Transparent - no border on inactive
      };

      decoration = {
        rounding = 8;
        shadow = {
          enabled = false;
        };
        blur = {
          enabled = true;
          size = 8;
          passes = 3;
          new_optimizations = true;
          xray = false; # Blur desktop behind floating windows, not window below
          noise = 0.01;
          contrast = 1.0;
          brightness = 1.0;
          vibrancy = 0.2;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "wind, 0.05, 0.85, 0.03, 0.97"
          "winIn, 0.07, 0.88, 0.04, 0.99"
          "winOut, 0.20, -0.15, 0, 1"
          "liner, 1, 1, 1, 1"
          "md3_decel, 0.05, 0.80, 0.10, 0.97"
          "menu_decel, 0.05, 0.82, 0, 1"
          "menu_accel, 0.20, 0, 0.82, 0.10"
          "easeOutCirc, 0, 0.48, 0.38, 1"
        ];
        animation = [
          "border, 1, 1.6, liner"
          "borderangle, 1, 82, liner, loop"
          "windowsIn, 1, 3.2, winIn, slide"
          "windowsOut, 1, 2.8, easeOutCirc"
          "windowsMove, 1, 3.0, wind, slide"
          "fade, 1, 1.8, md3_decel"
          "layersIn, 1, 1.8, menu_decel, slide"
          "layersOut, 1, 1.5, menu_accel"
          "fadeLayersIn, 1, 1.6, menu_decel"
          "fadeLayersOut, 1, 1.8, menu_accel"
          "workspaces, 1, 4.0, menu_decel, slide"
          "specialWorkspace, 1, 2.3, md3_decel, slidefadevert 15%"
        ];
      };

      # =======================================================================
      # MISC SETTINGS
      # =======================================================================
      misc = {
        focus_on_activate = true; # Auto-focus windows when they request attention (e.g. browser from terminal)
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      # =======================================================================
      # INPUT CONFIGURATION
      # =======================================================================
      input = {
        kb_layout = "us";
        follow_mouse = 1; # Focus follows mouse
        sensitivity = 0; # 0 = no modification to input speed
        accel_profile = "flat"; # No acceleration (1:1 mouse movement)
        touchpad = {
          natural_scroll = true; # Two-finger scroll direction (like macOS)
        };
      };

      # Per-device input settings
      # Find device names with: hyprctl devices
      device = {
        name = "pixa3854:00-093a:0274-touchpad"; # Framework's Pixart touchpad
        sensitivity = 0.3; # Higher sensitivity for trackpad
        accel_profile = "adaptive"; # Enable acceleration for trackpad
      };

    }; # End of settings

    # =======================================================================
    # EXTRA CONFIGURATION
    # =======================================================================
    # Raw Hyprland config for features not yet in Home Manager module
    extraConfig = ''
      # Touchpad gestures: 3-finger horizontal swipe switches workspace
      gesture = 3, horizontal, workspace
    '';
  };

  # ==========================================================================
  # HYPRLOCK - Screen Locker
  # ==========================================================================
  # Hyprland-native lock screen with blur and customization
  # Lock: Super+Escape | Sleep: Super+Shift+Escape
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
      };

      background = [
        {
          monitor = "";
          path = "screenshot"; # Use screenshot of current screen
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      # No input-field or label = completely clean look
      label = [ ]; # Remove default keyboard layout indicator
    };
  };

  # ==========================================================================
  # ROFI - Application Launcher
  # ==========================================================================
  # Rofi: dmenu replacement with nice UI for launching apps
  # Triggered by: Super+D (defined in keybindings above)
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
  # Enable Catppuccin theme for Rofi (from catppuccin flake)
  catppuccin.rofi.enable = true;

  # ==========================================================================
  # MAKO - Notification Daemon
  # ==========================================================================
  # Lightweight notification daemon for Wayland
  # Test with: notify-send "Title" "Body text"
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
  # Symlink Catppuccin landscape wallpapers to ~/.wallpapers
  # These are fetched from GitHub at build time
  home.file.".wallpapers".source = "${catppuccin-wallpapers}/landscapes";

  # ==========================================================================
  # WAYLAND UTILITIES
  # ==========================================================================
  # Essential tools for a functional Wayland desktop
  home.packages = with pkgs; [
    wl-clipboard # Clipboard: wl-copy, wl-paste (like xclip for Wayland)
    cliphist # Clipboard history manager (stores history, pairs with rofi)
    grim # Screenshots: grim -g "$(slurp)" screenshot.png
    slurp # Region selector (used with grim for area screenshots)
    brightnessctl # Brightness: brightnessctl set 50%
    playerctl # Media control: playerctl play-pause, next, previous
    swww # Wallpaper daemon: swww img ~/wallpaper.png
  ];
}
