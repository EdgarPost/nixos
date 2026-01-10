# ============================================================================
# NIRI SYSTEM MODULE - Wayland Compositor Infrastructure
# ============================================================================
#
# SYSTEM VS HOME MANAGER SPLIT:
# This module handles system-level Niri setup:
#   - Enable the compositor (nixpkgs version)
#   - XDG portals (desktop integration)
#   - System-wide fonts
#   - Polkit (privilege escalation dialogs)
#   - PAM for swaylock
#
# User-level configuration (keybindings, appearance) is in:
#   modules/home/niri.nix (config.kdl file)
#
# ============================================================================

{ config, pkgs, ... }:

{
  # Enable Niri Wayland compositor from nixpkgs
  programs.niri.enable = true;

  # ==========================================================================
  # XDG DESKTOP PORTALS
  # ==========================================================================
  # Portals enable sandboxed app communication with the desktop
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome  # Screen sharing for Niri
      pkgs.xdg-desktop-portal-gtk    # GTK file dialogs
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  # PAM configuration for swaylock (screen locker)
  security.pam.services.swaylock = {};

  # POLKIT - Privilege escalation UI
  security.polkit.enable = true;

  # ==========================================================================
  # WAYLAND ENVIRONMENT
  # ==========================================================================
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # XWayland support for legacy X11 apps
  environment.systemPackages = with pkgs; [
    xwayland-satellite  # Rootless XWayland for Niri
  ];

  # ==========================================================================
  # FONTS
  # ==========================================================================
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];
}
