# ============================================================================
# FRAMEWORK LAPTOP HOME MODULE - Hardware-Specific Hyprland Config
# ============================================================================
#
# Monitor, input device, and lid switch configuration specific to this machine.
# Merged into the base Hyprland config via extraHomeModules in flake.nix.
#
# Find device names with: hyprctl devices
# Find monitor names with: hyprctl monitors
#
# ============================================================================

{ lib, ... }:

{

  wayland.windowManager.hyprland.settings = {
    # Monitor configuration
    monitor = [
      "desc:Dell Inc. DELL U4025QW,5120x2160@60,0x0,1.25" # Dell U4025QW ultrawide
      "eDP-1,preferred,auto,1" # Built-in laptop screen
    ];

    # Full-width columns on laptop screen
    scrolling = {
      column_width = lib.mkForce 1.0;
    };

    # Per-device input settings (Framework hardware)
    device = [
      {
        name = "pixa3854:00-093a:0274-touchpad"; # Framework 12th gen Pixart touchpad
        sensitivity = 0.3;
        accel_profile = "adaptive";
      }
      {
        name = "logitech-g502-1"; # Logitech G502
        sensitivity = -0.5;
        scroll_factor = 0.3;
        accel_profile = "flat";
      }
    ];

    # Lid switch: manage laptop display (suspend is handled by logind)
    bindl = [
      ", switch:on:Lid Switch, exec, hyprctl keyword monitor eDP-1,disable"
      ", switch:off:Lid Switch, exec, hyprctl keyword monitor eDP-1,preferred,auto,1"
    ];
  };
}
