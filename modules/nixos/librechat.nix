# ============================================================================
# LIBRECHAT - AI Chat Interface
# ============================================================================
#
# WHAT IS THIS?
# - Self-hosted ChatGPT-like interface for local and cloud AI models
# - Connects to Bifrost gateway on port 4000 for all models
#
# ARCHITECTURE:
#   LibreChat (:3080) → Bifrost (:4000) → llama.cpp / Anthropic / Mistral
#
# THINKING MODE:
#   Two Bifrost endpoints: one injects enable_thinking=false, one =true.
#   llama.cpp handles thinking per-request via chat_template_kwargs.
#
# ACCESS:
#   http://edgar-framework-desktop:3080
#
# ============================================================================

{ ... }:

let
  localModels = [
    "qwen35-35b-a3b/qwen3.5-35b-a3b"
    "omnicoder-9b/omnicoder-9b"
  ];
  reasoningModels = [
    "qwen35-35b-a3b-reasoning/qwen3.5-35b-a3b-reasoning"
    "omnicoder-9b-reasoning/omnicoder-9b-reasoning"
  ];
  cloudModels = [
    "anthropic/claude-opus-4-6"
    "anthropic/claude-sonnet-4-6"
    "anthropic/claude-haiku-4-5-20251001"
    "mistral/devstral-medium-latest"
    "mistral/devstral-small-latest"
  ];
in
{
  networking.firewall.allowedTCPPorts = [ 3080 ];

  services.librechat = {
    enable = true;
    enableLocalDB = true;
    credentialsFile = "/var/lib/librechat/secrets.env";

    env = {
      PORT = "3080";
      HOST = "0.0.0.0";
      ALLOW_REGISTRATION = "true";
      ALLOW_SOCIAL_LOGIN = "false";
    };

    settings = {
      version = "1.2.1";
      cache = true;

      interface = {
        endpointsMenu = true;
        modelSelect = true;
        parameters = true;
      };

      endpoints = {
        custom = [
          {
            name = "Bifrost";
            apiKey = "none";
            baseURL = "http://127.0.0.1:4000/v1";
            models = {
              default = localModels ++ reasoningModels ++ cloudModels;
              fetch = true;
            };
            titleConvo = true;
            titleModel = "qwen35-35b-a3b/qwen3.5-35b-a3b";
            modelDisplayLabel = "Bifrost";
          }
        ];
      };

      modelSpecs = {
        enforce = false;
        list = [
          # Local models — fast (thinking off)
          {
            name = "qwen3.5-35b-a3b";
            label = "Qwen 3.5 35B A3B";
            description = "Fast MoE model (3B active params)";
            preset = {
              endpoint = "Bifrost";
              model = "qwen35-35b-a3b/qwen3.5-35b-a3b";
            };
          }

          {
            name = "omnicoder-9b";
            label = "OmniCoder 9B";
            description = "Coding agent model";
            preset = {
              endpoint = "Bifrost";
              model = "omnicoder-9b/omnicoder-9b";
            };
          }
          # Local models — reasoning (separate llama instances with thinking on)
          {
            name = "qwen3.5-35b-a3b-reasoning";
            label = "Qwen 3.5 35B A3B (Reasoning)";
            description = "MoE model with extended thinking";
            preset = {
              endpoint = "Bifrost";
              model = "qwen35-35b-a3b-reasoning/qwen3.5-35b-a3b-reasoning";
            };
          }

          {
            name = "omnicoder-9b-reasoning";
            label = "OmniCoder 9B (Reasoning)";
            description = "Coding model with extended thinking";
            preset = {
              endpoint = "Bifrost";
              model = "omnicoder-9b-reasoning/omnicoder-9b-reasoning";
            };
          }
          # Cloud models
          {
            name = "claude-opus";
            label = "Claude Opus 4.6";
            preset = {
              endpoint = "Bifrost";
              model = "anthropic/claude-opus-4-6";
            };
          }
          {
            name = "claude-sonnet";
            label = "Claude Sonnet 4.6";
            preset = {
              endpoint = "Bifrost";
              model = "anthropic/claude-sonnet-4-6";
            };
          }
          {
            name = "claude-haiku";
            label = "Claude Haiku 4.5";
            preset = {
              endpoint = "Bifrost";
              model = "anthropic/claude-haiku-4-5-20251001";
            };
          }
          {
            name = "devstral-medium";
            label = "Devstral Medium";
            preset = {
              endpoint = "Bifrost";
              model = "mistral/devstral-medium-latest";
            };
          }
          {
            name = "devstral-small";
            label = "Devstral Small";
            preset = {
              endpoint = "Bifrost";
              model = "mistral/devstral-small-latest";
            };
          }
        ];
      };
    };
  };
}
