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
		local conform = require("conform")

		-- Formatters live outside the plugin manager (uv tools, pacman, cargo).
		-- When one goes missing, conform logs an error on *every* save. Worse:
		-- a Mason-installed python tool can remain executable while its venv
		-- interpreter has been garbage collected, so `executable()` says yes and
		-- execve still returns ENOENT (bad shebang). Check both, once per
		-- session, and drop the dead ones so lsp_format="fallback" takes over.
		local runnable = {}

		local function is_runnable(cmd)
			if runnable[cmd] ~= nil then
				return runnable[cmd]
			end
			local ok = vim.fn.executable(cmd) == 1
			if ok then
				local first = (vim.fn.readfile(vim.fn.exepath(cmd), "", 1) or {})[1] or ""
				local interp = first:match("^#!%s*(%S+)")
				if interp then
					-- `#!/usr/bin/env foo` — the interpreter is the next word.
					if interp:match("/env$") then
						interp = first:match("^#!%s*%S+%s+(%S+)")
					end
					ok = interp == nil or vim.fn.executable(interp) == 1
				end
			end
			runnable[cmd] = ok
			return ok
		end

		local warned = {}

		-- Wrap a formatter list so unusable entries are filtered at format time.
		local function guard(...)
			local names = { ... }
			return function(bufnr)
				local usable = {}
				for _, name in ipairs(names) do
					local info = conform.get_formatter_info(name, bufnr)
					if info.available and is_runnable(info.command) then
						table.insert(usable, name)
					elseif not warned[name] then
						warned[name] = true
						vim.notify(
							string.format("conform: skipping '%s' (%s)", name,
								info.available_msg or "not runnable"),
							vim.log.levels.WARN
						)
					end
				end
				return usable
			end
		end

		-- Tool installed mid-session? Forget the verdicts.
		vim.api.nvim_create_user_command("FormatRecheck", function()
			runnable, warned = {}, {}
			vim.notify("conform: formatter availability re-checked", vim.log.levels.INFO)
		end, { desc = "Re-check which formatter binaries are runnable" })

		conform.setup({
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
				python = guard("black"),
				lua = guard("stylua"),
				markdown = guard("mdformat"),
				jsonl = guard("jq_jsonl"),
				sql = guard("sql_formatter"),
				terraform = guard("terraform_fmt"),
				hcl = guard("terraform_fmt"),
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
