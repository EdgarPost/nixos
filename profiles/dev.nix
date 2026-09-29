# ============================================================================
# DEV PROFILE - Development & Work Tools
# ============================================================================
#
# Development environment and work-specific tooling:
#   - Neovim, tmux, atuin (shell history), direnv, yazi (file manager)
#   - Zoxide (smart cd), ghq (repo manager), lazygit
#   - Kubernetes, OpenStack, Gardener (infrastructure)
#   - GitHub CLI (1Password integration)
#   - Fish: repo picker function, repo-sync aliases
#
# This profile is independent - it does not import other profiles.
#
# ============================================================================

{ pkgs, inputs, ... }:

{
  imports = [
    ../modules/home/nvim.nix # Text editor
    ../modules/home/tmux.nix # Terminal multiplexer
    ../modules/home/atuin.nix # Shell history sync
    ../modules/home/direnv.nix # Per-directory environments with nix-direnv
    ../modules/home/yazi.nix # File manager (TUI)
    ../modules/home/mcp.nix # MCP servers (obsidian-vault, etc.)
    ../modules/home/kubernetes.nix # k8s tools (kubie, kubectx)
    ../modules/home/openstack.nix # OpenStack CLI
    ../modules/home/azure.nix # Azure CLI + Azure DevOps extension
    ../modules/home/gardener.nix # Gardener cluster management
    ../modules/home/github.nix # GitHub CLI with 1Password
  ];

  # ==========================================================================
  # DEV PACKAGES
  # ==========================================================================
  home.packages = with pkgs; [
    lazygit # TUI for git operations
    ghq # Git repository manager (ghq get, ghq list)
    worktrunk # Git worktree manager for parallel AI agent workflows (from nixpkgs)
    herdr # AI agent multiplexer (from nixpkgs)
  ];

  # ghq repository manager config (lives here because ghq is a dev tool)
  programs.git.settings.ghq.root = "~/Code";

  # ==========================================================================
  # WORKTRUNK - Git worktree manager for parallel AI agent workflows
  # ==========================================================================
  # The worktrunk binary comes from nixpkgs (see home.packages above).
  # Upstream home-manager doesn't ship a programs.worktrunk module yet, so the
  # fish shell integration (equivalent of the flake's enableFishIntegration) is
  # wired in the fish section below.
  xdg.configFile."worktrunk/config.toml".text = ''
    [post-start]
    copy = "wt step copy-ignored"
  '';

  # ==========================================================================
  # HERDR - AI agent multiplexer
  # ==========================================================================
  # The herdr binary comes from nixpkgs (see home.packages above).
  # The worktrunk plugin itself is installed imperatively and lives outside
  # home-manager (plugin code + plugins.json under ~/.config/herdr):
  #   herdr plugin install devashish2203/herdr-worktrunk
  # Here we only declare its keybindings. Note this overrides herdr's built-in
  # prefix+shift+d (close workspace) and prefix+shift+r (reload config).
  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    # Override herdr's built-in "new worktree" key (prefix+shift+g) with
    # worktrunk's default-branch switch/create picker:
    [[keys.command]]
    key = "prefix+shift+g"
    type = "plugin_action"
    command = "worktrunk.open-with-remotes"
    description = "Worktree: switch / create from default branch"

    # Optional: bind current-branch creation separately.
    [[keys.command]]
    key = "prefix+shift+c"
    type = "plugin_action"
    command = "worktrunk.open-current"
    description = "Worktree: switch / create from current branch"

    [[keys.command]]
    key = "prefix+shift+d"
    type = "plugin_action"
    command = "worktrunk.remove"
    description = "Worktree: remove"
  '';

  # ==========================================================================
  # ENVSEC - Per-directory environment variable management
  # ==========================================================================
  programs.envsec = {
    enable = true;
    enableFishIntegration = true;
    storePath = "~/Code/envsec";
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

      # worktrunk shell integration (package from nixpkgs, see WORKTRUNK above)
      ${pkgs.worktrunk}/bin/wt config shell init fish | source
    '';

    # Shell aliases for dev workflows
    shellAliases = {
      # ghq bootstrap - clone all repos from config
      repo-sync = "grep -v '^#' ~/Code/repos.txt | grep -v '^$' | xargs -I {} ghq get {}";
    };
  };
}
