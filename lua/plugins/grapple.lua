return {
	"cbochs/grapple.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		scope = "git",
	},
	keys = {
		{ "<leader>ha", "<cmd>Grapple toggle<cr>",       desc = "Grapple: add/toggle tag" },
		{ "<leader>hh", "<cmd>Grapple toggle_tags<cr>",  desc = "Grapple: show tags" },
		{ "<leader>1",  "<cmd>Grapple select index=1<cr>", desc = "Grapple select 1" },
		{ "<leader>2",  "<cmd>Grapple select index=2<cr>", desc = "Grapple select 2" },
		{ "<leader>3",  "<cmd>Grapple select index=3<cr>", desc = "Grapple select 3" },
		{ "<leader>4",  "<cmd>Grapple select index=4<cr>", desc = "Grapple select 4" },
	},
}
