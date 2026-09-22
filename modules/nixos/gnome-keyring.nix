# ============================================================================
# GNOME KEYRING - Secret Service provider (org.freedesktop.secrets)
# ============================================================================
#
# WHAT IS THIS?
# A D-Bus Secret Service provider for the session bus. Applications that use
# the standard Secret Service API (org.freedesktop.secrets) to store secrets
# (tokens, passwords, encrypted data keys) talk to it.
#
# WHY WE NEED IT:
# Noctalia v5.x encrypts its persisted state (clipboard history, calendar
# account tokens) with a key obtained from the Secret Service. Without a
# provider on the session bus, Noctalia silently degrades:
#   - Clipboard history is kept in memory only -> lost on every
#     `nixos-rebuild switch` (restarts the noctalia service) and reboot.
#   - Calendar/Nextcloud accounts cannot store refresh tokens.
#
# HOW UNLOCKING WORKS:
#   - The "login" keyring is unlocked at login by the PAM module:
#     security.pam.services.greetd.enableGnomeKeyring = true (below).
#   - The daemon itself starts via D-Bus activation on first use.
#
# 1PASSWORD NOTE:
# 1Password is used for vault/SSH secrets but is NOT a Secret Service
# provider here, so it does not cover this need.
#
# ============================================================================

{ config, pkgs, ... }:

{
  services.gnome.gnome-keyring.enable = true;

  # Unlock the "login" keyring when the user authenticates at greetd
  # (tuigreet). Uses the login password, so keyring password == user password.
  security.pam.services.greetd.enableGnomeKeyring = true;

  # D-Bus activation needs the daemon on the session bus path
  environment.systemPackages = [ pkgs.gnome-keyring ];
}
