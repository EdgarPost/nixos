return {
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
