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
			{ "<leader>c", group = "code" },
			{ "<leader>f", group = "find/files" },
			{ "<leader>F", group = "figaro", mode = { "n", "v" } },
			{ "<leader>g", group = "git" },
			{ "<leader>h", group = "harpoon (grapple)" },
			{ "<leader>i", group = "insert" },
			{ "<leader>j", group = "jump (filesystem)" },
			{ "<leader>R", group = "http requests" },
			{ "<leader>t", group = "terminal" },
			{ "<leader>u", group = "toggle/UI" },
			{ "<leader>x", group = "diagnostics/trouble" },
		},
	},
	keys = {
		{
			"<leader>?",
			function() require("which-key").show({ global = false }) end,
			desc = "Buffer local keymaps",
		},
	},
}
