# ============================================================================
# DEV PROFILE - Development & Work Tools
# ============================================================================
#
# Development environment and work-specific tooling:
#   - Neovim, tmux, atuin (shell history), direnv, yazi (file manager)
#   - Zoxide (smart cd), ghq (repo manager), lazygit
#   - Claude Code, OpenCode (AI coding assistants)
#   - Kubernetes, OpenStack, Gardener (infrastructure)
#   - GitHub CLI, Mistral API (1Password integration)
#   - Fish: repo picker function, repo-sync, claude aliases
#
# This profile is independent - it does not import other profiles.
#
# ============================================================================

{ pkgs, ... }:

{
  imports = [
    ../modules/home/nvim.nix # Text editor
    ../modules/home/tmux.nix # Terminal multiplexer
    ../modules/home/atuin.nix # Shell history sync
    ../modules/home/direnv.nix # Per-directory environments with nix-direnv
    ../modules/home/yazi.nix # File manager (TUI)
    ../modules/home/claude-code.nix # AI coding assistant config
    ../modules/home/kubernetes.nix # k8s tools (kubie, kubectx)
    ../modules/home/openstack.nix # OpenStack CLI
    ../modules/home/gardener.nix # Gardener cluster management
    ../modules/home/github.nix # GitHub CLI with 1Password
    ../modules/home/mistral.nix # Mistral API key + Vibe CLI with 1Password
    ../modules/home/opencode.nix # OpenCode config (LiteLLM provider)
  ];

  # ==========================================================================
  # DEV PACKAGES
  # ==========================================================================
  home.packages = with pkgs; [
    lazygit # TUI for git operations
    ghq # Git repository manager (ghq get, ghq list)
    claude-code # AI coding assistant
    opencode # AI coding agent
  ];

  # ghq repository manager config (lives here because ghq is a dev tool)
  programs.git.settings.ghq.root = "~/Code";

  # ==========================================================================
  # WORKTRUNK - Git worktree manager for parallel AI agent workflows
  # ==========================================================================
  programs.worktrunk = {
    enable = true;
    enableFishIntegration = true;
  };

  # ==========================================================================
  # ZOXIDE - Smart cd
  # ==========================================================================
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # ==========================================================================
  # FISH SHELL - Dev extensions
  # ==========================================================================
  # These settings merge with base.nix's fish config (NixOS merges lists/attrsets)
  programs.fish = {
    interactiveShellInit = ''
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

    # Shell aliases for dev workflows
    shellAliases = {
      # ghq bootstrap - clone all repos from config
      repo-sync = "grep -v '^#' ~/Code/repos.txt | grep -v '^$' | xargs -I {} ghq get {}";
      # claude code
      c = "claude";
      cc = "claude --continue";
    };
  };
}
