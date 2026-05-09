return {
	"jack-work/tree-bear.nvim",
	keys = {
		{
			"<leader>gWt",
			function()
				require("tree-bear").track_worktree()
			end,
			mode = { "n", "v" },
			desc = "Format",
		},
		{
			"<leader>gWn",
			function()
				require("tree-bear").new_worktree()
			end,
			mode = { "n", "v" },
			desc = "Format",
		},
		{
			"<leader>gw",
			function()
				require("tree-bear").lazygit_worktree()
			end,
			mode = { "n", "v" },
			desc = "Format",
		},

	},

}
