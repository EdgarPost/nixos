# ============================================================================
# OPENCODE - AI Coding Agent Configuration
# ============================================================================
#
# WHAT IS THIS?
# - Configures OpenCode to use LiteLLM proxy as its AI provider
# - All models (local + cloud) accessed through single LiteLLM endpoint
# - Includes anthropic-login/logout shell functions for cloud API access
#
# MODELS:
#   Local:    qwen3.5-27b, qwen3.5-35b-a3b (thinking + no-think variants)
#   Cloud:    devstral, claude-opus, claude-sonnet, claude-haiku (need API keys)
#
# SETUP:
#   anthropic-login   # Load Anthropic key from 1Password → shell + LiteLLM
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
          baseURL = "http://localhost:4000/v1";
        };
        models = {
          "qwen3.5-27b" = {};
          "qwen3.5-35b-a3b" = {};
          devstral-medium = {};
          devstral-small = {};
          claude-opus = {};
          claude-sonnet = {};
          claude-haiku = {};
        };
      };
    };
    model = "local/devstral-medium";
    small_model = "local/devstral-small";
  };

  programs.fish.interactiveShellInit = ''
    function anthropic-login --description "Load Anthropic API key from 1Password into LiteLLM"
        set -l op_item "op://Pilosa/Anthropic/api_key"
        echo "Loading Anthropic API key from 1Password..."

        set -l key (op read "$op_item")
        or begin; echo "Failed to read API key from 1Password"; return 1; end

        set -gx ANTHROPIC_API_KEY $key

        # Add to LiteLLM env file (preserve other keys)
        sudo sed -i '/^ANTHROPIC_API_KEY=/d' /var/lib/litellm/env
        echo "ANTHROPIC_API_KEY=$key" | sudo tee -a /var/lib/litellm/env > /dev/null
        sudo systemctl restart litellm

        echo "Anthropic API key loaded (shell + LiteLLM)"
    end

    function anthropic-logout --description "Clear Anthropic API key"
        set -e ANTHROPIC_API_KEY
        sudo sed -i '/^ANTHROPIC_API_KEY=/d' /var/lib/litellm/env
        sudo systemctl restart litellm
        echo "Anthropic API key cleared"
    end
  '';
}
