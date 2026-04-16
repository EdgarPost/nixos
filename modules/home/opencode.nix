# ============================================================================
# OPENCODE - AI Coding Agent Configuration
# ============================================================================
#
# WHAT IS THIS?
# - Configures OpenCode to use Bifrost proxy as its AI provider
# - All models (local + cloud) accessed through single Bifrost endpoint
# - Includes anthropic-login/logout shell functions for cloud API access
#
# MODELS:
#   Local:    qwen3.6-35b-a3b (thinking + no-think variants)
#   Cloud:    devstral, claude-opus, claude-sonnet, claude-haiku (need API keys)
#
# SETUP:
#   anthropic-login   # Load Anthropic key from 1Password → shell + Bifrost
#   anthropic-logout  # Clear Anthropic key
#
# ============================================================================

{ ... }:

{
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    provider = {
      local = {
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "http://edgar-framework-desktop:4000/v1";
        };
        models = {
          # Bifrost requires provider/model format
          "qwen36-35b-a3b/qwen3.6-35b-a3b" = {};
          "omnicoder-9b/omnicoder-9b" = {};
          "mistral/devstral-medium-latest" = {};
          "mistral/devstral-small-latest" = {};
          "anthropic/claude-opus-4-6" = {};
          "anthropic/claude-sonnet-4-6" = {};
          "anthropic/claude-haiku-4-5-20251001" = {};
        };
      };
    };
    model = "local/qwen36-35b-a3b/qwen3.6-35b-a3b";
    small_model = "local/omnicoder-9b/omnicoder-9b";
  };

  programs.fish.interactiveShellInit = ''
    function anthropic-login --description "Load Anthropic API key from 1Password into Bifrost"
        set -l op_item "op://Pilosa/Anthropic/api_key"
        echo "Loading Anthropic API key from 1Password..."

        set -l key (op read "$op_item")
        or begin; echo "Failed to read API key from 1Password"; return 1; end

        set -gx ANTHROPIC_API_KEY $key

        # Add to Bifrost env file (preserve other keys)
        sudo sed -i '/^ANTHROPIC_API_KEY=/d' /var/lib/bifrost/env
        echo "ANTHROPIC_API_KEY=$key" | sudo tee -a /var/lib/bifrost/env > /dev/null
        sudo systemctl restart bifrost

        echo "Anthropic API key loaded (shell + Bifrost)"
    end

    function anthropic-logout --description "Clear Anthropic API key"
        set -e ANTHROPIC_API_KEY
        sudo sed -i '/^ANTHROPIC_API_KEY=/d' /var/lib/bifrost/env
        sudo systemctl restart bifrost
        echo "Anthropic API key cleared"
    end
  '';
}
