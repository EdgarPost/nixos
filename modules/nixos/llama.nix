{ pkgs, ... }:

let
  modelDir = "/var/lib/llama-models";
  llama-cpp = pkgs.llama-cpp.override { vulkanSupport = true; };

  mkLlamaService =
    {
      model,
      # Optional speculative MTP draft (separate GGUF, e.g. dense Qwen 27B:
      # "MTP/mtp-Qwen3.8-27B-Q4_0.gguf"). Passed via -md; the unit also
      # requires the draft to exist before starting.
      draftModel ? null,
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
    }: {
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
          ]
          ++ (if draftModel != null then [ "-md" "${modelDir}/${draftModel}" ] else [ ])
          ++ [
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
      unitConfig.ConditionPathExists =
        [ "${modelDir}/${model}" ]
        ++ (if draftModel != null then [ "${modelDir}/${draftModel}" ] else [ ]);
    };

  llama-download-models = pkgs.writeShellScriptBin "llama-download-models" ''
    set -euo pipefail
    HF="${pkgs.python3Packages.huggingface-hub}/bin/hf"

    run() {
      sudo -u llama env HF_HUB_ENABLE_HF_TRANSFER=1 "$@"
    }

    # NOTE: the MTP repo files are named WITHOUT "MTP" in the filename.
    # Use exact filenames per download; never glob+rename across models
    # (a previous glob-based "normalise" loop overwrote the MoE file with
    #  the 27B file, so the fast instance silently served the dense model).
    echo "Downloading Qwen3.6-35B-A3B MTP-GGUF UD-Q4_K_XL (~22.9GB)..."
    run $HF download unsloth/Qwen3.6-35B-A3B-MTP-GGUF \
      --include "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf" \
      --local-dir ${modelDir}

    echo "Downloading Qwen3.8-27B UD-Q4_K_M (~16.5GB)..."
    run $HF download unsloth/Qwen3.8-27B-GGUF \
      --include "Qwen3.8-27B-UD-Q4_K_M.gguf" \
      --include "MTP/mtp-Qwen3.8-27B-Q4_0.gguf" \
      --local-dir ${modelDir}

    echo "Done! Start services:"
    echo "  sudo systemctl start llama-qwen3_6-35b-a3b llama-qwen3_8-27b"
  '';
in
{
  # ── Fast MoE instance (port 8001) ──────────────────────────────────
  # Unsloth instruct mode: temp 0.7, top_p 0.8, top_k 20, min_p 0.0
  # MoE = ~3B active params, MTP speculative decoding for speed.
  #
  # ON-DEMAND REASONING (no separate instance needed):
  #   Thinking is OFF by default (--reasoning off). Any request can opt in
  #   per-call via the OpenAI-compatible API:
  #     chat_template_kwargs: { "enable_thinking": true }
  #   → response includes reasoning_content (thinking tokens).
  #   NOTE: top-level "reasoning_effort" does NOT enable Qwen thinking on
  #   llama.cpp build 10408 (only makes replies verbose) — use the kwargs
  #   above. Verified empirically on this host. Remove the --reasoning off
  #   default (reasoning=null) to let the model's template decide instead.
  #
  # NO MLOCK: with -ngl 99 weights live in Vulkan device memory (UMA/GTT),
  # not the process mapping — VmLck stays 0 kB, so --load-mode mlock is a
  # no-op on this build and was removed (verified empirically).
  systemd.services.llama-qwen3_6-35b-a3b = mkLlamaService {
    # Real HF filename in unsloth/Qwen3.6-35B-A3B-MTP-GGUF (no "MTP" in the name).
    model = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
    alias = "qwen3.6-35b-a3b";
    port = 8001;
    # Sweet spot: 256K ctx measurably costs prompt-processing speed on Strix
    # Halo (~68% of 4K-ctx pp speed is retained at 64K; more at 128K).
    ctxSize = 131072;
    temperature = 0.7;
    topP = 0.8;
    topK = 20;
    minP = 0.0;
    presencePenalty = 1.5;
    reasoning = "off";
    extraFlags = [ "--spec-type" "draft-mtp" "--spec-draft-n-max" "2" "--ubatch-size" "1024" "--poll" "100" ];
    description = "llama.cpp - Qwen3.6-35B-A3B (MoE, fast)";
  };

  # ── Dense quality instance (port 8002) ─────────────────────────────
  # Qwen3.8-27B = DENSE 27B (all params active; NOT MoE, so it is
  # inherently slower than the 35B-A3B instance above — this one is the
  # quality/vision/agentic workhorse. Unsloth Dynamic V3.0 quants: the
  # repo's current "UD-" files are the updated Dynamic 3.0 builds
  # (verified on the HF tree 2026-08-26; no separate UD3- files there).
  #
  # MTP speculative decode: Qwen3.8-27B ships a separate tiny draft
  # (MTP/mtp-Qwen3.8-27B-Q4_0.gguf, ~1.4GB) — reuse the same
  # --spec-type draft-mtp trick as the MoE instance, only via -md,
  # since the dense 27B does NOT bake the MTP head into the main GGUF.
  # This is the main decode-speed lever for a dense model.
  #
  # Sampling: unsloth's documented Qwen3.8 run recipe
  # (--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0) instead of the
  # MoE's tuned instruct-mode values. Reasoning left ON (template
  # decides); disable per-call with chat_template_kwargs if wanted.
  #
  # CONTEXT: native 256K (262144, extensible to 1M). KV q8_0 ≈ 8.4 GB at
  # 256K on this hybrid arch (only the 16 gated-attention blocks cache KV;
  # DeltaNet blocks use a small recurrent state) — cheap on 125 GB RAM.
  # Cost of the big window is prompt-processing speed on LONG contexts;
  # short prompts are unaffected. 35B stays at 128K (fast instance).
  systemd.services.llama-qwen3_8-27b = mkLlamaService {
    model = "Qwen3.8-27B-UD-Q4_K_M.gguf";
    draftModel = "MTP/mtp-Qwen3.8-27B-Q4_0.gguf";
    alias = "qwen3.8-27b";
    port = 8002;
    ctxSize = 262144;
    temperature = 1.0;
    topP = 0.95;
    topK = 20;
    minP = 0.0;
    extraFlags = [ "--spec-type" "draft-mtp" "--spec-draft-n-max" "2" "--ubatch-size" "1024" "--poll" "100" ];
    description = "llama.cpp - Qwen3.8-27B (dense, quality)";
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
