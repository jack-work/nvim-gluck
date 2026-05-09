return {
	"NeogitOrg/neogit",
	lazy = true,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"sindrets/diffview.nvim",

		-- Only one of these is needed.
		"nvim-telescope/telescope.nvim", -- optional
		"ibhagwan/fzf-lua", -- optional
		"nvim-mini/mini.pick", -- optional
		"folke/snacks.nvim", -- optional
	},
	cmd = "Neogit",
	keys = {
		{ "<leader>bg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" }
	}
}
