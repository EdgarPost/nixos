# ============================================================================
# OPENCODE - AI Coding Agent Configuration
# ============================================================================
#
# WHAT IS THIS?
# - Local models served by Bifrost proxy at edgar-framework-desktop:4000
# - OpenCode Zen (SST's managed gateway) wired up with 1Password-injected key
#
# MODELS:
#   Local:    qwen3.6-35b-a3b (non-thinking + reasoning variants)
#   Zen:      opencode/* (requires OPENCODE_ZEN_API_KEY in shell env)
#
# SETUP (Zen):
#   zen-login    # Reads op://Pilosa/OpenCodeZen/api_key into OPENCODE_ZEN_API_KEY
#   zen-logout   # Clears the env var
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
          "qwen36-35b-a3b/qwen3.6-35b-a3b" = { };
          "qwen36-35b-a3b-reasoning/qwen3.6-35b-a3b-reasoning" = { };
        };
      };
      opencode = {
        options.apiKey = "{env:OPENCODE_ZEN_API_KEY}";
      };
    };
    model = "local/qwen36-35b-a3b/qwen3.6-35b-a3b";
    small_model = "local/qwen36-35b-a3b/qwen3.6-35b-a3b";
  };

  programs.fish.interactiveShellInit = ''
    function zen-login --description "Load OpenCode Zen API key from 1Password"
        set -l op_item "op://Pilosa/OpenCodeZen/api_key"
        echo "Loading OpenCode Zen API key from 1Password..."

        set -gx OPENCODE_ZEN_API_KEY (op read "$op_item")
        or begin; echo "Failed to read API key from 1Password"; return 1; end

        echo "OpenCode Zen API key loaded"
    end

    function zen-logout --description "Clear OpenCode Zen API key from environment"
        set -e OPENCODE_ZEN_API_KEY
        echo "OpenCode Zen API key cleared"
    end
  '';
}
