-- LazyVim bootstrap configuration
-- This is the entry point for Neovim configuration

-- LazyVim will automatically set up everything you need
-- including LSP, treesitter, autocompletion, and more

-- Bootstrap lazy.nvim (the plugin manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load LazyVim
require("config.lazy")
require("config.options")
require("config.keymaps")
