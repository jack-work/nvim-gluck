return {
	"nvim-neorg/neorg",
	dependencies = { "luarocks.nvim", "nvim-lua/plenary.nvim" },
	lazy = false,
	version = "*",
	config = function()
		require("neorg").setup {
			load = {
				["core.defaults"] = {},
				["core.concealer"] = {},
				["core.ui.calendar"] = {},
				["core.dirman"] = {
					config = {
						workspaces = {
							notes = "~/notes",
							journal = "~/journal",
							ml4t = "~/notes/7646.ml4t",
						},
						default_workspace = "notes",
					},
				},
				["core.journal"] = {
					config = {
						strategy = "flat",
						template_name = "template.norg",
						use_template = true,
					},
				},
			},
		}
	end,
	keys = {
		{ "<leader>notes", "<cmd>Neorg index<cr>", desc = "Mason" }
	},
}
