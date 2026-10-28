# ============================================================================
# HYPRLAND SYSTEM MODULE - Wayland Compositor Infrastructure
# ============================================================================
#
# SYSTEM VS HOME MANAGER SPLIT:
# This module handles system-level Hyprland setup:
#   - Enable the compositor and PAM integration
#   - XDG portals (desktop integration)
#   - System-wide fonts
#   - Polkit (privilege escalation dialogs)
#
# User-level configuration (keybindings, appearance) is in:
#   modules/home/hyprland.nix
#
# ============================================================================

{ config, pkgs, ... }:

{
  # Enable Hyprland Wayland compositor
  # This installs Hyprland, sets up PAM for screen locking, and creates
  # the session file for display managers to offer Hyprland login
  programs.hyprland.enable = true;

  # ==========================================================================
  # XDG DESKTOP PORTALS
  # ==========================================================================
  # Portals are a freedesktop.org standard for sandboxed app ↔ desktop
  # communication. They enable:
  #   - File pickers (apps can open/save files without direct filesystem access)
  #   - Screen sharing (for video calls, OBS)
  #   - Notifications
  #   - Secret storage
  #
  # xdg-desktop-portal-gtk provides GTK-based file dialogs; Hyprland's
  # portal handles screen sharing. Both are needed for full functionality.
  xdg.portal = {
    enable = true;
    # Do NOT list pkgs.xdg-desktop-portal-hyprland here: since the 2026-10-27
    # nixpkgs bump, programs.hyprland adds its own `portalPackage` to this very
    # option, built against the hyprland the module actually runs. Listing the
    # plain package as well puts two different xdg-desktop-portal-hyprland
    # build outputs in xdg.portal.extraPortals, which become systemd.packages
    # and both ship share/systemd/user/xdg-desktop-portal-hyprland.service, so
    # the user-units builder fails with "ln: File exists".
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common.default = [
        "hyprland"
        "gtk"
      ];
      # Explicitly route screen sharing to Hyprland portal
      hyprland.default = [
        "hyprland"
        "gtk"
      ];
    };
  };

  # POLKIT - Privilege escalation UI
  # When apps need elevated privileges (e.g., mounting USB, changing network)
  # Polkit shows an auth dialog instead of requiring `sudo` in terminal
  security.polkit.enable = true;

  # ==========================================================================
  # WAYLAND ENVIRONMENT
  # ==========================================================================
  # Hint Electron apps (VS Code, Slack) to use native Wayland
  # instead of XWayland. Gives better scaling and input handling.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # ==========================================================================
  # FONTS
  # ==========================================================================
  # System-wide fonts available to all applications
  # Nerd Fonts: Regular fonts patched with programming icons/ligatures
  # Noto: Google's font family with wide Unicode coverage
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Primary coding font (includes powerline icons)
    nerd-fonts.fira-code # Alternative with ligatures
    noto-fonts # Sans/serif for documents
    noto-fonts-color-emoji # Emoji support (🎉)
  ];
}
