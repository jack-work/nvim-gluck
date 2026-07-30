-- figaro.nvim is a LOCAL plugin (not published). Guard on its presence so this
-- config loads cleanly on machines that do not have it checked out.
local figaro_dir = vim.fn.expand("~/dev/figaro.nvim")

return {
	dir = figaro_dir,
	name = "figaro.nvim",
	cond = vim.fn.isdirectory(figaro_dir) == 1,
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
