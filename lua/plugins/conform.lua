return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo", "FormatDisable", "FormatEnable" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ lsp_format = "fallback" })
			end,
			mode = { "n", "v" },
			desc = "Format buffer/selection",
		},
		{
			"<leader>uf",
			function()
				vim.b.disable_autoformat = not vim.b.disable_autoformat
				vim.notify(
					vim.b.disable_autoformat and "format-on-save: OFF (buffer)" or
					"format-on-save: ON (buffer)",
					vim.log.levels.INFO
				)
			end,
			desc = "Toggle format-on-save (buffer)",
		},
		{
			"<leader>uF",
			function()
				vim.g.disable_autoformat = not vim.g.disable_autoformat
				vim.notify(
					vim.g.disable_autoformat and "format-on-save: OFF (global)" or
					"format-on-save: ON (global)",
					vim.log.levels.INFO
				)
			end,
			desc = "Toggle format-on-save (global)",
		},
	},
	config = function()
		require("conform").setup({
			formatters = {
				-- jsonl: one JSON value per line. `jq -c .` reads all values from
				-- stdin and emits one compact JSON value per output line — exactly
				-- the JSONL convention. Use `jq .` (no -c) if you prefer pretty,
				-- but then it's no longer valid JSONL.
				jq_jsonl = {
					command = "jq",
					args = { "-c", "." },
					stdin = true,
				},
				sqlfluff = {
					args = { 'format', '--dialect', 'mysql', '-' },
				},
			},
			formatters_by_ft = {
				python = { "black" },
				lua = { "stylua" },
				markdown = { "mdformat" },
				jsonl = { "jq_jsonl" },
				sql = { 'sql_formatter' },
				terraform = { "terraform_fmt" },
				hcl = { "terraform_fmt" },
			},
			format_on_save = function(bufnr)
				if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
					return
				end
				return { timeout_ms = 500, lsp_format = "fallback" }
			end,
		})

		-- Match conform's :FormatDisable / :FormatEnable convention
		vim.api.nvim_create_user_command("FormatDisable", function(args)
			if args.bang then
				vim.b.disable_autoformat = true
			else
				vim.g.disable_autoformat = true
			end
		end, { desc = "Disable format-on-save (use ! for buffer-only)", bang = true })

		vim.api.nvim_create_user_command("FormatEnable", function()
			vim.b.disable_autoformat = false
			vim.g.disable_autoformat = false
		end, { desc = "Re-enable format-on-save" })
	end,
}
