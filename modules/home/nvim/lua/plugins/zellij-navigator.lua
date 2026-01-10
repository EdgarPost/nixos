-- Seamless navigation between nvim and zellij panes
return {
  {
    "swaits/zellij-nav.nvim",
    lazy = false,
    keys = {
      { "<C-h>", "<cmd>ZellijNavigateLeft<cr>", desc = "Navigate left" },
      { "<C-j>", "<cmd>ZellijNavigateDown<cr>", desc = "Navigate down" },
      { "<C-k>", "<cmd>ZellijNavigateUp<cr>", desc = "Navigate up" },
      { "<C-l>", "<cmd>ZellijNavigateRight<cr>", desc = "Navigate right" },
    },
    opts = {},
  },
}
