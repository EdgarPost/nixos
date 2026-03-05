# ============================================================================
# FRAMEWORK DESKTOP HOME MODULE - Hardware-Specific Hyprland Config
# ============================================================================
#
# Monitor and input device configuration specific to this machine.
# Merged into the base Hyprland config via extraHomeModules in flake.nix.
#
# Find device names with: hyprctl devices
# Find monitor names with: hyprctl monitors
#
# ============================================================================

{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    # Monitor configuration
    # Dell U4025QW ultrawide at 120Hz (connected via DP 2.1)
    monitor = [
      "desc:Dell Inc. DELL U4025QW,5120x2160@120,0x0,1.25"
    ];

    # Per-device input settings
    device = [
      {
        name = "logitech-g502-1"; # Logitech G502
        sensitivity = -0.5;
        scroll_factor = 0.3;
        accel_profile = "flat";
      }
    ];
  };
}
