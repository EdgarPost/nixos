# ============================================================================
# HANDY - Offline Speech-to-Text
# ============================================================================
#
# WHAT IS THIS?
# Handy provides system-wide offline voice dictation using Whisper/Parakeet.
# Press Super+V to toggle recording, text appears at cursor when done.
#
# USAGE:
#   Super+V       → toggle transcription (configured in hyprland.nix)
#   Super+Shift+V → clipboard history (unchanged)
#
# Handy starts hidden on login and lives in the system tray.
# Configure model and input method via the tray icon settings.
#
# SOURCE: github.com/cjpais/Handy (added as flake input)
#
# ============================================================================

{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.handy.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
