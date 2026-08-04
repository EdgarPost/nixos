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
  wayland.windowManager.hyprland = {
    settings = {
      # Monitor configuration
      monitor = [
        {
          output = "desc:Dell Inc. DELL U4025QW";
          mode = "5120x2160@60";
          position = "0x0";
          scale = "1.25";
        } # Dell U4025QW ultrawide
        {
          output = "eDP-1";
          mode = "preferred";
          position = "auto";
          scale = "1";
        } # Built-in laptop screen
      ];

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

      # Override base config sections inside the shared hl.config() table.
      # This merges with the base config instead of generating invalid standalone
      # hl.scrolling calls.
      config = {
        # Full-width columns on laptop screen
        scrolling = {
          column_width = lib.mkForce 1.0;
        };
      };
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
    # bindl is hyprlang syntax; use raw hl.bind with locked=true for Lua.
    extraConfig = ''
      hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor eDP-1,disable"), { locked = true })
      hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl keyword monitor eDP-1,preferred,auto,1"), { locked = true })
    '';
  };
}
