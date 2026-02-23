# ============================================================================
# BASE PROFILE - Shared Across All Environments
# ============================================================================
#
# Core shell and CLI configuration that every machine gets:
#   - Fish shell with greeting disabled
#   - Starship prompt with Kubernetes context display
#   - Shell aliases (eza, git shortcuts) via aliases.nix
#   - Catppuccin theming for terminal tools
#   - Basic CLI tools (eza, fzf, jq, yq)
#
# This profile is independent - it does not import other profiles.
# Compose with desktop.nix and/or dev.nix as needed.
#
# ============================================================================

{ pkgs, user, ... }:

{
  imports = [
    ../modules/home/aliases.nix    # Shared shell aliases (eza, git shortcuts)
    ../modules/home/catppuccin.nix # Unified theming (tmux, fish, bat, yazi)
  ];

  # ==========================================================================
  # HOME MANAGER IDENTITY
  # ==========================================================================
  # Required: Tell Home Manager who you are and where your home is
  # The `user` variable comes from flake.nix via extraSpecialArgs
  home.username = user.name;
  home.homeDirectory = "/home/${user.name}";

  # ==========================================================================
  # BASE PACKAGES
  # ==========================================================================
  home.packages = with pkgs; [
    eza  # Modern ls with colors and icons
    fzf  # Fuzzy finder (Ctrl+R integration)
    jq   # JSON query/manipulation
    yq   # YAML query (like jq for YAML)
  ];

  # ==========================================================================
  # FISH SHELL
  # ==========================================================================
  # Fish: user-friendly shell with autocompletion, syntax highlighting
  # Note: Also enabled system-wide in users.nix (required for login shell)
  programs.fish = {
    enable = true;
    interactiveShellInit = "set fish_greeting";  # Disable "Welcome to fish" message
  };

  # ==========================================================================
  # STARSHIP PROMPT
  # ==========================================================================
  # Cross-shell prompt that shows: directory, git status, language versions
  programs.starship = {
    enable = true;
    enableFishIntegration = true;

    # Kubernetes context display - essential for safety with kubie
    settings = {
      kubernetes = {
        disabled = false;
        # Show context and namespace
        format = "[$symbol$context( \\($namespace\\))]($style) ";
        symbol = "󱃾 ";  # Kubernetes helm icon (nerd font)
        style = "cyan";

        # Color-code contexts for safety (prod = red, local = green)
        contexts = [
          { context_pattern = ".*prod.*"; style = "bold red"; }
          { context_pattern = ".*acc.*"; style = "bold yellow"; }
        ];

        # Only show when kubeconfig exists (kubie session active)
        detect_files = [ ];
        detect_folders = [ ];
        detect_env_vars = [ "KUBECONFIG" ];
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
  home.stateVersion = "24.11";
}
