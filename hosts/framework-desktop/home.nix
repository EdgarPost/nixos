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
  # Desktop: DPMS timeout turns Dell off, creates headless output for Steam Remote Play.
  # When Dell resumes, headless is destroyed — Steam Deck streams only while Dell sleeps.
  services.hypridle.settings.listener = lib.mkForce [
    {
      timeout = 300; # 5 min → Dell off, headless on for Steam Remote Play
      on-timeout = ''
        hyprctl dispatch dpms off DP-4
        hyprctl output create headless
        hyprctl keyword monitor "HEADLESS-1,2560x1440@90,auto,1"
      '';
      on-resume = ''
        hyprctl dispatch dpms on DP-4
        hyprctl output remove HEADLESS-1
      '';
    }
  ];

  wayland.windowManager.hyprland.settings = {
    # Monitor configuration
    # Dell U4025QW ultrawide at 120Hz (connected via DP 2.1)
    # HEADLESS-1: virtual monitor for Steam Remote Play when Dell is asleep
    monitor = [
      "desc:Dell Inc. DELL U4025QW,5120x2160@120,0x0,1.25"
      "HEADLESS-1,2560x1440@90,auto,1"
    ];

    # Pin gaming workspace to headless output for Steam Remote Play streaming.
    # Inert when no headless exists, auto-activates when hypridle creates one.
    workspace = [
      "name:gaming, monitor:HEADLESS-1, default:true"
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
