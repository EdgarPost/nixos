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
      # KV cache quant. q8_0 = default (quality, what both instances
      # historically used). q4_0/q4_1 = ~1.8× smaller KV -> less UMA
      # bandwidth per attention step, so faster decode at LONG contexts
      # (never slower; negligible difference at short contexts), at a
      # small quality cost confined to the 16 gated-attention layers on
      # this hybrid arch (the DeltaNet blocks cache no KV at all).
      cacheTypeK ? "q8_0",
      cacheTypeV ? "q8_0",
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
      extraFlags ? [ ],
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
          ]
          ++ (
            if draftModel != null then
              [
                "-md"
                "${modelDir}/${draftModel}"
              ]
            else
              [ ]
          )
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
            cacheTypeK
            "--cache-type-v"
            cacheTypeV
            "--swa-full"
            "--keep"
            "1024"
          ]
          ++ (
            if alias != null then
              [
                "--alias"
                alias
              ]
            else
              [ ]
          )
          ++ (
            if temperature != null then
              [
                "--temp"
                (toString temperature)
              ]
            else
              [ ]
          )
          ++ (
            if topP != null then
              [
                "--top-p"
                (toString topP)
              ]
            else
              [ ]
          )
          ++ (
            if topK != null then
              [
                "--top-k"
                (toString topK)
              ]
            else
              [ ]
          )
          ++ (
            if minP != null then
              [
                "--min-p"
                (toString minP)
              ]
            else
              [ ]
          )
          ++ (
            if presencePenalty != null then
              [
                "--presence-penalty"
                (toString presencePenalty)
              ]
            else
              [ ]
          )
          ++ (
            if reasoning != null then
              [
                "--reasoning"
                reasoning
              ]
            else
              [ ]
          )
          ++ extraFlags
        );
        Restart = "on-failure";
        RestartSec = "5s";
      };
      unitConfig.ConditionPathExists = [
        "${modelDir}/${model}"
      ]
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

    echo "Done! Start service:"
    echo "  sudo systemctl start llama-qwen3_6-35b-a3b"
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
    presencePenalty = 1.0;
    reasoning = "off";
    # Speed instance: q4_0 KV cache (~1.8× smaller -> faster attention at
    # long contexts, equal at short; tiny quality cost on the 16 attention
    # layers) + ubatch 2048 for prompt-processing throughput.
    cacheTypeK = "q4_0";
    cacheTypeV = "q4_0";
    extraFlags = [
      "--spec-type"
      "draft-mtp"
      "--spec-draft-n-max"
      "2"
      "--ubatch-size"
      "2048"
      "--poll"
      "100"
    ];
    description = "llama.cpp - Qwen3.6-35B-A3B (MoE, fast)";
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
