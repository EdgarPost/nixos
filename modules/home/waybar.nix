# ============================================================================
# WAYBAR - Status Bar for Wayland
# ============================================================================
#
# WHAT IS WAYBAR?
# A highly customizable status bar for Wayland compositors (Hyprland, Sway).
# Shows system info, workspaces, and integrates with various services.
#
# CONFIGURATION STRUCTURE:
#   settings = [ { ... } ]  - JSON config (modules, layout)
#   style = "..."           - CSS styling (colors, fonts, padding)
#
# MODULES USED HERE:
#   - hyprland/workspaces: Workspace indicators
#   - clock: Date and time
#   - battery: Battery status with warnings
#   - cpu/memory: System resource usage
#   - pulseaudio: Volume with click-to-open pavucontrol
#   - bluetooth: Bluetooth status with click-to-open blueman
#   - network: WiFi/Ethernet status
#   - tray: System tray for background apps
#   - custom/notification: Unread notification count from mako
#
# CLICK HANDLERS:
# Many modules open GUI apps when clicked (requires packages below)
#
# ============================================================================

{ pkgs, ... }:

{
  # GUI applications opened by clicking waybar modules
  home.packages = with pkgs; [
    pavucontrol          # Volume control (pulseaudio module click)
    blueman              # Bluetooth manager (bluetooth module click)
    networkmanagerapplet # Network settings (network module click)
  ];

  programs.waybar = {
    enable = true;
    systemd.enable = true;  # Start waybar as systemd user service

    # ========================================================================
    # WAYBAR CONFIGURATION (JSON)
    # ========================================================================
    # settings is a list because waybar can have multiple bars
    # We only use one bar here
    settings = [{
      layer = "top";
      position = "top";
      height = 30;

      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "custom/notification" "clock" ];
      modules-right = [ "cpu" "memory" "pulseaudio" "bluetooth" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
        };
        on-click = "activate";
      };

      clock = {
        format = "{:%a %d %b  %H:%M}";
        tooltip-format = "{:%A, %B %d, %Y}";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰚥 {capacity}%";
        format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
      };

      cpu = {
        format = "󰻠 {usage}%";
        interval = 5;
      };

      memory = {
        format = "󰍛 {percentage}%";
        interval = 5;
        tooltip-format = "{used:0.1f}GB / {total:0.1f}GB";
      };

      network = {
        format-wifi = "󰖩 {signalStrength}%";
        format-ethernet = "󰈀";
        format-disconnected = "󰖪";
        tooltip-format = "{ifname}: {ipaddr}";
        on-click = "nm-connection-editor";
      };

      bluetooth = {
        format = "󰂯";
        format-connected = "󰂱 {device_alias}";
        format-disabled = "󰂲";
        tooltip-format = "{status}";
        on-click = "blueman-manager";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons = {
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        on-click = "pavucontrol";
        on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      };

      tray = {
        spacing = 10;
      };

      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "󰂚";
          none = "󰂜";
          dnd-notification = "󰂛";
          dnd-none = "󰪑";
        };
        return-type = "json";
        exec = "makoctl list | jq -r '{\"text\": (.data[0] | length | tostring), \"alt\": (if .data[0] | length > 0 then \"notification\" else \"none\" end), \"class\": \"notification\"}'";
        on-click = "makoctl dismiss";
        on-click-right = "makoctl dismiss -a";
        interval = 1;
      };
    }];

    # ========================================================================
    # WAYBAR STYLING (CSS)
    # ========================================================================
    # Colors like @base, @text, @blue come from catppuccin module
    # which injects CSS variables matching the selected flavor
    style = ''
      * {
        font-family: "JetBrains Mono";
        font-size: 13px;
      }

      window#waybar {
        background: alpha(@base, 0.9);
        color: @text;
      }

      #workspaces button {
        padding: 0 8px;
        color: @overlay0;
        border-radius: 0;
      }

      #workspaces button.active {
        color: @blue;
      }

      #workspaces button:hover {
        background: alpha(@surface0, 0.8);
      }

      #clock, #battery, #network, #pulseaudio, #tray, #cpu, #memory, #bluetooth, #custom-notification {
        padding: 0 12px;
      }

      #battery.warning {
        color: @yellow;
      }

      #battery.critical {
        color: @red;
      }
    '';
  };
}
