-- Key mappings
-- These are custom keyboard shortcuts for Neovim

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Set leader key to space
-- Leader is a prefix key you press before other keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Better window navigation
-- Use Ctrl+h/j/k/l to move between windows
keymap.set("n", "<C-h>", "<C-w>h", opts)
keymap.set("n", "<C-j>", "<C-w>j", opts)
keymap.set("n", "<C-k>", "<C-w>k", opts)
keymap.set("n", "<C-l>", "<C-w>l", opts)

-- Stay in indent mode
-- When indenting in visual mode, stay in visual mode
keymap.set("v", "<", "<gv", opts)
keymap.set("v", ">", ">gv", opts)

-- Move text up and down
-- In visual mode, use J and K to move selected lines
keymap.set("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap.set("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Better paste
-- When pasting over selected text, don't copy the replaced text
keymap.set("v", "p", '"_dP', opts)

-- Clear search highlighting
keymap.set("n", "<leader>h", ":nohlsearch<CR>", opts)

-- Quick save
keymap.set("n", "<leader>w", ":w<CR>", opts)

-- Quick quit
keymap.set("n", "<leader>q", ":q<CR>", opts)

-- LazyVim comes with many more keymaps!
-- Press <leader>? to see all available keymaps
