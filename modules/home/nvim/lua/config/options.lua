-- Options are automatically loaded before lazy.nvim startup
-- Add any additional options here

vim.opt.relativenumber = true

-- Auto-reload files changed outside of Neovim
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	callback = function()
		vim.cmd("checktime")
	end,
})
