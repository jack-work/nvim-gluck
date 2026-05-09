return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
				{ path = "snacks.nvim", words = { "Snacks" } },
				{ path = "lazy.nvim", words = { "LazyVim" } },
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	-- Optional: type stubs for vim.uv
	{ "Bilal2453/luvit-meta", lazy = true },
}
