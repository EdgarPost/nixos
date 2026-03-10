# ============================================================================
# SUNSHINE - Game Streaming Server
# ============================================================================
#
# Sunshine + Moonlight for streaming games to Steam Deck.
# Streams the headless Hyprland output (index 1) so the Dell monitor
# can be off without affecting FPS.
#
# Post-deployment:
#   1. Open https://localhost:47990 to set admin credentials
#   2. Check output index: journalctl --user -u sunshine | grep Monitor
#   3. Pair Moonlight on Steam Deck
#
# ============================================================================

{ pkgs, ... }:

let
  # Launch Steam Big Picture on the headless output for Moonlight streaming.
  # Restarts PipeWire first to work around Steam segfault bug:
  # https://github.com/ValveSoftware/steam-for-linux/issues/12211
  dellMonitor = "desc:Dell Inc. DELL U4025QW";

  # Disable Dell monitor, keep only headless for streaming
  gaming-mode-on = pkgs.writeShellScriptBin "gaming-mode-on" ''
    hyprctl keyword monitor "${dellMonitor},disable"
  '';

  # Re-enable Dell monitor after streaming ends
  gaming-mode-off = pkgs.writeShellScriptBin "gaming-mode-off" ''
    hyprctl keyword monitor "${dellMonitor},5120x2160@120,0x0,1.25"
  '';

  # Launch Steam Big Picture on the headless output for Moonlight streaming.
  # Restarts PipeWire first to work around Steam segfault bug:
  # https://github.com/ValveSoftware/steam-for-linux/issues/12211
  steam-bigpicture = pkgs.writeShellScriptBin "steam-bigpicture" ''
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
      output_name = 1; # Stream the headless output (index 1), not the Dell (index 0)
    };
    applications = {
      apps = [
        {
          name = "Steam Big Picture";
          cmd = "${steam-bigpicture}/bin/steam-bigpicture";
          auto-detach = "true";
          prep-cmd = [
            {
              do = "${gaming-mode-on}/bin/gaming-mode-on";
              undo = "${gaming-mode-off}/bin/gaming-mode-off";
            }
          ];
        }
      ];
    };
  };

  # Make steam-bigpicture available in PATH too (for manual use)
  environment.systemPackages = [ steam-bigpicture gaming-mode-on gaming-mode-off ];

  # Sunshine needs input group for virtual input devices (mouse/keyboard/gamepad)
  users.users.edgar.extraGroups = [ "input" ];
}
