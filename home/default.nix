# ============================================================================
# HOME MANAGER CONFIGURATION - Edgar's Desktop Environment
# ============================================================================
#
# Composes from mixin profiles:
#   base.nix    - fish, starship, aliases, catppuccin, basic CLI tools
#   desktop.nix - hyprland, ghostty, waybar, swaync, audio, workspaces, font, cursor
#   dev.nix     - nvim, tmux, atuin, direnv, yazi, zoxide, ghq, claude-code, k8s, etc.
#
# Plus Edgar-specific config: git (1Password SSH agent, SSH URLs), SSH, roon-cli
#
# ============================================================================

{ inputs, user, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/desktop.nix
    ../profiles/dev.nix
    ../modules/home/roon-cli.nix        # Roon CLI for terminal music control
  ];

  # ==========================================================================
  # GIT CONFIGURATION
  # ==========================================================================
  # Home Manager's programs.git writes ~/.config/git/config
  # This is equivalent to running `git config --global` commands

  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings = {
      # User identity (for commit authorship)
      user.name = user.fullName;
      user.email = user.git.email;

      # Modern defaults
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;

      # Commit signing disabled (no local key files with 1Password SSH agent)
      # To enable: export public key from 1Password and configure signing
      commit.gpgSign = false;

      # Use SSH instead of HTTPS for common hosts
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gitlab.com:".insteadOf = "https://gitlab.com/";
      url."git@bitbucket.org:".insteadOf = "https://bitbucket.org/";
      url."git@ssh.dev.azure.com:v3/".insteadOf = "https://dev.azure.com/";
    };

    # Include private git config AFTER main settings (for per-directory overrides)
    includes = [ { path = "~/Code/gitconfig"; } ];
  };

  # ==========================================================================
  # SSH CONFIGURATION
  # ==========================================================================
  # 1Password acts as SSH agent - no ~/.ssh/id_* files needed
  # Keys unlocked with biometric/1Password master password

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        extraOptions = {
          IdentityAgent = "~/.1password/agent.sock";
        };
      };
      "pbstation" = {
        hostname = "pbstation";
        forwardAgent = true;
        setEnv = {
          TERM = "xterm-256color";  # Synology lacks tmux/ghostty terminfo
        };
      };
    };
  };
}
