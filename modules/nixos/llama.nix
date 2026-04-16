{ pkgs, ... }:

let
  modelDir = "/var/lib/llama-models";
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  mkLlamaService = { model, alias ? null, port, ctxSize, description, autostart ? true, reasoningBudget ? -1 }: {
    inherit description;
    after = [ "network.target" ];
    wantedBy = if autostart then [ "multi-user.target" ] else [];
    serviceConfig = {
      Type = "exec";
      User = "llama";
      Group = "llama";
      ExecStart = builtins.concatStringsSep " " ([
        "${llama-cpp}/bin/llama-server"
        "--model" "${modelDir}/${model}"
        "--port" (toString port)
        "--host" "0.0.0.0"
        "--ctx-size" (toString ctxSize)
        "-fa" "on"
        "-ngl" "99"
        "--cache-type-k" "q8_0"
        "--cache-type-v" "q8_0"
        "--reasoning-budget" (toString reasoningBudget)
      ] ++ (if alias != null then [ "--alias" alias ] else []));
      Restart = "on-failure";
      RestartSec = "5s";
    };
    unitConfig.ConditionPathExists = "${modelDir}/${model}";
  };

  llama-download-models = pkgs.writeShellScriptBin "llama-download-models" ''
    set -euo pipefail
    HF="${pkgs.python3Packages.huggingface-hub}/bin/hf"

    run() {
      sudo -u llama env HF_HUB_ENABLE_HF_TRANSFER=1 "$@"
    }

    echo "Downloading Qwen3.6-35B-A3B (quick model, ~22GB)..."
    run $HF download unsloth/Qwen3.6-35B-A3B-GGUF \
      Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf \
      --local-dir ${modelDir}


    echo "Downloading OmniCoder-9B (coding agent, ~6GB)..."
    run $HF download Tesslate/OmniCoder-9B-GGUF \
      omnicoder-9b-q4_k_m.gguf \
      --local-dir ${modelDir}

    echo "Done! Start services:"
    echo "  sudo systemctl start llama-qwen3_6-35b-a3b llama-omnicoder-9b"
  '';
in
{
  # ── Non-thinking instances (reasoning off) ──────────────────────────
  systemd.services.llama-qwen3_6-35b-a3b = mkLlamaService {
    model = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
    alias = "qwen3.6-35b-a3b";
    port = 8001;
    ctxSize = 262144;
    reasoningBudget = 0;
    description = "llama.cpp - Qwen3.6-35B-A3B";
  };


  systemd.services.llama-omnicoder-9b = mkLlamaService {
    model = "omnicoder-9b-q4_k_m.gguf";
    alias = "omnicoder-9b";
    port = 8004;
    ctxSize = 131072;
    reasoningBudget = 0;
    description = "llama.cpp - OmniCoder-9B";
  };

  # ── Thinking instances (reasoning on) ───────────────────────────────
  # Same model files, mmap shares memory pages between instances
  systemd.services.llama-qwen3_6-35b-a3b-reasoning = mkLlamaService {
    model = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
    alias = "qwen3.6-35b-a3b-reasoning";
    port = 8011;
    ctxSize = 262144;
    description = "llama.cpp - Qwen3.6-35B-A3B (reasoning)";
  };


  systemd.services.llama-omnicoder-9b-reasoning = mkLlamaService {
    model = "omnicoder-9b-q4_k_m.gguf";
    alias = "omnicoder-9b-reasoning";
    port = 8014;
    ctxSize = 131072;
    description = "llama.cpp - OmniCoder-9B (reasoning)";
  };

  users.users.llama = { isSystemUser = true; group = "llama"; home = modelDir; };
  users.groups.llama = {};
  users.users.edgar.extraGroups = [ "llama" ];
  systemd.tmpfiles.rules = [ "d ${modelDir} 0775 llama llama -" ];

  environment.systemPackages = [
    llama-cpp
    llama-download-models
    pkgs.python3Packages.hf-transfer
  ];
}
