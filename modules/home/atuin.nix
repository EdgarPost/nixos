# ============================================================================
# ATUIN - Shell History with Sync
# ============================================================================
#
# WHAT IS ATUIN?
# A replacement for shell history that provides:
#   - Full-text search across all history
#   - Sync between machines (encrypted, via atuin.sh or self-hosted)
#   - Context awareness (directory, exit code, duration)
#   - SQLite backend (fast, queryable)
#
# SETUP FOR SYNC:
#   1. Create account: atuin register -u <username> -e <email>
#   2. Login: atuin login
#   3. Import existing history: atuin import auto
#
# USAGE:
#   Ctrl+R  - Open history search
#   Type    - Fuzzy search across all commands
#   Enter   - Execute selected command
#
# ============================================================================

{ ... }:

{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;  # Integrate with Fish shell

    # Don't override up-arrow (use Ctrl+R instead)
    # Some people prefer up-arrow for atuin, but it can interfere with
    # normal shell behavior when you just want the last command
    flags = [ "--disable-up-arrow" ];

    settings = {
      auto_sync = true;           # Automatically sync history
      sync_frequency = "5m";      # Sync every 5 minutes
      search_mode = "fuzzy";      # Fuzzy matching (typo-tolerant)
      style = "compact";          # Compact UI (more history visible)
    };
  };
}
