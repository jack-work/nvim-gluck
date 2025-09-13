return {
	"VonHeikemen/lsp-zero.nvim",
	branch = "v2.x",
	dependencies = {
		-- LSP Support
		{ "neovim/nvim-lspconfig" }, -- Required
		{              -- Optional
			"williamboman/mason.nvim",
			build = function()
				pcall(vim.cmd, "MasonUpdate")
			end,
		},
		{ "williamboman/mason-lspconfig.nvim" }, -- Optional

		-- Autocompletion
		{ "hrsh7th/nvim-cmp" }, -- Required
		{ "hrsh7th/cmp-nvim-lsp" }, -- Required
		{ "L3MON4D3/LuaSnip" }, -- Required
		{ "rafamadriz/friendly-snippets" },
		{ "hrsh7th/cmp-buffer" },
		{ "hrsh7th/cmp-path" },
		{ "hrsh7th/cmp-cmdline" },
		{ "saadparwaiz1/cmp_luasnip" },
	},
	config = function()
		local lsp = require("lsp-zero")

		lsp.on_attach(function(client, bufnr)
			local opts = { buffer = bufnr, remap = false }

			vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end,
				vim.tbl_deep_extend("force", opts, { desc = "LSP Goto Reference" }))
			vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end,
				vim.tbl_deep_extend("force", opts, { desc = "LSP Goto Definition" }))
			vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end,
				vim.tbl_deep_extend("force", opts, { desc = "LSP Hover" }))
			vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end,
				vim.tbl_deep_extend("force", opts, { desc = "LSP Workspace Symbol" }))
			vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.setloclist() end,
				vim.tbl_deep_extend("force", opts, { desc = "LSP Show Diagnostics" }))
			vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end,
				vim.tbl_deep_extend("force", opts, { desc = "LSP Code Action" }))
			vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end,
				vim.tbl_deep_extend("force", opts, { desc = "LSP References" }))
			vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end,
				vim.tbl_deep_extend("force", opts, { desc = "LSP Rename" }))
			vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end,
				vim.tbl_deep_extend("force", opts, { desc = "LSP Signature Help" }))
		end)

		require("mason").setup({})
		require("mason-lspconfig").setup({
			ensure_installed = {
				"gopls",
			},
			handlers = {
				lsp.default_setup,
				lua_ls = function()
					local lua_opts = lsp.nvim_lua_ls()
					require("lspconfig").lua_ls.setup(lua_opts)
				end,
			},
		})
	end,
}
