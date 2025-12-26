# ============================================================================
# GITHUB CLI - gh with 1Password Integration
# ============================================================================
#
# WHAT IS GITHUB CLI?
# Official CLI for GitHub:
#   - Create/view/merge pull requests
#   - Create/view issues
#   - Clone repositories
#   - View workflow runs
#   - And more
#
# AUTHENTICATION WITH 1PASSWORD:
# Your GitHub Personal Access Token is stored in 1Password and injected at runtime.
#
# SETUP:
#   1. Create a Personal Access Token in GitHub:
#      Settings → Developer settings → Personal access tokens → Tokens (classic)
#      Or use fine-grained tokens for specific repo access
#
#   2. Create an item in 1Password (Pilosa vault) named "GitHub" with a field:
#      - token: ghp_xxxxxxxxxxxx (your personal access token)
#
#   3. Run: gh-login
#      This reads the token from 1Password and sets GH_TOKEN
#
# USAGE:
#   gh-login              # Authenticate (sets GH_TOKEN for current shell)
#   gh auth status        # Verify authentication
#   gh pr list            # List pull requests
#   gh pr create          # Create a pull request
#   gh issue list         # List issues
#
# ============================================================================

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gh               # GitHub CLI
    _1password-cli   # 1Password CLI (`op` command) for secure credential injection
  ];

  programs.fish = {
    interactiveShellInit = ''
      function gh-login --description "Load GitHub token from 1Password"
          # 1Password item reference
          # Format: op://Vault/Item/field
          set -l op_item "op://Pilosa/GitHub/token"

          echo "Loading GitHub token from 1Password..."

          set -gx GH_TOKEN (op read "$op_item")
          or begin; echo "Failed to read token from 1Password"; return 1; end

          echo "GitHub CLI authenticated"
          gh auth status
      end

      function gh-logout --description "Clear GitHub token from environment"
          set -e GH_TOKEN
          echo "GitHub token cleared"
      end
    '';
  };
}
