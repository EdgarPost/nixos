return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "InsertEnter",
    opts = {
      provider = "openai_compatible",
      provider_options = {
        openai_compatible = {
          api_key = "none",
          end_point = "http://localhost:4000/v1/chat/completions",
          model = "qwen3.5-35b-a3b",
          name = "LiteLLM",
          optional = {
            max_tokens = 256,
            top_p = 0.9,
          },
        },
      },
      virtualtext = {
        auto_trigger_ft = { "*" },
        keymap = {
          accept = "<Tab>",
          dismiss = "<C-e>",
          accept_line = "<A-a>",
          accept_n_lines = "<A-z>",
          prev = "<A-[>",
          next = "<A-]>",
        },
      },
    },
  },
}
