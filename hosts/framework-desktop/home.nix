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

{ lib, ... }:

{
  wayland.windowManager.hyprland.settings = {
    # Monitor configuration
    # Dell U4025QW ultrawide at 120Hz (connected via DP 2.1)
    monitor = [
      "desc:Dell Inc. DELL U4025QW,5120x2160@120,0x0,1.25"
    ];

    # XWayland renders at 1x by default, causing pixelation with fractional scaling.
    # force_zero_scaling disables compositor upscaling so XWayland apps see the real
    # resolution and handle scaling themselves (Steam via STEAM_FORCE_DESKTOPUI_SCALING).
    xwayland = {
      force_zero_scaling = true;
    };

    # Override shared cursor settings: the base config uses software cursors
    # as a workaround for Intel iGPU issues. The Radeon 8060S handles hardware
    # cursors fine, and they're much more responsive.
    cursor = {
      no_hardware_cursors = lib.mkForce false;
      use_cpu_buffer = lib.mkForce false;
    };

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
