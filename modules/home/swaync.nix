# ============================================================================
# SWAYNC - Notification Center (Replaces Mako)
# ============================================================================
#
# SwayNotificationCenter provides:
# - Notification daemon
# - Notification center panel (toggle with Mod+N)
# - Do Not Disturb mode
# - Grouped notifications
#
# Commands:
#   swaync-client -t     Toggle notification center
#   swaync-client -d     Toggle DND
#   swaync-client -C     Close all notifications
#
# Test: notify-send "Title" "Body text"
#
# ============================================================================

{ config, pkgs, ... }:

{
  services.swaync = {
    enable = true;
    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;
      cssPriority = "application";
      control-center-margin-top = 15;
      control-center-margin-bottom = 15;
      control-center-margin-right = 15;
      notification-icon-size = 64;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      timeout = 5;
      timeout-low = 3;
      timeout-critical = 0;
      fit-to-screen = true;
      control-center-width = 400;
      notification-window-width = 400;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;
      widgets = [
        "inhibitors"
        "title"
        "dnd"
        "notifications"
      ];
      widget-config = {
        inhibitors = {
          text = "Inhibitors";
          button-text = "Clear";
          clear-all-button = true;
        };
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = {
          text = "Do Not Disturb";
        };
      };
    };
  };

  # Enable Catppuccin theme for SwayNC
  catppuccin.swaync.enable = true;

  # SwayNC client for manual control
  home.packages = with pkgs; [
    swaynotificationcenter
  ];
}
