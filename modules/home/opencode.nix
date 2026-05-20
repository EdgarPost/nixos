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
# ROLE-BASED MODEL ROUTING:
#   Global default: kimi-k2.6 (Zen, strong fallback)
#   Plan agent:     kimi-k2.6 (Zen, for roadmap/architecture thinking)
#   Build agent:    local qwen3.6-35b-a3b (fast local for code execution)
#   Small model:    local qwen3.6-35b-a3b (title gen, lightweight tasks)
#
# SUBAGENT INHERITANCE (OpenCode native):
#   - Subagents spawned by plan → use kimi-k2.6
#   - Subagents spawned by build → use local qwen
#   - No explicit subagent overrides needed
#
# MCP SERVERS (user-level local processes, NOT in Bifrost sandbox):
#   - filesystem:  npx -y @modelcontextprotocol/server-filesystem ~/Code /tmp
#   - github:      npx -y @modelcontextprotocol/server-github (needs GITHUB_PERSONAL_ACCESS_TOKEN)
#   - bifrost:     Remote → http://edgar-framework-desktop:4000/mcp (Tavily web search)
#
# SETUP (Zen):
#   zen-login    # Reads op://Pilosa/OpenCodeZen/api_key into OPENCODE_ZEN_API_KEY
#   zen-logout   # Clears the env var
#
# SETUP (GitHub MCP):
#   github-mcp-login  # Reads op://Pilosa/GitHub/token into GITHUB_PERSONAL_ACCESS_TOKEN
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
        models = {
          "kimi-k2.6" = { };
        };
      };
    };
    model = "opencode/kimi-k2.6";
    small_model = "local/qwen36-35b-a3b/qwen3.6-35b-a3b";
    mcp = {
      filesystem = {
        type = "local";
        command = [ "npx" "-y" "@modelcontextprotocol/server-filesystem" "/home/edgar/Code" "/tmp" ];
        enabled = true;
      };
      github = {
        type = "local";
        command = [ "npx" "-y" "@modelcontextprotocol/server-github" ];
        enabled = true;
      };
      bifrost = {
        type = "remote";
        url = "http://edgar-framework-desktop:4000/mcp";
        enabled = true;
      };
    };
    agent = {
      plan = {
        model = "opencode/kimi-k2.6";
      };
      build = {
        model = "local/qwen36-35b-a3b-reasoning/qwen3.6-35b-a3b-reasoning";
      };
    };
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

    function github-mcp-login --description "Load GitHub token for MCP servers from 1Password"
        set -l op_item "op://Pilosa/GitHub/token"
        echo "Loading GitHub token from 1Password..."

        set -gx GITHUB_PERSONAL_ACCESS_TOKEN (op read "$op_item")
        or begin; echo "Failed to read GitHub token from 1Password"; return 1; end

        echo "GitHub MCP token loaded (GITHUB_PERSONAL_ACCESS_TOKEN)"
    end

    function github-mcp-logout --description "Clear GitHub MCP token from environment"
        set -e GITHUB_PERSONAL_ACCESS_TOKEN
        echo "GitHub MCP token cleared"
    end
  '';
}
