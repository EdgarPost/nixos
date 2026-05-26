{ pkgs, ... }:

let
  modelDir = "/var/lib/llama-models";
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  mkLlamaService =
    {
      model,
      alias ? null,
      port,
      ctxSize,
      description,
      autostart ? true,
      temperature ? null,
      topP ? null,
      topK ? null,
      minP ? null,
      presencePenalty ? null,
      reasoning ? null,
      extraFlags ? [],
    }:
    {
      inherit description;
      after = [ "network.target" ];
      wantedBy = if autostart then [ "multi-user.target" ] else [ ];
      serviceConfig = {
        Type = "exec";
        User = "llama";
        Group = "llama";
        ExecStart = builtins.concatStringsSep " " (
          [
            "${llama-cpp}/bin/llama-server"
            "--model"
            "${modelDir}/${model}"
            "--port"
            (toString port)
            "--host"
            "0.0.0.0"
            "--ctx-size"
            (toString ctxSize)
            "-fa"
            "on"
            "-ngl"
            "99"
            "--cache-type-k"
            "q8_0"
            "--cache-type-v"
            "q8_0"
            "--swa-full"
            "--mlock"
            "--keep"
            "1024"
          ]
          ++ (if alias != null then [ "--alias" alias ] else [ ])
          ++ (if temperature != null then [ "--temp" (toString temperature) ] else [ ])
          ++ (if topP != null then [ "--top-p" (toString topP) ] else [ ])
          ++ (if topK != null then [ "--top-k" (toString topK) ] else [ ])
          ++ (if minP != null then [ "--min-p" (toString minP) ] else [ ])
          ++ (if presencePenalty != null then [ "--presence-penalty" (toString presencePenalty) ] else [ ])
          ++ (if reasoning != null then [ "--reasoning" reasoning ] else [ ])
          ++ extraFlags
        );
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

    echo "Downloading Qwen3.6-35B-A3B MTP-GGUF (~23GB)..."
    run $HF download unsloth/Qwen3.6-35B-A3B-MTP-GGUF \
      --include "*UD-Q4_K_XL*" \
      --local-dir ${modelDir}

    # Normalise to a stable filename regardless of how HF names the file
    for f in ${modelDir}/*UD-Q4_K_XL*.gguf; do
      target="${modelDir}/Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf"
      if [ "$f" != "$target" ]; then
        sudo -u llama mv "$f" "$target"
      fi
    done

    echo "Done! Start services:"
    echo "  sudo systemctl start llama-qwen3_6-35b-a3b llama-qwen3_6-35b-a3b-reasoning"
  '';
in
{
  # ── Non-thinking instance ──────────────────────────────────────────
  # Unsloth instruct mode: temp 0.7, top_p 0.8, top_k 20, min_p 0.0
  systemd.services.llama-qwen3_6-35b-a3b = mkLlamaService {
    model = "Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf";
    alias = "qwen3.6-35b-a3b";
    port = 8001;
    ctxSize = 262144;
    temperature = 0.7;
    topP = 0.8;
    topK = 20;
    minP = 0.0;
    presencePenalty = 1.5;
    reasoning = "off";
    extraFlags = [ "--spec-type" "draft-mtp" "--spec-draft-n-max" "2" ];
    description = "llama.cpp - Qwen3.6-35B-A3B";
  };

  # ── Thinking instance ──────────────────────────────────────────────
  # Unsloth coding+thinking: temp 0.6, top_p 0.95, top_k 20, presence_penalty 0.0
  # Same model file — mmap shares memory pages between instances
  systemd.services.llama-qwen3_6-35b-a3b-reasoning = mkLlamaService {
    model = "Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL.gguf";
    alias = "qwen3.6-35b-a3b-reasoning";
    port = 8011;
    ctxSize = 262144;
    temperature = 0.6;
    topP = 0.95;
    topK = 20;
    minP = 0.0;
    presencePenalty = 0.0;
    extraFlags = [ "--spec-type" "draft-mtp" "--spec-draft-n-max" "2" ];
    description = "llama.cpp - Qwen3.6-35B-A3B (reasoning)";
  };

  users.users.llama = {
    isSystemUser = true;
    group = "llama";
    home = modelDir;
  };
  users.groups.llama = { };
  users.users.edgar.extraGroups = [ "llama" ];
  systemd.tmpfiles.rules = [ "d ${modelDir} 0775 llama llama -" ];

  environment.systemPackages = [
    llama-cpp
    llama-download-models
    pkgs.python3Packages.hf-transfer
  ];
}
