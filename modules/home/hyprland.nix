{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null; # Use NixOS module's package
    portalPackage = null;

    settings = {
      # Monitor config (prefer highest refresh rate)
      monitor = ",highrr,auto,1";

      # Mod key (SUPER = Windows key)
      "$mod" = "SUPER";

      # Default apps
      "$terminal" = "ghostty";
      "$menu" = "rofi -show drun";

      # Startup
      exec-once = [
        "1password --silent" # Start 1Password in background
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
      ];

      # Repeat keys (volume, brightness, resize)
      binde = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"

        # Resize window
        "$mod CTRL, H, resizeactive, -20 0"
        "$mod CTRL, L, resizeactive, 20 0"
        "$mod CTRL, K, resizeactive, 0 -20"
        "$mod CTRL, J, resizeactive, 0 20"
      ];

      # Locked keys (work on lockscreen too)
      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        # Lid close: disable laptop screen and move workspaces to external
        ", switch:on:Lid Switch, exec, hyprctl keyword monitor eDP-1,disable"
        # Lid open: re-enable laptop screen
        ", switch:off:Lid Switch, exec, hyprctl keyword monitor eDP-1,preferred,auto,1"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Appearance (colors handled by catppuccin module)
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
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

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0; # Global default
        accel_profile = "flat";
        touchpad = {
          natural_scroll = true;
        };
      };

      # Per-device sensitivity
      device = {
        name = "pixa3854:00-093a:0274-touchpad";  # Framework touchpad
        sensitivity = 0.3;
        accel_profile = "adaptive";  # Enable acceleration for trackpad
      };

    };

    # Touchpad gestures (Hyprland 0.51+ syntax)
    extraConfig = ''
      gesture = 3, horizontal, workspace
    '';
  };

  # Rofi launcher with catppuccin
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

  # Mako notifications (centered at top)
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

  # Essential Wayland packages
  home.packages = with pkgs; [
    wl-clipboard # Clipboard
    grim # Screenshots
    slurp # Screen region select
    brightnessctl # Brightness control
    playerctl # Media control
  ];
}
