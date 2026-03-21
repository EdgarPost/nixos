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

{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hyprland;

  # Rofi project picker → tmux session per ghq project
  tmux-project = pkgs.writeShellScriptBin "tmux-project" ''
    root=$(${pkgs.ghq}/bin/ghq root)

    # Show rofi picker with ghq projects
    selected=$(${pkgs.ghq}/bin/ghq list | rofi -dmenu -p "Project" -i)
    [ -z "$selected" ] && exit 0

    name="''${selected##*/}"
    path="$root/$selected"

    # Ensure tmux session exists for this project
    tmux has-session -t "=$name" 2>/dev/null || \
      tmux new-session -d -s "$name" -c "$path"

    # Focus existing ghostty or launch new one
    if hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "com.mitchellh.ghostty")' > /dev/null 2>&1; then
      hyprctl dispatch focuswindow class:com.mitchellh.ghostty
      # Switch tmux client to the project session
      tmux switch-client -t "=$name"
    else
      # Launch ghostty with this project's tmux session
      ghostty -e tmux new-session -A -s "$name" -c "$path" &
    fi
  '';

  # Open khal in tmux session, reusing existing ghostty if available
  open-calendar = pkgs.writeShellScriptBin "open-calendar" ''
    # Ensure tmux session "khal" exists
    tmux has-session -t =khal 2>/dev/null || \
      tmux new-session -d -s khal 'khal interactive'

    # Focus existing ghostty or launch new one
    if hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "com.mitchellh.ghostty")' > /dev/null 2>&1; then
      hyprctl dispatch focuswindow class:com.mitchellh.ghostty
      tmux switch-client -t =khal
    else
      ghostty -e tmux new-session -A -s khal 'khal interactive' &
    fi
  '';

  # Rofi power menu
  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    choice=$(echo -e "Lock\nAway\nSuspend\nReboot\nShutdown" | rofi -dmenu -p "Power")
    case "$choice" in
      Lock) loginctl lock-session; sleep 1; hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name' | xargs -I{} hyprctl dispatch dpms off {} ;;
      Away) hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name' | xargs -I{} hyprctl dispatch dpms off {} ;;
      Suspend) systemctl suspend ;;
      Reboot) systemctl reboot ;;
      Shutdown) systemctl poweroff ;;
    esac
  '';

  # Catppuccin wallpapers - fetched at build time
  catppuccin-wallpapers = pkgs.fetchFromGitHub {
    owner = "zhichaoh";
    repo = "catppuccin-wallpapers";
    rev = "1023077979591cdeca76aae94e0359da1707a60e";
    sha256 = "sha256-h+cFlTXvUVJPRMpk32jYVDDhHu1daWSezFcvhJqDpmU=";
  };
