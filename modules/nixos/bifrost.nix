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
#   Bifrost (:4000) ─────┼── llama.cpp :8011  (Qwen3.6-35B-A3B, reasoning)
#                        └── Anthropic API    (Claude, optional)
#
# CLOUD API KEYS:
#   API keys are loaded from /var/lib/bifrost/env (not in Nix store).
#   Use `anthropic-login` shell functions to inject keys
#   from 1Password into both shell env and Bifrost env file.
#
# MCP GATEWAY:
#   Bifrost can act as a central MCP gateway — register MCP servers once,
#   all clients (LibreChat, OpenCode, Claude Code) get tool access.
#   Code Mode replaces 150+ tool defs with 4 meta-tools (~50% token savings).
#   See mcp block in settings below.
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

        # Cloud providers (activated when API keys are in env file)
        anthropic = {
          keys = [
            {
              name = "anthropic";
              value = "env.ANTHROPIC_API_KEY";
              weight = 1.0;
              models = [
                "claude-opus-4-6"
                "claude-sonnet-4-6"
                "claude-haiku-4-5-20251001"
              ];
            }
          ];
        };
      };

      # MCP Gateway — register MCP servers here for all clients to access
      # Uncomment when Bifrost MCP support is verified in this version
      # mcp = {
      #   client_configs = [
      #     {
      #       name = "filesystem";
      #       connection_type = "stdio";
      #       stdio_config = {
      #         command = "npx";
      #         args = ["-y" "@anthropic/mcp-filesystem"];
      #       };
      #       tools_to_execute = ["*"];
      #       is_code_mode_client = true;
      #     }
      #   ];
      #   tool_manager_config = {
      #     code_mode_binding_level = "server";
      #   };
      # };
    };
  };

  # Ensure env file exists (systemd reads EnvironmentFile as root before
  # dropping to DynamicUser; StateDirectory already creates /var/lib/bifrost)
  systemd.tmpfiles.rules = [
    "f /var/lib/bifrost/env 0600 root root -"
  ];
}
