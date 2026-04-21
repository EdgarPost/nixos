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
#   Two llama.cpp instances: one with enable_thinking=false, one with thinking on.
#   Bifrost routes to the correct instance based on provider name.
#
# ACCESS:
#   http://edgar-framework-desktop:3080
#
# ============================================================================

{ ... }:

let
  localModels = [
    "qwen36-35b-a3b/qwen3.6-35b-a3b"
  ];
  reasoningModels = [
    "qwen36-35b-a3b-reasoning/qwen3.6-35b-a3b-reasoning"
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
            baseURL = "http://edgar-framework-desktop:4000/v1";
            models = {
              default = localModels ++ reasoningModels;
              fetch = true;
            };
            titleConvo = true;
            titleModel = "qwen36-35b-a3b/qwen3.6-35b-a3b";
            modelDisplayLabel = "Bifrost";
          }
        ];
      };

      modelSpecs = {
        enforce = false;
        list = [
          # Local models — fast (thinking off)
          {
            name = "qwen3.6-35b-a3b";
            label = "Qwen 3.6 35B A3B";
            description = "Fast MoE model (3B active params)";
            preset = {
              endpoint = "Bifrost";
              model = "qwen36-35b-a3b/qwen3.6-35b-a3b";
            };
          }

          # Local models — reasoning (separate llama instances with thinking on)
          {
            name = "qwen3.6-35b-a3b-reasoning";
            label = "Qwen 3.6 35B A3B (Reasoning)";
            description = "MoE model with extended thinking";
            preset = {
              endpoint = "Bifrost";
              model = "qwen36-35b-a3b-reasoning/qwen3.6-35b-a3b-reasoning";
            };
          }
        ];
      };
    };
  };
}
