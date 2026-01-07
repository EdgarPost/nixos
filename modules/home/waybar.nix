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

{ pkgs, font, ... }:

let
  waybar-cpu = pkgs.writers.writeBash "waybar-cpu" ''
    awk '{u=$2+$4; t=$2+$4+$5; if(NR==1){u1=u;t1=t} else {
      p=(u-u1)*100/(t-t1); lvl=int(p/10)*10
      printf "{\"text\":\" \",\"tooltip\":\"CPU: %.0f%%\",\"class\":\"level-%d\",\"percentage\":%.0f}\n", p, lvl, p
    }}' <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat)
  '';

  waybar-mem = pkgs.writers.writeBash "waybar-mem" ''
    awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{
      p=(t-a)*100/t; lvl=int(p/10)*10
      printf "{\"text\":\" \",\"tooltip\":\"Memory: %.0f%%\",\"class\":\"level-%d\",\"percentage\":%.0f}\n", p, lvl, p
    }' /proc/meminfo
  '';

  waybar-volume = pkgs.writers.writeBash "waybar-volume" ''
    vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
    muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED || true)
    lvl=$((vol/5*5))
    if [ "$lvl" -gt 100 ]; then lvl=100; fi
    if [ "$muted" = "1" ]; then
      echo "{\"text\":\" \",\"tooltip\":\"Volume: muted\",\"class\":\"muted\",\"percentage\":$vol}"
    else
      echo "{\"text\":\" \",\"tooltip\":\"Volume: $vol%\",\"class\":\"level-$lvl\",\"percentage\":$vol}"
    fi
  '';