in
{
  options.hyprland.enableFancyEffects = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable expensive visual effects (blur, animations). Disable on iGPU/high-res setups.";
  };

  config = {
    wayland.windowManager.hyprland = {
      enable = true;
      # Use the Hyprland package from NixOS module (avoid duplicate installations)
      package = null;
      portalPackage = null;
      # Let systemd manage the session (creates hyprland-session.target for waybar)
      systemd.enable = true;

      settings = {
        # =======================================================================
        # WORKSPACE RULES
        # =======================================================================
        workspace = [ ];

        # =======================================================================
        # WINDOW RULES
        # =======================================================================
        windowrule = [
          "float on, match:title ^(Picture-in-Picture)$"
          "pin on, match:title ^(Picture-in-Picture)$"
          "size 640 360, match:title ^(Picture-in-Picture)$"
          "move 3437 68, match:title ^(Picture-in-Picture)$"
          "keep_aspect_ratio on, match:title ^(Picture-in-Picture)$"
          "no_initial_focus on, match:title ^(Picture-in-Picture)$"
          "no_follow_mouse on, match:title ^(Picture-in-Picture)$"
          "focus_on_activate false, match:title ^(Picture-in-Picture)$"
        ];

        # =======================================================================
        # MONITOR CONFIGURATION
        # =======================================================================
        # Format: name,resolution,position,scale
        # "highrr" = prefer highest refresh rate available
        # "auto" = let Hyprland position the monitor
        # Use `hyprctl monitors` to see detected monitors
        monitor = [
          ",preferred,auto,1" # Fallback for any other monitors
        ];

        # Define variables for use throughout config
        # Similar to shell variables, but Hyprland-specific
        "$mod" = "SUPER"; # Windows/Super key as modifier
        "$hyper" = "SUPER SHIFT CTRL ALT"; # Caps Lock via keyd
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
          "TMUX_TMPDIR,$XDG_RUNTIME_DIR"
        ];

        # =======================================================================
        # STARTUP APPLICATIONS
        # =======================================================================
        # exec-once: Run once when Hyprland starts (not on config reload)
        # exec: Run on every config reload
        exec-once = [
          # CRITICAL: Update DBus environment so portals and apps can access Wayland
          # This MUST run first, before any apps that depend on DBus/portals
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE"
          "wl-paste --watch cliphist store" # Clipboard history daemon
          "1password --silent" # Start 1Password daemon for SSH agent
          # waybar is now managed by systemd (see waybar.nix)
          "swww-daemon" # Wallpaper daemon (supports animated transitions)
          # Set random wallpaper from ~/.wallpapers on login (wait for daemon, then animate)
          # First set Catppuccin Mocha crust color, then transition to wallpaper
          "until swww clear 11111b 2>/dev/null; do sleep 0.1; done && swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1"
          "swaync" # Notification center (replacing mako)
          "handy --start-hidden" # Offline speech-to-text (toggle with Super+V)
        ];

        # =======================================================================
        # KEYBINDINGS - bind (normal, single press)
        # =======================================================================
        # Format: "MODIFIERS, key, action, args"
        # Modifiers: SUPER, SHIFT, CTRL, ALT (combine with space: "SUPER SHIFT")
        bind = [
          # =============================================================
          # HYPER KEY BINDINGS (Caps Lock via keyd)
          # High-level OS actions: app focus, launchers, session control
          # =============================================================
          "$hyper, D, exec, $menu"
          "$hyper, C, exec, open-calendar"
          "$hyper, M, exit"
          "$hyper, H, exec, handy --toggle-transcription"
          "$hyper, W, exec, swww img \"$(find -L ~/.wallpapers -type f | shuf -n 1)\" --transition-type grow --transition-pos center --transition-duration 1"
          "$hyper, A, exec, audio-menu"
          "$hyper, P, exec, tmux-project"
          "$hyper, V, exec, cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy && wtype -M ctrl -k v"
          "$hyper, B, exec, hyprctl clients -j | jq -e '.[] | select(.class == \"zen\")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:zen || zen"
          "$hyper, S, exec, hyprctl clients -j | jq -e '.[] | select(.class == \"Slack\")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:Slack || slack"
          "$hyper, T, exec, hyprctl clients -j | jq -e '.[] | select(.class == \"com.mitchellh.ghostty\")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:com.mitchellh.ghostty || $terminal"
          "$hyper, Y, exec, hyprctl clients -j | jq -e '.[] | select(.class == \"yazi\")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:yazi || ghostty --class=yazi -e yazi"

          # =============================================================
          # MOD KEY BINDINGS (SUPER)
          # Window management, navigation, workspaces
          # =============================================================
          "$mod, Q, killactive"
          "$mod, F, fullscreen"
          "$mod, G, togglefloating"
          "$hyper, N, exec, swaync-client -t" # Toggle notification center

          # Cycle column width (0.333 → 0.5 → 0.75 → 1.0)
          "$mod CTRL, L, layoutmsg, colresize +conf"
          "$mod CTRL, H, layoutmsg, colresize -conf"

          # Move focus
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          # Move window (swapcol keeps windows as standalone columns)
          "$mod SHIFT, H, layoutmsg, swapcol l"
          "$mod SHIFT, L, layoutmsg, swapcol r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"

          # Workspaces 1-9
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"

          # Media controls
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPrev, exec, playerctl previous"
          ", XF86AudioStop, exec, playerctl stop"

          # Power menu (lock, suspend, reboot, shutdown)
          "$hyper, Escape, exec, power-menu"

          # Screenshots (to clipboard)
          "$mod CTRL, S, exec, grim - | wl-copy" # Full screen
          "$mod CTRL SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy" # Region select

          # Power menu (triggered by power button)
          ", XF86PowerOff, exec, power-menu"

          # Next/previous workspace
          "$mod, Tab, workspace, e+1"
          "$mod SHIFT, Tab, workspace, e-1"

          # Move current window to next workspace
          "$mod SHIFT, N, movetoworkspace, e+1"

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

          # Resize column
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
          layout = "scrolling";
          gaps_in = 8;
          gaps_out = 16;
          border_size = 2;
          "col.inactive_border" = "rgba(00000000)"; # Transparent - no border on inactive
        };

        scrolling = {
          column_width = 0.5;
          focus_fit_method = 1; # Fit: minimal scroll to show focused column (two 0.5 columns sit side by side)
          explicit_column_widths = "0.333, 0.5, 0.75, 1.0";
        };

        decoration = {
          rounding = 8;
          shadow = {
            enabled = false;
          };
          blur = {
            enabled = cfg.enableFancyEffects;
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
        cursor = {
          no_hardware_cursors = true; # Use software cursors (avoids GPU cursor plane issues)
          use_cpu_buffer = true; # CPU-side cursor buffer (fixes cursor vanishing on Intel iGPU hotplug)
        };

        misc = {
          focus_on_activate = true; # Auto-focus windows when they request attention (e.g. browser from terminal)
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          vfr = true; # Variable Frame Rate - only render when needed (saves CPU)
          mouse_move_enables_dpms = true; # Wake display on mouse move
          key_press_enables_dpms = true; # Wake display on key press
        };

        # =======================================================================
        # INPUT CONFIGURATION
        # =======================================================================
        input = {
          kb_layout = "us";
          kb_options = "compose:ralt"; # Right Alt as Compose key for accented chars
          follow_mouse = 1; # Focus follows mouse
          sensitivity = -0.9; # 0 = no modification to input speed
          accel_profile = "adaptive"; # No acceleration (1:1 mouse movement)
          touchpad = {
            natural_scroll = true; # Two-finger scroll direction (like macOS)
          };
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

        input-field = [
          {
            monitor = "";
            size = "300, 50";
            outline_thickness = 2;
            fade_on_empty = true;
            placeholder_text = "";
            hide_input = false;
          }
        ];

        label = [ ];
      };
    };

    # ==========================================================================
    # HYPRIDLE - Idle Daemon
    # ==========================================================================
    # Reports idle status to D-Bus (Slack etc. show "away") and manages
    # screen lock + DPMS after inactivity. Services and SSH stay running.
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof hyprlock || hyprlock";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = 300; # 5 min → lock
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = 330; # 5.5 min → screen off
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
        ];
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
    # WALLPAPERS
    # ==========================================================================
    # Symlink Catppuccin landscape wallpapers to ~/.wallpapers
    # These are fetched from GitHub at build time
    home.file.".wallpapers".source = "${catppuccin-wallpapers}/landscapes";

    # ==========================================================================
    # WAYLAND UTILITIES
    # ==========================================================================
    # Essential tools for a functional Wayland desktop
    home.packages = [
      tmux-project
      open-calendar
      power-menu
    ]
    ++ (with pkgs; [
      jq # JSON query tool
      wl-clipboard # Clipboard: wl-copy, wl-paste (like xclip for Wayland)
      cliphist # Clipboard history manager (stores history, pairs with rofi)
      wtype # Wayland keyboard input simulator (for auto-paste after clipboard selection)
      grim # Screenshots: grim -g "$(slurp)" screenshot.png
      slurp # Region selector (used with grim for area screenshots)
      brightnessctl # Brightness: brightnessctl set 50%
      playerctl # Media control: playerctl play-pause, next, previous
      swww # Wallpaper daemon: swww img ~/wallpaper.png
    ]);
  }; # End of config
}
