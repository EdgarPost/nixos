# ============================================================================
# HOME MANAGER CONFIGURATION - User-Level Dotfiles and Programs
# ============================================================================
#
# WHAT IS HOME MANAGER?
# Home Manager manages your user environment declaratively:
#   - Dotfiles (~/.config/*, ~/.bashrc, etc.)
#   - User packages (not installed system-wide)
#   - Program configurations (git, vim, tmux, etc.)
#
# WHY SEPARATE FROM NIXOS?
#   1. No sudo needed to change your shell prompt
#   2. Per-user package isolation (different users, different tools)
#   3. Works on macOS and non-NixOS Linux too
#   4. Separation of concerns: system admin vs user preferences
#
# KEY CONCEPTS:
#   programs.<name>.enable = true;   # Install and configure a program
#   home.packages = [ ... ];         # Install packages without config
#   home.file."path".text = "...";   # Create arbitrary dotfiles
#   xdg.configFile."path".source = ...; # Create files in ~/.config/
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

let
  # Shared font configuration - used by terminal, waybar, etc.
  font = {
    family = "JetBrains Mono";
    size = 14;
  };
in
{
  # Make font available to all imported modules
  _module.args.font = font;

  # Import modular configurations
  # Each module handles one aspect (terminal, editor, WM, etc.)
  imports = [
    ../modules/home/aliases.nix # Shared shell aliases (eza, git shortcuts)
    ../modules/home/hyprland.nix # Window manager + keybindings
    ../modules/home/ghostty.nix # Terminal emulator
    ../modules/home/atuin.nix # Shell history
    ../modules/home/tmux.nix # Terminal multiplexer
    ../modules/home/catppuccin.nix # Unified theming
    ../modules/home/waybar.nix # Status bar
    ../modules/home/yazi.nix # File manager
    ../modules/home/nvim.nix # Text editor
    ../modules/home/claude-code.nix # AI coding assistant config
    ../modules/home/kubernetes.nix # k8s tools (kubie, kubectx)
    ../modules/home/openstack.nix # OpenStack CLI
    ../modules/home/gardener.nix # Gardener cluster management
    ../modules/home/mistral.nix # Mistral API key + Vibe CLI with 1Password
    ../modules/home/github.nix # GitHub CLI with 1Password
    # ../modules/home/calendar.nix # Calendar & contacts (vdirsyncer + khal + khard)
  ];

  # ==========================================================================
  # HOME MANAGER IDENTITY
  # ==========================================================================
  # Required: Tell Home Manager who you are and where your home is
  # The `user` variable comes from flake.nix via extraSpecialArgs
  home.username = user.name;
  home.homeDirectory = "/home/${user.name}";

  # ==========================================================================
  # USER PACKAGES
  # ==========================================================================
  # Packages installed to ~/.nix-profile (user-only, no sudo)
  # These differ from environment.systemPackages (system-wide, needs sudo)
  #
  # SYNTAX PATTERNS:
  #   `with pkgs;` - Brings all package names into scope
  #   `inputs.flake.packages.${system}.name` - Package from a flake input
  #   `lib.optionals condition [ list ]` - Conditional list items
  #   `stdenv.hostPlatform.system` - Current architecture string

  home.packages =
    with pkgs;
    [
      # CLI tools
      eza # Modern ls with colors and icons
      fzf # Fuzzy finder (Ctrl+R integration)
      jq # JSON query/manipulation
      yq # YAML query (like jq for YAML)
      lazygit # TUI for git operations
      impala # WiFi management TUI
      ghq # Git repository manager (ghq get, ghq list)

      # Development
      nodejs_22 # JavaScript runtime
      claude-code # AI coding assistant
      opencode # AI coding agent (Mistral, etc.)

      # Communication
      signal-desktop # Encrypted messaging

      # Browser from flake input
      # ${stdenv.hostPlatform.system} resolves to "x86_64-linux" or "aarch64-linux"
      # This pattern accesses architecture-specific packages from external flakes
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default

      # CONDITIONAL PACKAGES
      # `lib.optionals` returns the list only if condition is true, else []
      # List concatenation (++) merges the conditional packages into main list
      # This enables architecture-specific packages (some apps lack ARM builds)
    ]
    ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [
      slack # Only available for x86_64 (no aarch64 build)
    ];

  # ==========================================================================
  # GIT CONFIGURATION
  # ==========================================================================
  # Home Manager's programs.git writes ~/.config/git/config
  # This is equivalent to running `git config --global` commands

  programs.git = {
    enable = true; # Install git and manage its config
    settings = {
      # User identity (for commit authorship)
      user.name = user.fullName;
      user.email = user.git.email;

      # Modern defaults
      init.defaultBranch = "main"; # Not master
      push.autoSetupRemote = true; # Auto-create upstream on first push
      pull.rebase = true; # Rebase instead of merge on pull

      # ghq repository manager
      ghq.root = "~/Code";

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
  # FISH SHELL
  # ==========================================================================
  # Fish: user-friendly shell with autocompletion, syntax highlighting
  # Note: Also enabled system-wide in users.nix (required for login shell)

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting  # Disable "Welcome to fish" message

      # ghq + fzf: fuzzy cd to repo (sorted by most recently modified files)
      function repo
        set -l dir (ghq list -p | while read -l repo
          set -l ts (find $repo -type f -not -path '*/.git/*' -printf '%T@\n' 2>/dev/null | sort -rn | head -1)
          test -n "$ts"; or set ts 0
          echo "$ts $repo"
        end | sort -rn | cut -d' ' -f2- | fzf)
        and cd $dir
      end
    '';

    # Shell aliases - shortcuts for common commands
    # Unlike bash, Fish aliases are just functions under the hood
    # Common aliases (ll, git shortcuts) are in modules/home/aliases.nix
    # Module-specific aliases live in their modules (nvim.nix, catppuccin.nix, etc.)
    shellAliases = {
      # ghq bootstrap - clone all repos from config
      repo-sync = "grep -v '^#' ~/Code/repos.txt | grep -v '^$' | xargs -I {} ghq get {}";
      # claude code
      c = "claude";
      cc = "claude --continue";
    };
  };

  # ==========================================================================
  # STARSHIP PROMPT
  # ==========================================================================
  # Cross-shell prompt that shows: directory, git status, language versions
  # Configurable via ~/.config/starship.toml (or starship.settings here)

  programs.starship = {
    enable = true;
    enableFishIntegration = true; # Add init to fish config automatically

    # Kubernetes context display - essential for safety with kubie
    settings = {
      kubernetes = {
        disabled = false;
        # Show context and namespace
        format = "[$symbol$context( \\($namespace\\))]($style) ";
        symbol = "󱃾 "; # Kubernetes helm icon (nerd font)
        style = "cyan";

        # Color-code contexts for safety (prod = red, local = green)
        contexts = [
          {
            context_pattern = "k3s-local";
            style = "green";
            context_alias = "k3s";
          }
          {
            context_pattern = ".*prod.*";
            style = "bold red";
          }
          {
            context_pattern = ".*acc.*";
            style = "bold yellow";
          }
        ];

        # Only show when kubeconfig exists (kubie session active)
        detect_files = [ ];
        detect_folders = [ ];
        detect_env_vars = [ "KUBECONFIG" ];
      };
    };
  };

  # ==========================================================================
  # CURSOR THEME
  # ==========================================================================
  # Consistent cursor across all applications (X11, Wayland, GTK, Qt)

  home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor; # macOS-style cursor for Linux
    size = 24;
    gtk.enable = true; # Apply to GTK applications too
  };

  # ==========================================================================
  # SSH CONFIGURATION
  # ==========================================================================
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

  # ==========================================================================
  # HOME MANAGER SELF-MANAGEMENT
  # ==========================================================================
  # Allow Home Manager to manage itself (updates via flake, not channel)
  programs.home-manager.enable = true;

  # ==========================================================================
  # STATE VERSION
  # ==========================================================================
  # Like NixOS stateVersion, but for Home Manager's stateful defaults
  # Set this to your initial Home Manager version and rarely change it
  # Different from NixOS stateVersion - they track independently
  home.stateVersion = "24.11";
}
