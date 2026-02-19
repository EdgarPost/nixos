return {
	-- Disable neo-tree (using yazi instead)
	{ "nvim-neo-tree/neo-tree.nvim", enabled = false },

	-- Disable indent guides
	{ "lukas-reineke/indent-blankline.nvim", enabled = false },

	-- Disable all animations (mini.animate)
	{ "nvim-mini/mini.animate", enabled = false },

	-- snacks.nvim overrides
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			opts.scroll = { enabled = false }
			opts.picker = {
				sources = {
					files = { hidden = true },
					grep = { hidden = true },
				},
			}
			opts.dashboard = {
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
					{ section = "startup" },
					{
						pane = 2,
						icon = " ",
						title = "Recent Files",
						section = "recent_files",
						cwd = true,
						hidden = true,
						indent = 2,
						padding = 1,
					},
					{
						pane = 2,
						icon = " ",
						title = "Git Status",
						section = "terminal",
						enabled = function()
							return Snacks.git.get_root() ~= nil
						end,
						cmd = "git status --short --branch --renames",
						height = 5,
						padding = 1,
						ttl = 5 * 60,
						indent = 3,
					},
				},
			}
		end,
	},
}
