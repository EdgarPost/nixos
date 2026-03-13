# ============================================================================
# LITELLM - Unified AI Gateway Proxy
# ============================================================================
#
# WHAT IS THIS?
# - LiteLLM proxy that sits in front of local llama.cpp models and cloud APIs
# - Provides a single OpenAI-compatible endpoint on port 4000
# - Local models (Qwen) work immediately, cloud models need API keys
#
# ARCHITECTURE:
#                       ┌── llama.cpp :8001  (Qwen3.5-35B-A3B)
#   LiteLLM (:4000) ───┼── llama.cpp :8002  (Qwen3.5-27B)
#                       ├── llama.cpp :8003  (Qwen3.5-4B)
#                       ├── llama.cpp :8004  (OmniCoder-9B)
#                       ├── Anthropic API    (Claude, optional)
#                       └── Mistral API      (Codestral, optional)
#
# CLOUD API KEYS:
#   API keys are loaded from /var/lib/litellm/env (not in Nix store).
#   Use `anthropic-login` / `mistral-login` shell functions to inject keys
#   from 1Password into both shell env and LiteLLM env file.
#
# ============================================================================

{ ... }:

{
  services.litellm = {
    enable = true;
    port = 4000;
    host = "0.0.0.0";
    environmentFile = "/var/lib/litellm/env";
    settings = {
      model_list = [
        # Local models (always available, thinking disabled by default)
        {
          model_name = "qwen3.5-35b-a3b";
          litellm_params = {
            model = "openai/qwen3.5-35b-a3b";
            api_base = "http://127.0.0.1:8001/v1";
            api_key = "none";
            extra_body = {
              chat_template_kwargs = { enable_thinking = false; };
            };
          };
        }
        {
          model_name = "qwen3.5-27b";
          litellm_params = {
            model = "openai/qwen3.5-27b";
            api_base = "http://127.0.0.1:8002/v1";
            api_key = "none";
            extra_body = {
              chat_template_kwargs = { enable_thinking = false; };
            };
          };
        }
        {
          model_name = "qwen3.5-4b";
          litellm_params = {
            model = "openai/qwen3.5-4b";
            api_base = "http://127.0.0.1:8003/v1";
            api_key = "none";
            extra_body = {
              chat_template_kwargs = { enable_thinking = false; };
            };
          };
        }
        {
          model_name = "omnicoder-9b";
          litellm_params = {
            model = "openai/omnicoder-9b";
            api_base = "http://127.0.0.1:8004/v1";
            api_key = "none";
            extra_body = {
              chat_template_kwargs = { enable_thinking = false; };
            };
          };
        }
        # Reasoning variants (thinking enabled, for Open WebUI)
        {
          model_name = "qwen3.5-35b-a3b-reasoning";
          litellm_params = {
            model = "openai/qwen3.5-35b-a3b-reasoning";
            api_base = "http://127.0.0.1:8001/v1";
            api_key = "none";
          };
        }
        {
          model_name = "qwen3.5-27b-reasoning";
          litellm_params = {
            model = "openai/qwen3.5-27b-reasoning";
            api_base = "http://127.0.0.1:8002/v1";
            api_key = "none";
          };
        }
        {
          model_name = "omnicoder-9b-reasoning";
          litellm_params = {
            model = "openai/omnicoder-9b-reasoning";
            api_base = "http://127.0.0.1:8004/v1";
            api_key = "none";
          };
        }
        # Cloud models (activated when API keys are in env file)
        {
          model_name = "claude-opus";
          litellm_params = {
            model = "anthropic/claude-opus-4-6";
            api_key = "os.environ/ANTHROPIC_API_KEY";
          };
        }
        {
          model_name = "claude-sonnet";
          litellm_params = {
            model = "anthropic/claude-sonnet-4-6";
            api_key = "os.environ/ANTHROPIC_API_KEY";
          };
        }
        {
          model_name = "claude-haiku";
          litellm_params = {
            model = "anthropic/claude-haiku-4-5-20251001";
            api_key = "os.environ/ANTHROPIC_API_KEY";
          };
        }
        {
          model_name = "devstral-medium";
          litellm_params = {
            model = "mistral/devstral-medium-latest";
            api_key = "os.environ/MISTRAL_API_KEY";
          };
        }
        {
          model_name = "devstral-small";
          litellm_params = {
            model = "mistral/devstral-small-latest";
            api_key = "os.environ/MISTRAL_API_KEY";
          };
        }
      ];
      litellm_settings = {
        drop_params = true;
      };
    };
  };

  # Ensure env file exists (systemd reads EnvironmentFile as root before
  # dropping to DynamicUser; StateDirectory already creates /var/lib/litellm)
  systemd.tmpfiles.rules = [
    "f /var/lib/litellm/env 0600 root root -"
  ];
}
