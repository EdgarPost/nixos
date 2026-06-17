# ============================================================================
# AUDIO - WirePlumber + PipeWire Configuration
# ============================================================================
#
# PipeWire is the system audio server (configured in hosts/common/desktop.nix).
# This module tunes WirePlumber for our hardware:
#   - Duplex profiles (mic + output) on both built-in and USB audio
#   - Don't restore muted state on startup (prevents muted mic surprises)
#   - Default mic volume at 75% on built-in inputs
#   - Prefer Logitech C920 webcam over built-in cameras
#
# Device selection, volume, and the audio control panel all live in noctalia
# (panel-toggle control-center audio). The rofi-based audio-menu / audio-select
# / audio-output / audio-input scripts are gone.
#
# ============================================================================

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Audio control tools (GUI)
    pwvucontrol # Modern PipeWire volume control (better than pavucontrol)
    crosspipe   # Visual patchbay for complex audio routing
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

  # WirePlumber: Set built-in mic to unmuted at 75% volume by default
  xdg.configFile."wireplumber/wireplumber.conf.d/54-default-mic-volume.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          { node.name = "~alsa_input.pci-*" }
        ]
        actions = {
          update-props = {
            node.softvolume.mute = false
            node.softvolume.volume = 0.75
          }
        }
      }
    ]
  '';

  # WirePlumber: Prioritize Logitech C920 webcam over built-in camera
  # Higher priority = preferred default when multiple cameras available
  xdg.configFile."wireplumber/wireplumber.conf.d/53-prefer-c920-webcam.conf".text = ''
    monitor.libcamera.rules = [
      {
        matches = [
          { node.name = "~libcamera_device.*" }
        ]
        actions = {
          update-props = {
            node.priority.session = 1000
          }
        }
      }
    ]

    monitor.v4l2.rules = [
      {
        matches = [
          { node.name = "~v4l2_input.*C920*" }
        ]
        actions = {
          update-props = {
            node.priority.session = 2000
            node.description = "Logitech C920"
          }
        }
      }
      {
        matches = [
          { device.product.name = "HD Pro Webcam C920" }
        ]
        actions = {
          update-props = {
            device.priority.session = 2000
          }
        }
      }
    ]
  '';
}
