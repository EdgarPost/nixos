return {
  -- Disable neo-tree (using yazi instead)
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  -- Disable indent guides
  { "lukas-reineke/indent-blankline.nvim", enabled = false },

  -- Disable all animations (mini.animate)
  { "echasnovski/mini.animate", enabled = false },

  -- Disable snacks.nvim scroll animation
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = false },
    },
  },
}
