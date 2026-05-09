return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" }, -- Load on save events
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>fo",
			function()
				require("conform").format({ lsp_format = "fallback" })
			end,
			mode = { "n", "v" },
			desc = "Format code",
		},
	},
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				python = { "black" }, -- You can use "ruff_format" instead
				lua = { "stylua" },
				markdown = { "mdformat" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback",
			},
		})
	end,
}
