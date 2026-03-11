{ pkgs, ... }:

let
  modelDir = "/var/lib/llama-models";
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  mkLlamaService = { model, port, ctxSize, description }: {
    inherit description;
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
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

    echo "Done! Start services:"
    echo "  sudo systemctl start llama-qwen3_5-35b-a3b llama-qwen3_5-27b"
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
