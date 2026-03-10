# ============================================================================
# SUNSHINE - Game Streaming Server
# ============================================================================
#
# Sunshine + Moonlight for streaming games to Steam Deck OLED.
#
# Dynamic virtual display management:
#   - Stream start: creates headless output at 2560x1440@90Hz, disables Dell
#   - Stream end: re-enables Dell, destroys headless output
#
# HDR-ready: HEVC Main10 and AV1 10-bit encoding advertised to Moonlight.
# Full HDR pipeline requires Hyprland HDR support on headless outputs (future).
#
# Post-deployment:
#   1. Open https://localhost:47990 to set admin credentials
#   2. Pair Moonlight on Steam Deck
#   3. Test with "Desktop" app first, then "Steam Big Picture"
#
# ============================================================================

{ pkgs, ... }:

let
  dellMonitor = "desc:Dell Inc. DELL U4025QW";

  # Create headless output and disable Dell for streaming
  sunshine-stream-on = pkgs.writeShellScriptBin "sunshine-stream-on" ''
    set -euo pipefail

    # Pre-set monitor rules for likely headless names BEFORE creating the output.
    # Hyprland applies matching rules automatically when outputs appear.
    # Setting the rule after creation results in a garbage default mode (0.06Hz).
    for i in 1 2 3; do
      hyprctl keyword monitor "HEADLESS-$i,2560x1440@90,auto,1,bitdepth,10"
    done

    # Create a headless output (virtual monitor for streaming)
    hyprctl output create headless

    # Wait for the headless output to register
    HEADLESS=""
    for i in $(seq 1 10); do
      HEADLESS=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name' | head -1)
      [ -n "$HEADLESS" ] && break
      sleep 0.5
    done

    if [ -z "$HEADLESS" ]; then
      echo "ERROR: Headless output not found after 5s"
      exit 1
    fi

    # Save headless name for cleanup (handles HEADLESS-1, HEADLESS-2, etc.)
    echo "$HEADLESS" > /tmp/sunshine-headless-name
    echo "Headless output ready: $HEADLESS at 2560x1440@90Hz"

    # Disable Dell monitor — headless becomes the sole active display
    hyprctl keyword monitor "${dellMonitor},disable" || true

    # Focus the gaming workspace on the headless monitor
    hyprctl dispatch focusmonitor "$HEADLESS"
    hyprctl dispatch workspace name:gaming
  '';

  # Re-enable Dell and destroy headless output after streaming ends
  sunshine-stream-off = pkgs.writeShellScriptBin "sunshine-stream-off" ''
    set -euo pipefail

    # Re-enable Dell monitor
    hyprctl keyword monitor "${dellMonitor},5120x2160@120,0x0,1.25"

    # Wait for Dell to come up
    sleep 1

    # Destroy the headless output and remove pre-set monitor rules
    if [ -f /tmp/sunshine-headless-name ]; then
      HEADLESS=$(cat /tmp/sunshine-headless-name)
      hyprctl output remove "$HEADLESS"
      rm -f /tmp/sunshine-headless-name
    fi

    # Clean up pre-set headless monitor rules
    for i in 1 2 3; do
      hyprctl keyword monitor "HEADLESS-$i,disabled" 2>/dev/null || true
    done
  '';

  # Launch Steam Big Picture on the headless output for Moonlight streaming.
  # Restarts PipeWire first to work around Steam segfault bug:
  # https://github.com/ValveSoftware/steam-for-linux/issues/12211
  steam-bigpicture = pkgs.writeShellScriptBin "steam-bigpicture" ''
    set -euo pipefail

    # Restart PipeWire to prevent Steam segfault
    systemctl --user restart pipewire.service pipewire-pulse.service

    # Wait for PipeWire to stabilize
    sleep 2

    # Find the headless monitor name
    HEADLESS=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name | startswith("HEADLESS-")) | .name' | head -1)

    if [ -n "$HEADLESS" ]; then
      # Focus the headless monitor and gaming workspace
      hyprctl dispatch focusmonitor "$HEADLESS"
      hyprctl dispatch workspace name:gaming
    fi

    # Ensure EAC-critical env var is set (sessionVariables may not reach Sunshine children)
    export WINE_CPU_TOPOLOGY="16:0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15"

    # Launch Steam Big Picture
    steam steam://open/bigpicture
  '';
in
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # Required for Wayland capture (wlr-export-dmabuf)
    openFirewall = true;
    settings = {
      # No output_name — when Dell is disabled, Sunshine captures the sole active display
    };
    applications = {
      apps = [
        {
          name = "Desktop";
          auto-detach = "true";
          prep-cmd = [
            {
              do = "${sunshine-stream-on}/bin/sunshine-stream-on";
              undo = "${sunshine-stream-off}/bin/sunshine-stream-off";
            }
          ];
        }
        {
          name = "Steam Big Picture";
          cmd = "${steam-bigpicture}/bin/steam-bigpicture";
          auto-detach = "true";
          prep-cmd = [
            {
              do = "${sunshine-stream-on}/bin/sunshine-stream-on";
              undo = "${sunshine-stream-off}/bin/sunshine-stream-off";
            }
          ];
        }
      ];
    };
  };

  # Make scripts available in PATH (for manual use / emergency cleanup)
  environment.systemPackages = [
    steam-bigpicture
    sunshine-stream-on
    sunshine-stream-off
  ];

  # Sunshine needs input group for virtual input devices (mouse/keyboard/gamepad)
  users.users.edgar.extraGroups = [ "input" ];
}
