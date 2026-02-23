# ============================================================================
# SERVER HOME MANAGER CONFIGURATION - Headless/CLI Environment
# ============================================================================
#
# STANDALONE HOME-MANAGER FOR NON-NIXOS SERVERS
# This configuration runs on any Linux with Nix installed (Ubuntu, Debian, etc.)
# It provides a consistent development environment across cloud servers.
#
# Composes from mixin profiles:
#   base.nix - fish, starship, aliases, catppuccin, basic CLI tools
#   dev.nix  - nvim, tmux, atuin, direnv, yazi, zoxide, ghq, claude-code, k8s, etc.
#
# USAGE:
#   # Install Nix on server, then:
#   nix run home-manager/master -- switch --flake .#edgar@server
#   # Or for ARM servers:
#   nix run home-manager/master -- switch --flake .#edgar@server-arm
#
# 1PASSWORD:
#   Set OP_SERVICE_ACCOUNT_TOKEN env var for op CLI access
#   Service account needs access to Pilosa vault
#
# ============================================================================

{ pkgs, user, ... }:

{
  imports = [
    ../profiles/base.nix
    ../profiles/dev.nix
  ];

  # ==========================================================================
  # SERVER PACKAGES
  # ==========================================================================
  # Essential CLI tools not available on non-NixOS servers
  # (On NixOS hosts these are in environment.systemPackages)
  home.packages = with pkgs; [
    _1password-cli   # Authenticate via OP_SERVICE_ACCOUNT_TOKEN env var
    htop             # Process monitor
    ripgrep          # Fast grep
    fd               # Fast find
  ];

  # ==========================================================================
  # GIT CONFIGURATION
  # ==========================================================================
  programs.git = {
    enable = true;
    settings = {
      user.name = user.fullName;
      user.email = user.git.email;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      # SSH signing (if you set up keys on server)
      gpg.format = "ssh";
      user.signingKey = "~/.ssh/id_ed25519.pub";
      commit.gpgSign = false;
    };
  };
}
