{ ... }:

{
  # Claude Code configuration
  home.file.".claude/settings.json".text = builtins.toJSON {
    # Disable commit/PR attribution
    attribution = {
      commit = "";
      pr = "";
    };

    # Enable sandbox for security
    sandbox = {
      enabled = true;
      autoAllowBashIfSandboxed = true;  # Auto-allow bash when sandboxed
    };

    # Deny access to sensitive files
    permissions = {
      deny = [
        "Edit ~/.ssh/**"
        "Edit ~/.gnupg/**"
        "Edit ~/.aws/**"
        "Edit ~/.config/1Password/**"
        "Read ~/.ssh/id_*"
        "Read ~/.gnupg/**"
      ];
    };
  };
}
