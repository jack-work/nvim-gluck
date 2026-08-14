return {
	-- Mason. The repo moved from williamboman/ to the mason-org/ organisation
	-- (mason 2.x); GitHub still redirects the old URL, which is why this kept
	-- working, but redirects are not a dependency to rely on.
	{
		"mason-org/mason.nvim",
		cmd = "Mason",
		keys = {
			{ "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" },
		},
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	-- mason-lspconfig: auto-enables installed servers via vim.lsp.enable() (Nvim 0.11+)
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = { "mason.nvim", "neovim/nvim-lspconfig" },
		-- Matches nvim-lspconfig's own trigger. This plugin's whole job is to
		-- call vim.lsp.enable() for installed servers, which only matters once
		-- a real file is open; vim.lsp.enable() registers a FileType autocmd,
		-- and FileType fires after BufReadPre, so the first buffer still gets
		-- its server. Loading it eagerly pulled in mason-core, mason-registry
		-- and mason.nvim for 2.5 ms before any buffer existed.
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			ensure_installed = { "lua_ls", "terraformls", "pyright", "gopls", "taplo" },
			-- rustaceanvim owns rust-analyzer end to end (see plugins/rust.lua).
			-- Letting mason-lspconfig also vim.lsp.enable() it starts a second,
			-- unconfigured client: duplicate diagnostics, duplicate completions,
			-- and none of the rustaceanvim commands.
			automatic_enable = { exclude = { "rust_analyzer" } },
		},
	},

	-- nvim-lspconfig: provides per-server defaults; we layer overrides via vim.lsp.config
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			vim.diagnostic.config({
				underline = true,
				update_in_insert = false,
				virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "✘",
						[vim.diagnostic.severity.WARN]  = "▲",
						[vim.diagnostic.severity.HINT]  = "⚑",
						[vim.diagnostic.severity.INFO]  = "»",
					},
				},
			})

			-- Per-server overrides (merged on top of nvim-lspconfig defaults)
			-- JSON LSP: also attach for jsonl (one JSON value per line).
			-- Note: server validates the whole buffer as JSON, so it WILL complain
			-- about multi-line jsonl files. We disable diagnostics for jsonl and
			-- still keep completion/hover/schema features.
			vim.lsp.config("jsonls", {
				filetypes = { "json", "jsonc", "jsonl" },
			})

			-- Silence the inevitable "expected end of file" diagnostics on jsonl.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "jsonl",
				callback = function(ev)
					vim.diagnostic.enable(false, { bufnr = ev.buf })
				end,
			})

			-- Pyright: point it at the project's real interpreter (nix devShell,
			-- .venv, $VIRTUAL_ENV) instead of the bare system python3. Without
			-- this, flake-only deps show up as reportMissingImports errors.
			vim.lsp.config("pyright", {
				root_markers = { "flake.nix", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
				on_init = function(client)
					local pyenv = require("config.pyenv")
					pyenv.apply(client, pyenv.python(client.root_dir))
				end,
			})

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						workspace = { checkThirdParty = false },
						codeLens = { enable = true },
						completion = { callSnippet = "Replace" },
						diagnostics = { globals = { "vim" } },
						hint = { enable = true },
					},
				},
			})

			-- gopls: the defaults are conservative. These are the settings that
			-- turn it into an actual Go IDE — staticcheck, the analyzers that
			-- catch real bugs (shadow, nilness, unusedwrite), and inlay hints.
			vim.lsp.config("gopls", {
				settings = {
					gopls = {
						gofumpt = true, -- stricter gofmt; what most Go repos use
						staticcheck = true,
						usePlaceholders = true,
						completeUnimported = true,
						semanticTokens = true,
						analyses = {
							nilness = true,
							shadow = true,
							unusedparams = true,
							unusedwrite = true,
							useany = true,
							unusedvariable = true,
						},
						hints = {
							assignVariableTypes = true,
							compositeLiteralFields = true,
							compositeLiteralTypes = true,
							constantValues = true,
							functionTypeParameters = true,
							parameterNames = true,
							rangeVariableTypes = true,
						},
						-- Without this, gopls silently ignores files behind
						-- build tags — the "undefined: Foo" mystery on
						-- //go:build integration files.
						buildFlags = { "-tags=integration" },
						directoryFilters = { "-.git", "-node_modules", "-vendor" },
					},
				},
			})

			-- Go: organize imports on save.
			--
			-- gopls formats via textDocument/formatting (conform's lsp_format
			-- fallback picks that up), but adding and removing imports is a
			-- *code action*, source.organizeImports, which nothing calls
			-- automatically. This is the goimports behaviour everyone expects
			-- from a Go editor and the reason `go build` fails on unused
			-- imports right after you delete a line.
			--
			-- Applied synchronously before conform's own BufWritePre runs, so
			-- the import block is fixed first and then formatted.
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("UserGoImports", { clear = true }),
				pattern = { "*.go" },
				callback = function(ev)
					if vim.g.disable_autoformat or vim.b[ev.buf].disable_autoformat then
						return
					end
					local params = vim.lsp.util.make_range_params(0, "utf-16")
					params.context = { only = { "source.organizeImports" }, diagnostics = {} }
					local results = vim.lsp.buf_request_sync(
						ev.buf, "textDocument/codeAction", params, 1000)
					for client_id, res in pairs(results or {}) do
						for _, action in pairs(res.result or {}) do
							if action.edit then
								local client = vim.lsp.get_client_by_id(client_id)
								vim.lsp.util.apply_workspace_edit(
									action.edit, client and client.offset_encoding or "utf-16")
							end
						end
					end
				end,
			})

			-- LSP keymaps on attach.
			-- Nvim 0.11+ ships native defaults: K, grr, gri, grn, gra, gO, [d, ]d.
			-- Only bind keys that aren't natively covered.
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
				callback = function(ev)
					local buf_opts = { buffer = ev.buf, silent = true }
					local map = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", buf_opts, { desc = desc }))
					end

					map("n", "gd", vim.lsp.buf.definition, "Go to definition")
					map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
					map("n", "grt", vim.lsp.buf.type_definition, "Go to type definition")
					map("n", "<leader>ws", vim.lsp.buf.workspace_symbol, "Workspace symbols")
					map("n", "gl", vim.diagnostic.open_float, "Show line diagnostics")
					map("i", "<C-s>", vim.lsp.buf.signature_help, "Signature help")

					if vim.lsp.inlay_hint then
						map("n", "<leader>uh", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
						end, "Toggle inlay hints")
					end
				end,
			})
		end,
	},

	-- Treesitter (main branch — requires Neovim 0.12+ and tree-sitter-cli)
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ensure = {
				"bash", "c", "html", "javascript", "json", "lua", "luadoc", "luap",
				"markdown", "markdown_inline", "python", "query", "regex", "tsx",
				"typescript", "vim", "vimdoc", "yaml", "go",
				-- Rust + the formats it lives in
				"rust", "toml", "ron",
				-- Go's satellite files (gopls diagnoses these; TS highlights them)
				"gomod", "gosum", "gowork", "gotmpl",
				-- The rest of the daily rotation
				"nix", "terraform", "hcl", "dockerfile", "make",
				"diff", "git_config", "gitcommit", "gitignore",
			}
			local installed = require("nvim-treesitter.config").get_installed()
			local missing = vim.iter(ensure):filter(function(p)
				return not vim.tbl_contains(installed, p)
			end):totable()
			if #missing > 0 then
				require("nvim-treesitter").install(missing)
			end

			vim.opt.foldlevel = 99 -- open files unfolded by default

			-- Use the `json` TS parser for `jsonl` buffers.
			vim.treesitter.language.register("json", "jsonl")

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
					if lang and pcall(vim.treesitter.start, args.buf, lang) then
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
						vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
						vim.wo.foldmethod = "expr"
					end
				end,
			})
		end,
	},

	-- TS textobjects: move (next/prev), select (af/if, ac/ic, aa/ia), swap (params)
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			local move = require("nvim-treesitter-textobjects.move")
			local select = require("nvim-treesitter-textobjects.select")
			local swap = require("nvim-treesitter-textobjects.swap")

			-- Move
			local move_map = function(lhs, fn, q)
				vim.keymap.set({ "n", "x", "o" }, lhs, function() fn(q) end)
			end
			move_map("]f", move.goto_next_start,     "@function.outer")
			move_map("]c", move.goto_next_start,     "@class.outer")
			move_map("]a", move.goto_next_start,     "@parameter.inner")
			move_map("]F", move.goto_next_end,       "@function.outer")
			move_map("]C", move.goto_next_end,       "@class.outer")
			move_map("[f", move.goto_previous_start, "@function.outer")
			move_map("[c", move.goto_previous_start, "@class.outer")
			move_map("[a", move.goto_previous_start, "@parameter.inner")
			move_map("[F", move.goto_previous_end,   "@function.outer")
			move_map("[C", move.goto_previous_end,   "@class.outer")

			-- Select
			local sel_map = function(lhs, q)
				vim.keymap.set({ "x", "o" }, lhs, function()
					select.select_textobject(q, "textobjects")
				end)
			end
			sel_map("af", "@function.outer")
			sel_map("if", "@function.inner")
			sel_map("ac", "@class.outer")
			sel_map("ic", "@class.inner")
			sel_map("aa", "@parameter.outer")
			sel_map("ia", "@parameter.inner")

			-- "n" textobject: smallest TS node under cursor.
			-- Works as an operator target (dan/cin/yan/van).
			-- In visual mode, repeating expands to parent node (Smart Select).
			local function select_ts_node()
				local mode = vim.fn.mode()
				if mode == "v" or mode == "V" then
					-- Already in visual: expand to parent of current selection
					local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
					local sr, sc, er, ec = s[2] - 1, s[3] - 1, e[2] - 1, e[3] - 1
					if sr > er or (sr == er and sc > ec) then
						sr, sc, er, ec = er, ec, sr, sc
					end
					local node = vim.treesitter.get_node({ pos = { sr, sc } })
					while node do
						local nr1, nc1, nr2, nc2 = node:range()
						if nr1 < sr or (nr1 == sr and nc1 < sc)
							or nr2 > er + 1 or (nr2 == er + 1 and nc2 > ec + 1)
						then
							break
						end
						node = node:parent()
					end
					if not node then return end
					local nr1, nc1, nr2, nc2 = node:range()
					vim.cmd("normal! \27")
					vim.api.nvim_win_set_cursor(0, { nr1 + 1, nc1 })
					vim.cmd("normal! v")
					vim.api.nvim_win_set_cursor(0, { nr2 + 1, math.max(nc2 - 1, 0) })
				else
					-- Operator-pending or normal: select smallest enclosing node
					local node = vim.treesitter.get_node()
					if not node then return end
					local sr, sc, er, ec = node:range()
					vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
					vim.cmd("normal! v")
					vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
				end
			end
			vim.keymap.set({ "x", "o" }, "in", select_ts_node, { desc = "TS node (inner/expand)" })
			vim.keymap.set({ "x", "o" }, "an", select_ts_node, { desc = "TS node (around/expand)" })

			-- Swap parameters
			vim.keymap.set("n", "<leader>cs", function()
				swap.swap_next("@parameter.inner")
			end, { desc = "Swap parameter with next" })
			vim.keymap.set("n", "<leader>cS", function()
				swap.swap_previous("@parameter.inner")
			end, { desc = "Swap parameter with previous" })
		end,
	},

}
