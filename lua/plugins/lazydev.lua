return {
	{
		"folke/lazydev.nvim",
		ft = "lua", -- Only loads for .lua files
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },

				{ path = "snacks.nvim",        words = { "Snacks" } },
			}
		},
	},
}
