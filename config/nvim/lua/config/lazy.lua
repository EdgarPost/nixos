-- LazyVim plugin configuration
-- This sets up the LazyVim distribution

require("lazy").setup({
  spec = {
    -- Import LazyVim itself
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Import any additional plugins here
    -- { import = "plugins" },
  },
  defaults = {
    lazy = false, -- Don't lazy-load by default
    version = false, -- Don't use version tags
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true }, -- Automatically check for plugin updates
  performance = {
    rtp = {
      -- Disable some rtp plugins that we don't need
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
