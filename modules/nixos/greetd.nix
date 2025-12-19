# ============================================================================
# GREETD - Minimal Login Manager (Display Manager)
# ============================================================================
#
# WHAT IS A DISPLAY MANAGER?
# The program that shows the login screen. Traditional DMs: GDM, SDDM, LightDM
# greetd is minimal, Wayland-native, and pairs with various "greeters" (UIs)
#
# WHY GREETD?
#   - Lightweight (no heavy dependencies like GNOME/KDE)
#   - Wayland-native (no X11 baggage)
#   - Configurable via NixOS (not separate config files)
#   - tuigreet: Terminal-based UI (fast, simple, no mouse needed)
#
# ============================================================================

{ config, pkgs, user, ... }:

{
  services.greetd = {
    enable = true;
    settings = {
      # Default session: what to show on every boot
      default_session = {
        # tuigreet: TUI-based greeter with nice features
        # --time: Show current time on login screen
        # --remember: Remember last used session/username
        # --cmd: Command to run after successful login
        #
        # SYNTAX: ${pkgs.tuigreet}/bin/tuigreet
        # Nix interpolates the full store path, e.g.:
        # /nix/store/abc123-tuigreet-0.9.1/bin/tuigreet
        # This ensures the exact versioned binary is used
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";  # Run greeter as unprivileged user
      };

      # AUTO-LOGIN (optional)
      # Uncomment to skip login screen entirely (less secure)
      # initial_session runs once on first boot, then default_session
      # initial_session = {
      #   command = "Hyprland";
      #   user = user.name;
      # };
    };
  };
}
