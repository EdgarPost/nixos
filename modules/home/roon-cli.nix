# ============================================================================
# ROON CLI - Command-line interface for Roon music player
# ============================================================================
#
# WHAT IS THIS?
# A CLI tool to control Roon from your terminal. Provides two components:
#   - `roon`: CLI commands (play, pause, browse, etc.)
#   - `roon-daemon`: Background service maintaining Roon Core connection
#
# ARCHITECTURE:
# The daemon runs persistently, maintaining the Roon API connection.
# CLI commands communicate with the daemon via Unix socket, enabling
# instant command execution without reconnection overhead.
#
# USAGE:
#   roon play        # Control playback
#   roon pause       # Pause playback
#   roon outputs     # List available outputs
#
# The daemon starts automatically via systemd user service.
#
# SOURCE: github.com/EdgarPost/roon-cli (added as flake input)
#
# ============================================================================

{ ... }:

{
  # Enable roon-cli with systemd daemon
  # Module imported from flake input in flake.nix
  services.roon-cli.enable = true;
}
