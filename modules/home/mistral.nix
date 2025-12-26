# ============================================================================
# MISTRAL - API Key + Vibe CLI Integration with 1Password
# ============================================================================
#
# WHAT IS THIS?
# - Injects Mistral API key from 1Password for tools like OpenCode
# - Installs Mistral Vibe CLI (command-line coding assistant)
#
# SETUP:
#   1. Create an item in 1Password (Pilosa vault) named "Mistral" with a field:
#      - api_key: your Mistral API key
#
#   2. Run: vibe-install
#      This installs mistral-vibe using uv
#
#   3. Run: mistral-login
#      This reads the API key from 1Password and sets MISTRAL_API_KEY
#
# USAGE:
#   vibe-install          # Install/update mistral-vibe CLI
#   mistral-login         # Authenticate (sets MISTRAL_API_KEY for current shell)
#   mistral-logout        # Clear the API key from environment
#   vibe                  # Run Mistral Vibe CLI
#   opencode              # OpenCode will use MISTRAL_API_KEY automatically
#
# ============================================================================

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    _1password-cli   # 1Password CLI (`op` command) for secure credential injection
    uv               # Fast Python package installer (for mistral-vibe)
  ];

  programs.fish = {
    interactiveShellInit = ''
      # Add uv tools to PATH (for mistral-vibe)
      fish_add_path -g ~/.local/bin

      function vibe-install --description "Install/update Mistral Vibe CLI"
          echo "Installing mistral-vibe..."
          uv tool install mistral-vibe --upgrade
          and echo "Mistral Vibe installed. Run 'vibe' to start."
      end

      function mistral-login --description "Load Mistral API key from 1Password"
          # 1Password item reference
          # Format: op://Vault/Item/field
          set -l op_item "op://Pilosa/Mistral/api_key"

          echo "Loading Mistral API key from 1Password..."

          set -gx MISTRAL_API_KEY (op read "$op_item")
          or begin; echo "Failed to read API key from 1Password"; return 1; end

          echo "Mistral API key loaded"
      end

      function mistral-logout --description "Clear Mistral API key from environment"
          set -e MISTRAL_API_KEY
          echo "Mistral API key cleared"
      end
    '';
  };
}
