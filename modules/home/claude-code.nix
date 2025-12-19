# ============================================================================
# CLAUDE CODE - AI Coding Assistant Configuration
# ============================================================================
#
# WHAT IS CLAUDE CODE?
# Anthropic's AI coding assistant that runs in your terminal.
# This config manages its settings file declaratively via Nix.
#
# SECURITY CONSIDERATIONS:
# Claude Code can read files and execute commands. This config:
#   1. Enables sandboxing (restricted filesystem access)
#   2. Denies access to sensitive directories (SSH keys, etc.)
#   3. Auto-allows bash when sandboxed (safe because sandbox limits access)
#
# The settings are written to ~/.claude/settings.json
#
# ============================================================================

{ ... }:

{
  # DECLARATIVE CONFIG FILE
  # home.file."path".text creates a file in your home directory
  # builtins.toJSON converts a Nix attrset to JSON string
  # This pattern: Nix attrset → JSON file, is common for app configs
  home.file.".claude/settings.json".text = builtins.toJSON {

    # ==========================================================================
    # ATTRIBUTION
    # ==========================================================================
    # Disable automatic commit message and PR attribution
    # (Remove "Generated with Claude" footers)
    attribution = {
      commit = "";
      pr = "";
    };

    # ==========================================================================
    # SANDBOX MODE
    # ==========================================================================
    # Sandboxing restricts Claude's filesystem access for security
    sandbox = {
      enabled = true;
      # When sandboxed, auto-allow bash commands without prompting
      # Safe because sandbox already limits what bash can access
      autoAllowBashIfSandboxed = true;
    };

    # ==========================================================================
    # PERMISSIONS - Deny access to sensitive files
    # ==========================================================================
    # Even with sandbox, explicitly deny access to secrets
    # Format: "Action path/glob"
    # Actions: Read, Edit, Bash (execute)
    permissions = {
      deny = [
        "Edit ~/.ssh/**"              # SSH keys and config
        "Edit ~/.gnupg/**"            # GPG keys
        "Edit ~/.aws/**"              # AWS credentials
        "Edit ~/.config/1Password/**" # 1Password config
        "Read ~/.ssh/id_*"            # Private key contents
        "Read ~/.gnupg/**"            # GPG secret keys
      ];
    };
  };
}
