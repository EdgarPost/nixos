{ pkgs, ... }:

let
  modelDir = "/var/lib/llama-models";
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  mkLlamaService = { model, port, ctxSize, description, autostart ? true }: {
    inherit description;
    after = [ "network.target" ];
    wantedBy = if autostart then [ "multi-user.target" ] else [];
    serviceConfig = {
      Type = "exec";
      User = "llama";
      Group = "llama";
      ExecStart = builtins.concatStringsSep " " [
        "${llama-cpp}/bin/llama-server"
        "--model" "${modelDir}/${model}"
        "--port" (toString port)
        "--host" "0.0.0.0"
        "--ctx-size" (toString ctxSize)
        "--no-mmap"
        "-fa" "on"
        "-ngl" "99"
        "--cache-type-k" "q8_0"
        "--cache-type-v" "q8_0"
      ];
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

    echo "Downloading Qwen3.5-35B-A3B (quick model, ~22GB)..."
    run $HF download unsloth/Qwen3.5-35B-A3B-GGUF \
      Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf \
      --local-dir ${modelDir}

    echo "Downloading Qwen3.5-27B (reasoning model, ~17GB)..."
    run $HF download unsloth/Qwen3.5-27B-GGUF \
      Qwen3.5-27B-UD-Q4_K_XL.gguf \
      --local-dir ${modelDir}

    echo "Downloading Qwen3.5-4B (fast small model, ~3GB)..."
    run $HF download unsloth/Qwen3.5-4B-GGUF \
      Qwen3.5-4B-Q4_K_M.gguf \
      --local-dir ${modelDir}

    echo "Downloading OmniCoder-9B (coding agent, ~6GB)..."
    run $HF download Tesslate/OmniCoder-9B-GGUF \
      omnicoder-9b-q4_k_m.gguf \
      --local-dir ${modelDir}

    echo "Done! Start services:"
    echo "  sudo systemctl start llama-qwen3_5-35b-a3b llama-qwen3_5-27b llama-qwen3_5-4b llama-omnicoder-9b"
  '';
in
{
  systemd.services.llama-qwen3_5-35b-a3b = mkLlamaService {
    model = "Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf";
    port = 8001;
    ctxSize = 65536;
    description = "llama.cpp - Qwen3.5-35B-A3B (MoE, 3B active)";
  };

  systemd.services.llama-qwen3_5-27b = mkLlamaService {
    model = "Qwen3.5-27B-UD-Q4_K_XL.gguf";
    port = 8002;
    ctxSize = 131072;
    description = "llama.cpp - Qwen3.5-27B (dense)";
    autostart = false;
  };

  systemd.services.llama-qwen3_5-4b = mkLlamaService {
    model = "Qwen3.5-4B-Q4_K_M.gguf";
    port = 8003;
    ctxSize = 32768;
    description = "llama.cpp - Qwen3.5-4B (fast, Dutch stories)";
  };

  systemd.services.llama-omnicoder-9b = mkLlamaService {
    model = "omnicoder-9b-q4_k_m.gguf";
    port = 8004;
    ctxSize = 131072;
    description = "llama.cpp - OmniCoder-9B (coding agent)";
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
