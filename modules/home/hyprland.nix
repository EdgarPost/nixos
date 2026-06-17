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

    name=$(echo "''${selected##*/}" | tr '.:' '--')
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
      configType = "hyprlang";
      # Use the Hyprland package from NixOS module (avoid duplicate installations)
      package = null;
      portalPackage = null;
      # Let systemd manage the session (creates hyprland-session.target)
      # Noctalia runs as a systemd user service wired to hyprland-session.target
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

          # hyprland-share-picker (screen/window share selector) reports an
          # empty window class, so match by its title instead.
          "float on, match:title ^(Select what to share)$"
          "center on, match:title ^(Select what to share)$"

          # Keep rendering when occluded so screen sharing can capture these
          # windows even when they're not currently visible. Costs CPU/GPU for
          # apps that animate in the background, so limited to a small allowlist.
          "render_unfocused on, match:class ^(com.mitchellh.ghostty)$"
          "render_unfocused on, match:class ^(zen)$"
        ];

        # =======================================================================
        # MONITOR CONFIGURATION
        # =======================================================================
        # Format: name,resolution,position,scale
        # "highrr" = prefer highest refresh rate available
        # "auto" = let Hyprland position the monitor
        # Use `hyprctl monitors` to see detected monitors
        monitor = [
          # Dell U4025QW: connected via both DisplayPort and Thunderbolt (TB is
          # for USB/KVM passthrough, no video). Both inputs would otherwise show
          # up as separate outputs and confuse screen-share pickers.
          "DP-4,5120x2160@120,0x0,1.25"
          "DP-5,disable"
          ",preferred,auto,1" # Fallback for any other monitors
        ];

        # Define variables for use throughout config
        # Similar to shell variables, but Hyprland-specific
        "$mod" = "SUPER"; # Windows/Super key as modifier
        "$hyper" = "SUPER SHIFT CTRL ALT"; # Caps Lock via keyd
        "$terminal" = "ghostty"; # Default terminal emulator

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
          "1password --silent" # Start 1Password daemon for SSH agent
          # Wallpaper is managed by noctalia (no awww needed)
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
          "$hyper, M, exec, hyprctl clients -j | jq -e '.[] | select(.class == \"thunderbird\")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:thunderbird || thunderbird"
          "$hyper, W, exec, noctalia msg panel-toggle wallpaper" # Wallpaper picker (noctalia IPC)
          "$hyper, A, exec, noctalia msg panel-toggle control-center audio" # Audio panel (noctalia IPC)
          "$hyper, P, exec, tmux-project"
          "$hyper, D, exec, noctalia msg panel-toggle launcher" # App launcher (noctalia IPC; supports apps + emoji + calc)
          "$hyper, B, exec, hyprctl clients -j | jq -e '.[] | select(.class == \"zen\")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:zen || zen"
          "$hyper, S, exec, hyprctl clients -j | jq -e '.[] | select(.class == \"Slack\")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:Slack || slack"
          "$hyper, T, exec, hyprctl clients -j | jq -e '.[] | select(.class == \"com.mitchellh.ghostty\")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:com.mitchellh.ghostty || $terminal"
          "$hyper, V, exec, noctalia msg panel-toggle clipboard" # Clipboard history (noctalia IPC)
          "$hyper, Y, exec, hyprctl clients -j | jq -e '.[] | select(.class == \"yazi\")' > /dev/null 2>&1 && hyprctl dispatch focuswindow class:yazi || ghostty --class=yazi -e yazi"

          # =============================================================
          # MOD KEY BINDINGS (SUPER)
          # Window management, navigation, workspaces
          # =============================================================
          "$mod, Q, killactive"
          "$mod, F, fullscreen"
          "$mod, G, togglefloating"

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

          # Media controls (noctalia IPC over MPRIS, no playerctl needed)
          ", XF86AudioPlay, exec, noctalia msg media toggle"
          ", XF86AudioNext, exec, noctalia msg media next"
          ", XF86AudioPrev, exec, noctalia msg media previous"
          ", XF86AudioStop, exec, noctalia msg media stop"

          # Power menu (noctalia session panel: lock, logout, lock&suspend, reboot, shutdown)
          "$hyper, Escape, exec, noctalia msg panel-toggle session"

          # Screenshots (noctalia IPC; copies to clipboard + saves file)
          "$mod CTRL, S, exec, noctalia msg screenshot-fullscreen" # Full screen
          "$mod CTRL SHIFT, S, exec, noctalia msg screenshot-region" # Region select

          # Power menu (triggered by power button)
          ", XF86PowerOff, exec, noctalia msg panel-toggle session"

          # Next/previous workspace
          "$mod, Tab, workspace, e+1"
          "$mod SHIFT, Tab, workspace, e-1"

          # Move current window to next workspace
          "$mod SHIFT, N, movetoworkspace, e+1"

          # Move current window to next monitor
          "$mod SHIFT, M, movewindow, mon:+1"

        ];

        # =======================================================================
        # KEYBINDINGS - binde (repeating, held keys)
        # =======================================================================
        # These trigger repeatedly while the key is held down
        # Perfect for volume, brightness, and window resizing
        binde = [
          # Volume / brightness via noctalia IPC (OSD feedback for free)
          ", XF86AudioRaiseVolume, exec, noctalia msg volume-up"
          ", XF86AudioLowerVolume, exec, noctalia msg volume-down"
          ", XF86MonBrightnessUp, exec, noctalia msg brightness-up"
          ", XF86MonBrightnessDown, exec, noctalia msg brightness-down"

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
          ", XF86AudioMute, exec, noctalia msg volume-mute"
          ", XF86AudioMicMute, exec, noctalia msg mic-mute"
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
        # Border colors set manually (catppuccin.hyprland disabled, incompatible with Hyprland 0.55.x)
        general = {
          layout = "scrolling";
          gaps_in = 8;
          gaps_out = 16;
          border_size = 2;
          "col.active_border" = "rgba(89b4faff)"; # Catppuccin Mocha blue
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
    # ROFI - Used only by tmux-project picker (not as an app launcher anymore)
    # ==========================================================================
    # Noctalia handles app launching now ($hyper+D). Rofi is still invoked
    # directly by the tmux-project script as a generic dmenu picker.
    # Enable Catppuccin theme for Rofi (from catppuccin flake)
    catppuccin.rofi.enable = true;

    # ==========================================================================
    # WALLPAPERS
    # ==========================================================================
    # Symlink Catppuccin landscape wallpapers to ~/.wallpapers
    # These are fetched from GitHub at build time
    home.file.".wallpapers".source = "${catppuccin-wallpapers}/landscapes";

    # ==========================================================================
    # XDG-DESKTOP-PORTAL-HYPRLAND (screen sharing)
    # ==========================================================================
    # Auto-tick the "allow restore token" checkbox in hyprland-share-picker so
    # subsequent shares from the same app can skip the picker.
    xdg.configFile."hypr/xdph.conf".text = ''
      screencopy {
        allow_token_by_default = true
      }
    '';

    # ==========================================================================
    # WAYLAND UTILITIES
    # ==========================================================================
    # Essential tools for a functional Wayland desktop
    home.packages = [
      tmux-project
      pkgs.rofi # Used by tmux-project picker (catppuccin.rofi themes it)
    ]
    ++ (with pkgs; [
      jq # JSON query tool
      wl-clipboard # Clipboard: wl-copy, wl-paste (like xclip for Wayland)
    ]);
  }; # End of config
}