in
{
  # GUI applications opened by clicking waybar modules
  home.packages = with pkgs; [
    pavucontrol          # Volume control (pulseaudio module click)
    blueman              # Bluetooth manager (bluetooth module click)
    networkmanagerapplet # Network settings (network module click)
  ];

  programs.waybar = {
    enable = true;
    systemd.enable = true;  # Managed by systemd - restarts after rebuild/crash
    systemd.target = "hyprland-session.target";  # Start with Hyprland

    # ========================================================================
    # WAYBAR CONFIGURATION (JSON)
    # ========================================================================
    # settings is a list because waybar can have multiple bars
    # We only use one bar here
    settings = [{
      layer = "top";
      position = "top";
      height = 30;
      margin-top = 15;
      margin-left = 15;
      margin-right = 15;
      margin-bottom = 0;

      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "custom/notification" "clock" ];
      modules-right = [ "custom/cpu" "custom/memory" "custom/volume" "bluetooth" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{id}";
        on-click = "activate";
        persistent-workspaces = {
          "*" = 5;  # Show workspaces 1-5 on all monitors
        };
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
        format = "{icon}";
        format-charging = "󰂄";
        format-plugged = "󰚥";
        tooltip-format = "{capacity}%";
        format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
      };

      "custom/cpu" = {
        exec = "${waybar-cpu}";
        return-type = "json";
        format = "{}";
        interval = 3;
      };

      "custom/memory" = {
        exec = "${waybar-mem}";
        return-type = "json";
        format = "{}";
        interval = 3;
      };

      "custom/volume" = {
        exec = "${waybar-volume}";
        return-type = "json";
        format = "{}";
        interval = 5;
        signal = 10;
        on-click = "pavucontrol";
        on-scroll-up = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ && pkill -RTMIN+10 waybar";
        on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && pkill -RTMIN+10 waybar";
      };

      network = {
        interface = "wl*";
        format-wifi = "󰖩";
        format-ethernet = "󰈀";
        format-disconnected = "󰖪";
        tooltip-format-wifi = "{essid} ({signalStrength}%)";
        tooltip-format-ethernet = "{ifname}: {ipaddr}";
        tooltip-format-disconnected = "Disconnected";
        on-click = "nm-connection-editor";
      };

      bluetooth = {
        format = "󰂯";
        format-connected = "󰂱 {device_alias}";
        format-disabled = "󰂲";
        tooltip-format = "{status}";
        on-click = "blueman-manager";
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
        font-family: "${font.family}";
        font-size: ${toString font.size}px;
      }

      window#waybar {
        background: transparent;
        color: @text;
      }

      /* Island styling for center and right sections */
      .modules-center,
      .modules-right {
        background: alpha(@base, 0.9);
        border-radius: 12px;
        margin: 0 15px;
        padding: 0 4px;
      }

      /* Left section is transparent - workspaces are individual islands */
      .modules-left {
        background: transparent;
      }

      /* Each workspace button is its own island */
      #workspaces button {
        background: alpha(@base, 0.9);
        padding: 0 12px;
        margin: 0 4px;
        border-radius: 12px;
        border: none;
        color: @text;
      }

      #workspaces button.empty {
        color: @overlay0;
      }

      #workspaces button.active {
        background: @green;
        color: @base;
      }

      #workspaces button:hover {
        background: alpha(@surface1, 0.9);
      }

      #workspaces button.active:hover {
        background: @green;
      }

      #clock, #battery, #network, #tray, #bluetooth, #custom-notification {
        padding: 0 12px;
      }

      /* Vertical bar styling for CPU, Memory, and Volume */
      #custom-cpu,
      #custom-memory,
      #custom-volume {
        min-width: 6px;
        margin: 6px 3px;
        border-radius: 2px;
        background: @surface0;
      }

      /* CPU/Memory: green -> yellow -> peach -> red */
      #custom-cpu.level-0, #custom-memory.level-0 { background: linear-gradient(to top, @green 0%, @surface0 0%); }
      #custom-cpu.level-10, #custom-memory.level-10 { background: linear-gradient(to top, @green 10%, @surface0 10%); }
      #custom-cpu.level-20, #custom-memory.level-20 { background: linear-gradient(to top, @green 20%, @surface0 20%); }
      #custom-cpu.level-30, #custom-memory.level-30 { background: linear-gradient(to top, @yellow 30%, @surface0 30%); }
      #custom-cpu.level-40, #custom-memory.level-40 { background: linear-gradient(to top, @yellow 40%, @surface0 40%); }
      #custom-cpu.level-50, #custom-memory.level-50 { background: linear-gradient(to top, @yellow 50%, @surface0 50%); }
      #custom-cpu.level-60, #custom-memory.level-60 { background: linear-gradient(to top, @peach 60%, @surface0 60%); }
      #custom-cpu.level-70, #custom-memory.level-70 { background: linear-gradient(to top, @peach 70%, @surface0 70%); }
      #custom-cpu.level-80, #custom-memory.level-80 { background: linear-gradient(to top, @red 80%, @surface0 80%); }
      #custom-cpu.level-90, #custom-memory.level-90 { background: linear-gradient(to top, @red 90%, @surface0 90%); }
      #custom-cpu.level-100, #custom-memory.level-100 { background: @red; }

      /* Volume: white/text color (5% steps) with animation */
      #custom-volume {
        transition: background 150ms ease-in-out;
      }
      #custom-volume.level-0 { background: linear-gradient(to top, @text 0%, @surface0 0%); }
      #custom-volume.level-5 { background: linear-gradient(to top, @text 5%, @surface0 5%); }
      #custom-volume.level-10 { background: linear-gradient(to top, @text 10%, @surface0 10%); }
      #custom-volume.level-15 { background: linear-gradient(to top, @text 15%, @surface0 15%); }
      #custom-volume.level-20 { background: linear-gradient(to top, @text 20%, @surface0 20%); }
      #custom-volume.level-25 { background: linear-gradient(to top, @text 25%, @surface0 25%); }
      #custom-volume.level-30 { background: linear-gradient(to top, @text 30%, @surface0 30%); }
      #custom-volume.level-35 { background: linear-gradient(to top, @text 35%, @surface0 35%); }
      #custom-volume.level-40 { background: linear-gradient(to top, @text 40%, @surface0 40%); }
      #custom-volume.level-45 { background: linear-gradient(to top, @text 45%, @surface0 45%); }
      #custom-volume.level-50 { background: linear-gradient(to top, @text 50%, @surface0 50%); }
      #custom-volume.level-55 { background: linear-gradient(to top, @text 55%, @surface0 55%); }
      #custom-volume.level-60 { background: linear-gradient(to top, @text 60%, @surface0 60%); }
      #custom-volume.level-65 { background: linear-gradient(to top, @text 65%, @surface0 65%); }
      #custom-volume.level-70 { background: linear-gradient(to top, @text 70%, @surface0 70%); }
      #custom-volume.level-75 { background: linear-gradient(to top, @text 75%, @surface0 75%); }
      #custom-volume.level-80 { background: linear-gradient(to top, @text 80%, @surface0 80%); }
      #custom-volume.level-85 { background: linear-gradient(to top, @text 85%, @surface0 85%); }
      #custom-volume.level-90 { background: linear-gradient(to top, @text 90%, @surface0 90%); }
      #custom-volume.level-95 { background: linear-gradient(to top, @text 95%, @surface0 95%); }
      #custom-volume.level-100 { background: @text; }
      #custom-volume.muted { background: @surface0; }

      #battery.warning {
        color: @yellow;
      }

      #battery.critical {
        color: @red;
      }
    '';
  };
}
