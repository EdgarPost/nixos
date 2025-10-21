-- Neovim options
-- These are basic settings for how Neovim behaves

local opt = vim.opt

-- Line numbers
opt.number = true          -- Show line numbers
opt.relativenumber = true  -- Show relative line numbers (great for vim motions)

-- Indentation
opt.tabstop = 2           -- Number of spaces a tab counts for
opt.shiftwidth = 2        -- Number of spaces for each indent
opt.expandtab = true      -- Use spaces instead of tabs
opt.smartindent = true    -- Auto-indent new lines

-- Search
opt.ignorecase = true     -- Ignore case when searching
opt.smartcase = true      -- Unless the search contains uppercase

-- Appearance
opt.termguicolors = true  -- True color support
opt.signcolumn = "yes"    -- Always show sign column (prevents text shifting)
opt.wrap = false          -- Don't wrap lines
opt.scrolloff = 8         -- Keep 8 lines above/below cursor

-- Splits
opt.splitbelow = true     -- Horizontal splits go below
opt.splitright = true     -- Vertical splits go right

-- Backup and undo
opt.backup = false        -- Don't create backup files
opt.swapfile = false      -- Don't create swap files
opt.undofile = true       -- Enable persistent undo

-- Clipboard
opt.clipboard = "unnamedplus"  -- Use system clipboard

-- Other
opt.updatetime = 250      -- Faster completion
opt.timeoutlen = 300      -- Faster key sequence completion
