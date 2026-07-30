return {
	dir = vim.fn.expand("~/dev/figaro.nvim"),
	name = "figaro.nvim",
	cmd = { "FigAt", "FigQ", "FigListen", "FigStatus", "FigDetach" },
	opts = {},
	keys = {
		{
			"<leader>Fa",
			function() require("figaro").attend() end,
			desc = "Attend aria (picker)",
		},
		{
			"<leader>Fq",
			function() require("figaro").prompt(false) end,
			desc = "Prompt figaro (compose buffer)",
		},
		{
			"<leader>Fq",
			function() require("figaro").prompt(true) end,
			mode = "v",
			desc = "Send selection to figaro",
		},
		{
			"<leader>Fl",
			function() require("figaro").listen() end,
			desc = "Listen to attended aria",
		},
		{ "<leader>Fs", "<cmd>FigStatus<cr>", desc = "Aria status" },
		{ "<leader>Fd", "<cmd>FigDetach<cr>", desc = "Detach aria" },
	},
}
