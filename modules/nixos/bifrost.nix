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
#   Bifrost (:4000) ─────┼── llama.cpp :8004  (OmniCoder-9B)
#                        ├── Anthropic API    (Claude, optional)
#                        └── Mistral API      (Codestral, optional)
#
# CLOUD API KEYS:
#   API keys are loaded from /var/lib/bifrost/env (not in Nix store).
#   Use `anthropic-login` / `mistral-login` shell functions to inject keys
#   from 1Password into both shell env and Bifrost env file.
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
        # Local llama.cpp instances (OpenAI-compatible)
        qwen36-35b-a3b = {
          keys = [{ name = "local"; value = "none"; models = []; weight = 1.0; }];
          network_config.base_url = "http://127.0.0.1:8001";
          custom_provider_config = {
            base_provider_type = "openai";
            allowed_requests = {
              chat_completion = true;
              chat_completion_stream = true;
              list_models = true;
            };
          };
        };

        omnicoder-9b = {
          keys = [{ name = "local"; value = "none"; models = []; weight = 1.0; }];
          network_config.base_url = "http://127.0.0.1:8004";
          custom_provider_config = {
            base_provider_type = "openai";
            allowed_requests = {
              chat_completion = true;
              chat_completion_stream = true;
              list_models = true;
            };
          };
        };

        # Local llama.cpp instances — reasoning ON (ports 801x)
        qwen36-35b-a3b-reasoning = {
          keys = [{ name = "local"; value = "none"; models = []; weight = 1.0; }];
          network_config.base_url = "http://127.0.0.1:8011";
          custom_provider_config = {
            base_provider_type = "openai";
            allowed_requests = {
              chat_completion = true;
              chat_completion_stream = true;
              list_models = true;
            };
          };
        };

        omnicoder-9b-reasoning = {
          keys = [{ name = "local"; value = "none"; models = []; weight = 1.0; }];
          network_config.base_url = "http://127.0.0.1:8014";
          custom_provider_config = {
            base_provider_type = "openai";
            allowed_requests = {
              chat_completion = true;
              chat_completion_stream = true;
              list_models = true;
            };
          };
        };

        # Cloud providers (activated when API keys are in env file)
        anthropic = {
          keys = [{
            name = "anthropic";
            value = "env.ANTHROPIC_API_KEY";
            weight = 1.0;
            models = [
              "claude-opus-4-6"
              "claude-sonnet-4-6"
              "claude-haiku-4-5-20251001"
            ];
          }];
        };
        mistral = {
          keys = [{
            name = "mistral";
            value = "env.MISTRAL_API_KEY";
            weight = 1.0;
            models = [
              "devstral-medium-latest"
              "devstral-small-latest"
            ];
          }];
        };
      };
    };
  };

  # Ensure env file exists (systemd reads EnvironmentFile as root before
  # dropping to DynamicUser; StateDirectory already creates /var/lib/bifrost)
  systemd.tmpfiles.rules = [
    "f /var/lib/bifrost/env 0600 root root -"
  ];
}
