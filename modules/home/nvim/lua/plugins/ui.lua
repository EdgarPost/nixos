return {
	-- Disable neo-tree (using yazi instead)
	{ "nvim-neo-tree/neo-tree.nvim", enabled = false },

	-- Disable indent guides
	{ "lukas-reineke/indent-blankline.nvim", enabled = false },

	-- Disable all animations (mini.animate)
	{ "nvim-mini/mini.animate", enabled = false },

	-- Disable snacks.nvim scroll animation + show hidden files in picker
	{
		"folke/snacks.nvim",
		opts = {
			scroll = { enabled = false },
			picker = {
				sources = {
					files = {
						hidden = true,
					},
					grep = {
						hidden = true,
					},
				},
			},
		},
	},
}
