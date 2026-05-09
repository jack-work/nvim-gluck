return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
		delay = 300,
		icons = {
			breadcrumb = "»",
			separator = "➜",
			group = "+",
		},
		spec = {
			{ "<leader>f", group = "find/files" },
			{ "<leader>g", group = "git" },
			{ "<leader>v", group = "lsp" },
			{ "<leader>R", group = "http requests" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer local keymaps",
		},
	},
}
