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

{ config, pkgs, lib, inputs, user, ... }:

{
  # Import modular configurations
  # Each module handles one aspect (terminal, editor, WM, etc.)
  imports = [
    ../modules/home/hyprland.nix    # Window manager + keybindings
    ../modules/home/ghostty.nix     # Terminal emulator
    ../modules/home/atuin.nix       # Shell history
    ../modules/home/tmux.nix        # Terminal multiplexer
    ../modules/home/catppuccin.nix  # Unified theming
    ../modules/home/waybar.nix      # Status bar
    ../modules/home/yazi.nix        # File manager
    ../modules/home/nvim.nix        # Text editor
    ../modules/home/claude-code.nix # AI coding assistant config
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

  home.packages = with pkgs; [
    # CLI tools
    eza           # Modern ls with colors and icons
    fzf           # Fuzzy finder (Ctrl+R integration)
    jq            # JSON query/manipulation
    yq            # YAML query (like jq for YAML)
    lazygit       # TUI for git operations

    # Development
    nodejs_22     # JavaScript runtime
    claude-code   # AI coding assistant

    # Browser from flake input
    # ${stdenv.hostPlatform.system} resolves to "x86_64-linux" or "aarch64-linux"
    # This pattern accesses architecture-specific packages from external flakes
    inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default

  # CONDITIONAL PACKAGES
  # `lib.optionals` returns the list only if condition is true, else []
  # List concatenation (++) merges the conditional packages into main list
  # This enables architecture-specific packages (some apps lack ARM builds)
  ] ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [
    slack  # Only available for x86_64 (no aarch64 build)
  ];

  # ==========================================================================
  # GIT CONFIGURATION
  # ==========================================================================
  # Home Manager's programs.git writes ~/.config/git/config
  # This is equivalent to running `git config --global` commands

  programs.git = {
    enable = true;  # Install git and manage its config
    settings = {
      # User identity (for commit authorship)
      user.name = user.fullName;
      user.email = user.email;

      # Modern defaults
      init.defaultBranch = "main";       # Not master
      push.autoSetupRemote = true;       # Auto-create upstream on first push
      pull.rebase = true;                # Rebase instead of merge on pull

      # SSH key signing (alternative to GPG)
      # Git can sign commits with your SSH key instead of GPG
      gpg.format = "ssh";
      user.signingKey = "~/.ssh/id_ed25519.pub";
      commit.gpgSign = false;  # Enable after SSH key is set up
    };
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
    '';

    # Shell aliases - shortcuts for common commands
    # Unlike bash, Fish aliases are just functions under the hood
    shellAliases = {
      ll = "eza -la";      # Detailed list with eza
      la = "eza -a";       # Show hidden files
      cat = "bat";         # cat with syntax highlighting
      n = "nvim";          # Quick editor access
      lg = "lazygit";      # Git TUI
      g = "git";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
    };
  };

  # ==========================================================================
  # STARSHIP PROMPT
  # ==========================================================================
  # Cross-shell prompt that shows: directory, git status, language versions
  # Configurable via ~/.config/starship.toml (or starship.settings here)

  programs.starship = {
    enable = true;
    enableFishIntegration = true;  # Add init to fish config automatically
  };

  # ==========================================================================
  # CURSOR THEME
  # ==========================================================================
  # Consistent cursor across all applications (X11, Wayland, GTK, Qt)

  home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor;  # macOS-style cursor for Linux
    size = 24;
    gtk.enable = true;  # Apply to GTK applications too
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
