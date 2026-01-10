-- Yazi file manager integration (floating window)
return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>e", "<cmd>Yazi<cr>", desc = "Open yazi (current file)" },
      { "<leader>E", "<cmd>Yazi cwd<cr>", desc = "Open yazi (cwd)" },
    },
    opts = {
      open_for_directories = true, -- Replace netrw for directories
      floating_window_scaling_factor = 0.9,
    },
  },
}
