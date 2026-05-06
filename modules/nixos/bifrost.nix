# ============================================================================
# BIFROST - Unified AI Gateway Proxy
# ============================================================================
#
# WHAT IS THIS?
# - Bifrost proxy that sits in front of local llama.cpp models and cloud APIs
# - Provides a single OpenAI-compatible endpoint on port 4000
# - Written in Go (compiled binary, no Python/PyPI supply chain risk)
# - Local models (Qwen) work immediately, cloud models need API keys
#
# ARCHITECTURE:
#                        ┌── llama.cpp :8001  (Qwen3.6-35B-A3B)
#   Bifrost (:4000) ─────└── llama.cpp :8011  (Qwen3.6-35B-A3B, reasoning)
#
# CLOUD API KEYS:
#   API keys are loaded from /var/lib/bifrost/env (not in Nix store).
#   Secrets managed via: bifrost-secrets-update (reads from 1Password)
#
# MCP GATEWAY:
#   Bifrost acts as a central MCP gateway — but ONLY for HTTP/SSE MCP servers.
#   Stdio MCP servers (filesystem, github) CANNOT run inside Bifrost's systemd
#   sandbox (DynamicUser + ProtectHome + no network for npx). They run as
#   user-level local MCPs in LibreChat and OpenCode instead.
#
# MCP CLIENTS IN BIFROST:
#   tavily — HTTP: Tavily hosted MCP (needs TAVILY_MCP_URL)
#
# MCP CLIENTS IN LIBRECHAT/OPENCODE (user-level, no sandbox):
#   filesystem — stdio: @modelcontextprotocol/server-filesystem ~/Code /tmp
#   github     — stdio: @modelcontextprotocol/server-github (needs GH_TOKEN)
#
# SECRETS (1Password → /var/lib/bifrost/env):
#   TAVILY_MCP_URL = https://mcp.tavily.com/mcp/?tavilyApiKey=tvly-...
#
# CACHING:
#   Bifrost semantic cache: NOT enabled (requires vector store like Weaviate)
#   llama.cpp KV-cache:   ENABLED (see modules/nixos/llama.nix)
#   LibreChat cache:      ENABLED (cache = true in librechat.nix)
#
# ============================================================================

{ inputs, ... }:

{
  imports = [ inputs.bifrost.nixosModules.bifrost ];

  services.bifrost = {
    enable = true;
    port = 4000;
    host = "0.0.0.0";
    environmentFile = "/var/lib/bifrost/env";

    settings = {
      providers = {
        # Local llama.cpp — non-thinking (instruct mode)
        qwen36-35b-a3b = {
          keys = [
            {
              name = "local";
              value = "none";
              models = [ ];
              weight = 1.0;
            }
          ];
          network_config = {
            base_url = "http://127.0.0.1:8001";
            default_request_timeout_in_seconds = 120;
          };
          custom_provider_config = {
            base_provider_type = "openai";
            allowed_requests = {
              chat_completion = true;
              chat_completion_stream = true;
              responses = true;
              responses_stream = true;
              list_models = true;
            };
          };
        };

        # Local llama.cpp — thinking (reasoning mode)
        qwen36-35b-a3b-reasoning = {
          keys = [
            {
              name = "local";
              value = "none";
              models = [ ];
              weight = 1.0;
            }
          ];
          network_config = {
            base_url = "http://127.0.0.1:8011";
            default_request_timeout_in_seconds = 300;
          };
          custom_provider_config = {
            base_provider_type = "openai";
            allowed_requests = {
              chat_completion = true;
              chat_completion_stream = true;
              responses = true;
              responses_stream = true;
              list_models = true;
            };
          };
        };
      };

      # MCP Gateway — ONLY HTTP/SSE clients work inside Bifrost's sandbox.
      # Stdio clients (filesystem, github) run as user-level local MCPs in
      # LibreChat and OpenCode instead. See those modules for their configs.
      mcp = {
        client_configs = [
          {
            name = "tavily";
            connection_type = "http";
            connection_string = "env.TAVILY_MCP_URL";
            is_ping_available = false;
            tools_to_execute = [ "*" ];
          }
        ];
      };
    };
  };

  # Ensure env file exists (systemd reads EnvironmentFile as root before
  # dropping to DynamicUser; StateDirectory already creates /var/lib/bifrost)
  systemd.tmpfiles.rules = [
    "f /var/lib/bifrost/env 0600 root root -"
  ];
}
