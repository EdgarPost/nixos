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

let
  # ==========================================================================
  # GREENPT - Pilosa's EU-hosted, OpenAI-compatible AI API
  # ==========================================================================
  # One key covers chat, embeddings, reranking, OCR, speech, scraping and
  # search. Pi reaches it as a custom provider in models.json (GreenPT is not
  # a built-in provider), under provider name "greenpt".
  #
  # The key lives in 1Password (Pilosa vault, item "GreenPT", field api_key).
  # `apiKey` is a command Pi runs at request time, so the key never enters the
  # environment or a file on disk; `op` must be on PATH (it is, via github.nix,
  # from the dev profile).
  #
  # GreenPT publishes EUR per 1M tokens, Pi's cost fields are USD, so convert
  # with one constant. Bump it when the rate drifts materially.
  eurToUsd = 1.16;
  eur = n: builtins.floor (n * eurToUsd * 10000.0 + 0.5) / 10000.0;

  # Only the models worth a slot for a coding agent. contextWindow (1M) and
  # maxTokens (64k, the documented ceiling for this class) are verified against
  # the live endpoint. Costs: input, output, cached input per 1M tokens.
  greenptModel =
    {
      id,
      name,
      input ? [ "text" ],
      inputCost,
      outputCost,
      cacheReadCost,
    }:
    {
      inherit
        id
        name
        input
        ;
      reasoning = true;
      contextWindow = 1000000;
      maxTokens = 65536;
      cost = {
        input = eur inputCost;
        output = eur outputCost;
        cacheRead = eur cacheReadCost;
        cacheWrite = 0;
      };
    };
in
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
    hunk # Review-first terminal diff viewer (from nixpkgs)
    pi-coding-agent # AI coding agent (from nixpkgs)
  ];

  # ==========================================================================
  # PI CODING AGENT
  # ==========================================================================
  # Installed unwrapped so `pi update`, `pi list`, etc. work: subcommands
  # dispatch on argv[0], so a wrapper that prepends `--skill` would break them.
  # Pi auto-discovers skills under ~/.pi/agent/skills, so we symlink hunk's
  # bundled skills there instead of passing --skill flags (one path covers
  # hunk-review and hunk-extensions and tracks hunk upgrades automatically).
  home.file.".pi/agent/skills/hunk".source = "${pkgs.hunk}/share/skills/hunk";

  # Global communication style, appended to pi's built-in system prompt.
  # Lives in the repo so it survives reinstalls; keep editing it here, not in
  # ~/.pi/agent (that path is a store symlink).
  home.file.".pi/agent/APPEND_SYSTEM.md".source = ../modules/home/pi/APPEND_SYSTEM.md;

  # Pi model providers. Declarative so it survives reinstalls (the previous
  # imperative file is migrated here verbatim). Pi reads this file and reloads
  # it on /model; it never writes to it (/login writes auth.json, catalog
  # persistence goes to models-store.json), so a store symlink is safe.
  # Do not edit ~/.pi/agent/models.json directly — this path is a store link.
  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers = {
      # Local llama.cpp router on the desktop; the dummy key satisfies Pi.
      local-qwen36 = {
        baseUrl = "http://edgar-framework-desktop:8001/v1";
        api = "openai-completions";
        apiKey = "ollama";
        models = [ { id = "local/qwen3.6-35b-a3b"; } ];
      };

      greenpt = {
        # EU inference. Use https://api.us.greenpt.ai/v1 to serve from the US.
        baseUrl = "https://api.greenpt.ai/v1";
        api = "openai-completions";
        apiKey = "!op read 'op://Pilosa/GreenPT/api_key'";
        models = [
          (greenptModel {
            id = "glm-5.3-flash";
            name = "GLM-5.3 Flash";
            inputCost = 0.11;
            outputCost = 0.44;
            cacheReadCost = 0.022;
          })
          (greenptModel {
            id = "glm-5.3";
            name = "GLM-5.3";
            inputCost = 1.10;
            outputCost = 4.40;
            cacheReadCost = 0.275;
          })
          (greenptModel {
            id = "deepseek-v4.1-flash";
            name = "DeepSeek V4.1 Flash";
            input = [
              "text"
              "image"
            ];
            inputCost = 0.22;
            outputCost = 1.10;
            cacheReadCost = 0.011;
          })
        ];
      };
    };
  };

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
