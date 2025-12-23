# ============================================================================
# SERVER HOME MANAGER CONFIGURATION - Headless/CLI Environment
# ============================================================================
#
# STANDALONE HOME-MANAGER FOR NON-NIXOS SERVERS
# This configuration runs on any Linux with Nix installed (Ubuntu, Debian, etc.)
# It provides a consistent development environment across cloud servers.
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

{
  config,
  pkgs,
  lib,
  inputs,
  user,
  ...
}:

{
  # Import CLI-only modules (no desktop/GUI modules)
  imports = [
    ../modules/home/aliases.nix # Shared shell aliases (eza, git shortcuts)
    ../modules/home/atuin.nix # Shell history sync
    ../modules/home/catppuccin.nix # Theming for tmux/fish/bat/yazi
    ../modules/home/claude-code.nix # AI coding assistant config
    ../modules/home/gardener.nix # Gardener cluster management (uses op://Pilosa)
    ../modules/home/kubernetes.nix # k8s tools (kubie, kubectx)
    ../modules/home/nvim.nix # Text editor
    ../modules/home/openstack.nix # OpenStack CLI (uses op://Pilosa)
    ../modules/home/tmux.nix # Terminal multiplexer
    ../modules/home/yazi.nix # File manager (TUI)
  ];

  # ==========================================================================
  # HOME MANAGER IDENTITY
  # ==========================================================================
  home.username = user.name;
  home.homeDirectory = "/home/${user.name}";

  # ==========================================================================
  # SERVER PACKAGES
  # ==========================================================================
  # Essential CLI tools for development servers
  home.packages = with pkgs; [
    # 1Password CLI (authenticate via OP_SERVICE_ACCOUNT_TOKEN env var)
    _1password-cli

    # Core CLI tools
    eza # Modern ls with colors
    fzf # Fuzzy finder
    jq # JSON query/manipulation
    yq # YAML query
    lazygit # TUI for git
    htop # Process monitor
    ripgrep # Fast grep
    fd # Fast find

    # Development
    nodejs_22 # JavaScript runtime
    claude-code # AI coding assistant
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

  # ==========================================================================
  # FISH SHELL
  # ==========================================================================
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting  # Disable welcome message
    '';

    # Common aliases (ll, git shortcuts) are in modules/home/aliases.nix
  };

  # ==========================================================================
  # STARSHIP PROMPT
  # ==========================================================================
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      kubernetes = {
        disabled = false;
        format = "[$symbol$context( \\($namespace\\))]($style) ";
        symbol = "󱃾 ";
        style = "cyan";

        contexts = [
          { context_pattern = "k3s-local"; style = "green"; context_alias = "k3s"; }
          { context_pattern = ".*prod.*"; style = "bold red"; }
          { context_pattern = ".*acc.*"; style = "bold yellow"; }
        ];

        detect_files = [ ];
        detect_folders = [ ];
        detect_env_vars = [ "KUBECONFIG" ];
      };
    };
  };

  # ==========================================================================
  # HOME MANAGER SELF-MANAGEMENT
  # ==========================================================================
  programs.home-manager.enable = true;

  # ==========================================================================
  # STATE VERSION
  # ==========================================================================
  home.stateVersion = "24.11";
}
