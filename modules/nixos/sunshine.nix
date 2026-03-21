# ============================================================================
# SUNSHINE - Game Streaming Server
# ============================================================================
#
# Sunshine + Moonlight for streaming games to Steam Deck OLED.
#
# Virtual display management:
#   - Stream start: creates "sunshine" headless output at 1920x1080@90Hz,
#     disables Dell so Sunshine captures only the headless display
#   - Stream end: re-enables Dell, destroys headless output
#
# HDR-ready: HEVC Main10 and AV1 10-bit encoding advertised to Moonlight.
# Full HDR pipeline requires Hyprland HDR support on headless outputs (future).
#
# Post-deployment:
#   1. Open https://localhost:47990 to set admin credentials
#   2. Pair Moonlight on Steam Deck
#   3. Test streaming with Steam Big Picture
#
# ============================================================================

{ pkgs, ... }:

let
  headlessName = "sunshine";
  dellMonitor = "desc:Dell Inc. DELL U4025QW";

  # Create headless output and disable Dell for streaming
  sunshine-stream-on = pkgs.writeShellScriptBin "sunshine-stream-on" ''
    set -euo pipefail

    # Save Dell DPMS state so stream-off can restore it
    hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name == "DP-4") | .dpmsStatus' > /tmp/sunshine-dell-dpms

    # Remove stale output if it exists from a previous session
    hyprctl output remove "${headlessName}" 2>/dev/null || true

    # Pre-set monitor rule BEFORE creating the output.
    # Hyprland applies matching rules automatically when outputs appear.
    # Setting the rule after creation results in a garbage default mode (0.06Hz).
    hyprctl keyword monitor "${headlessName},1920x1080@90,auto,1,bitdepth,10"

    # Create a named headless output (predictable name, no incrementing counter)
    hyprctl output create headless "${headlessName}"

    # Wait for the output to register
    for i in $(seq 1 10); do
      FOUND=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.name == "${headlessName}") | .name')
      [ -n "$FOUND" ] && break
      sleep 0.5
    done

    if [ -z "''${FOUND:-}" ]; then
      echo "ERROR: ${headlessName} output not found after 5s"
      exit 1
    fi

    echo "Headless output ready: ${headlessName} at 1920x1080@90Hz"

    # Disable Dell monitor — headless becomes the sole active display for Sunshine
    hyprctl keyword monitor "${dellMonitor},disable" || true

    # Focus the gaming workspace on the headless monitor
    hyprctl dispatch focusmonitor "${headlessName}"
    hyprctl dispatch workspace name:gaming
  '';

  # Re-enable Dell and destroy headless output after streaming ends.
  # No set -e: every step must attempt even if earlier ones fail.
  sunshine-stream-off = pkgs.writeShellScriptBin "sunshine-stream-off" ''
    echo "sunshine-stream-off: starting cleanup" >> /tmp/sunshine-stream.log

    # Re-enable Dell monitor
    hyprctl keyword monitor "${dellMonitor},5120x2160@120,0x0,1.25" \
      && echo "sunshine-stream-off: Dell re-enabled" >> /tmp/sunshine-stream.log \
      || echo "sunshine-stream-off: FAILED to re-enable Dell" >> /tmp/sunshine-stream.log

    sleep 1

    # Restore Dell DPMS state from before streaming
    DPMS_WAS=$(cat /tmp/sunshine-dell-dpms 2>/dev/null || echo "true")
    if [ "$DPMS_WAS" = "false" ]; then
      sleep 1
      hyprctl dispatch dpms off DP-4 2>/dev/null || true
      echo "sunshine-stream-off: Dell restored to DPMS off (Away)" >> /tmp/sunshine-stream.log
    else
      hyprctl dispatch dpms on DP-4 2>/dev/null || true
      echo "sunshine-stream-off: Dell restored to DPMS on" >> /tmp/sunshine-stream.log
    fi
    rm -f /tmp/sunshine-dell-dpms

    # Destroy the headless output
    hyprctl output remove "${headlessName}" 2>/dev/null \
      && echo "sunshine-stream-off: removed ${headlessName}" >> /tmp/sunshine-stream.log \
      || echo "sunshine-stream-off: ${headlessName} not found" >> /tmp/sunshine-stream.log

    # Clean up monitor rule
    hyprctl keyword monitor "${headlessName},disabled" 2>/dev/null || true

    echo "sunshine-stream-off: cleanup complete" >> /tmp/sunshine-stream.log
  '';

  # Launch Steam Big Picture on the headless output for Moonlight streaming.
  # This script handles the full lifecycle: setup → launch → watch for disconnect → cleanup.
  # We can't rely on prep-cmd undo because Sunshine keeps the session alive after
  # Moonlight closes (waiting for reconnect), so undo never fires.
  steam-bigpicture = pkgs.writeShellScriptBin "steam-bigpicture" ''
    LOG=/tmp/sunshine-stream.log
    exec >> "$LOG" 2>&1

    echo "steam-bigpicture: starting at $(date)"

    # ── Setup (same as stream-on) ──
    ${sunshine-stream-on}/bin/sunshine-stream-on
    echo "steam-bigpicture: stream-on complete"

    # ── Launch Steam ──
    pkill -x steam 2>/dev/null || true
    sleep 2

    hyprctl dispatch focusmonitor "${headlessName}"
    hyprctl dispatch workspace name:gaming
    export WINE_CPU_TOPOLOGY="16:0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15"

    echo "steam-bigpicture: launching steam -gamepadui"
    steam -gamepadui >> /tmp/sunshine-steam.log 2>&1 &

    # ── Watch for Moonlight disconnect ──
    # Wait for CLIENT DISCONNECTED in the Sunshine journal, then clean up.
    # grep -m1 exits after the first match, cleanly terminating journalctl.
    echo "steam-bigpicture: watching for client disconnect"
    journalctl --user -u sunshine -f --since "now" --no-pager | grep -m1 "CLIENT DISCONNECTED" >/dev/null
    echo "steam-bigpicture: detected client disconnect"

    # ── Cleanup ──
    echo "steam-bigpicture: running stream-off"
    ${sunshine-stream-off}/bin/sunshine-stream-off
    echo "steam-bigpicture: done at $(date)"
  '';
in
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = false; # Not needed for wlr capture; breaks Steam's bwrap sandbox
    openFirewall = true;
    settings = {
      capture = "wlr"; # Use wlr-screencopy protocol — required for headless outputs (KMS can't see them)
    };
    applications = {
      apps = [
        {
          name = "Steam Big Picture";
          cmd = "${steam-bigpicture}/bin/steam-bigpicture";
          auto-detach = "true";
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
