# ============================================================================
# AUDIO DEVICE SELECTION
# ============================================================================
#
# Select audio input/output combos from available devices.
#
# Commands:
#   audio-select        Select output+input combo (rofi menu)
#   audio-output        Select output only
#   audio-input         Select input only
#
# Keybinding:
#   Super+A             Open combo selector
#
# ============================================================================

{ pkgs, ... }:

let
  # Helper to get sinks
  getSinks = ''
    wpctl status | sed -n '/Audio/,/Video/p' | sed -n '/Sinks:/,/Sources:/p' | \
      grep -E '[0-9]+\.' | sed 's/.*│\s*//' | sed 's/\*\s*//' | sed 's/\s*\[vol:.*$//'
  '';

  # Helper to get sources
  getSources = ''
    wpctl status | sed -n '/Audio/,/Video/p' | sed -n '/Sources:/,/Filters:/p' | \
      grep -E '[0-9]+\.' | sed 's/.*│\s*//' | sed 's/\*\s*//' | sed 's/\s*\[vol:.*$//'
  '';

  # Combo selector - pick output then input
  audio-select = pkgs.writeShellScriptBin "audio-select" ''
    get_sinks() { ${getSinks} }
    get_sources() { ${getSources} }

    # Build combo menu: "Output → Input"
    build_combos() {
      sinks=$(get_sinks)
      sources=$(get_sources)

      while IFS= read -r sink; do
        sink_name=$(echo "$sink" | sed 's/^[0-9]*\.\s*//')
        while IFS= read -r source; do
          source_name=$(echo "$source" | sed 's/^[0-9]*\.\s*//')
          sink_id=$(echo "$sink" | grep -oP '^\d+')
          source_id=$(echo "$source" | grep -oP '^\d+')
          echo "$sink_id:$source_id:$sink_name → $source_name"
        done <<< "$sources"
      done <<< "$sinks"
    }

    combos=$(build_combos)
    if [ -z "$combos" ]; then
      ${pkgs.libnotify}/bin/notify-send "Audio" "No devices available"
      exit 1
    fi

    # Show menu with just the names
    choice=$(echo "$combos" | cut -d: -f3- | rofi -dmenu -p "Audio" -i)

    if [ -n "$choice" ]; then
      # Find matching combo and extract IDs
      line=$(echo "$combos" | grep -F "$choice" | head -1)
      sink_id=$(echo "$line" | cut -d: -f1)
      source_id=$(echo "$line" | cut -d: -f2)

      wpctl set-default "$sink_id"
      wpctl set-default "$source_id"

      ${pkgs.libnotify}/bin/notify-send -i audio-headphones "Audio" "$choice"
    fi
  '';

  # Output-only selector
  audio-output = pkgs.writeShellScriptBin "audio-output" ''
    get_sinks() { ${getSinks} }

    sinks=$(get_sinks)
    if [ -z "$sinks" ]; then
      ${pkgs.libnotify}/bin/notify-send "Audio" "No outputs available"
      exit 1
    fi

    choice=$(echo "$sinks" | rofi -dmenu -p "Output" -i)
    if [ -n "$choice" ]; then
      sink_id=$(echo "$choice" | grep -oP '^\d+')
      wpctl set-default "$sink_id"
      name=$(echo "$choice" | sed 's/^[0-9]*\.\s*//')
      ${pkgs.libnotify}/bin/notify-send -i audio-speakers "Output" "$name"
    fi
  '';

  # Input-only selector
  audio-input = pkgs.writeShellScriptBin "audio-input" ''
    get_sources() { ${getSources} }

    sources=$(get_sources)
    if [ -z "$sources" ]; then
      ${pkgs.libnotify}/bin/notify-send "Audio" "No inputs available"
      exit 1
    fi

    choice=$(echo "$sources" | rofi -dmenu -p "Input" -i)
    if [ -n "$choice" ]; then
      source_id=$(echo "$choice" | grep -oP '^\d+')
      wpctl set-default "$source_id"
      name=$(echo "$choice" | sed 's/^[0-9]*\.\s*//')
      ${pkgs.libnotify}/bin/notify-send -i audio-input-microphone "Input" "$name"
    fi
  '';

  # Keep old name for keybinding compatibility
  audio-menu = pkgs.writeShellScriptBin "audio-menu" ''
    exec ${audio-select}/bin/audio-select
  '';

in
{
  home.packages = with pkgs; [
    # Audio control tools
    pwvucontrol # Modern PipeWire volume control (better than pavucontrol)
    helvum      # Visual patchbay for complex audio routing

    # Device selection scripts
    audio-select
    audio-output
    audio-input
    audio-menu
  ];

  # WirePlumber: Set duplex profiles by default (enables mic input)
  xdg.configFile."wireplumber/wireplumber.conf.d/51-device-profiles.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          { device.name = "~alsa_card.pci-*" }
        ]
        actions = {
          update-props = {
            device.profile = "output:analog-stereo+input:analog-stereo"
          }
        }
      }
      {
        matches = [
          { device.name = "~alsa_card.usb-*" }
        ]
        actions = {
          update-props = {
            device.profile = "output:analog-stereo+input:mono-fallback"
          }
        }
      }
    ]
  '';

  # WirePlumber: Disable state restoration (prevents muted mic on startup)
  xdg.configFile."wireplumber/wireplumber.conf.d/52-no-restore-mute.conf".text = ''
    wireplumber.settings = {
      device.restore-profile = true
      device.restore-routes = true
      node.stream.restore-props = false
      node.stream.restore-target = true
    }
  '';
}
