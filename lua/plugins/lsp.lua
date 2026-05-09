return {
	-- LSP Server Management
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = {
			{ "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" }
		},
		opts = {
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗"
				}
			}
		},
	},

	-- LSP Configuration
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		opts = {
			-- Enable inlay hints globally
			inlay_hints = { enabled = true },

			-- Configure diagnostics
			diagnostics = {
				underline = true,
				update_in_insert = false,
				virtual_text = {
					spacing = 4,
					source = "if_many",
					prefix = "●",
				},
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "✘",
						[vim.diagnostic.severity.WARN] = "▲",
						[vim.diagnostic.severity.HINT] = "⚑",
						[vim.diagnostic.severity.INFO] = "»",
					},
				},
			},

			-- LSP servers to install and configure
			servers = {
				lua_ls = {
					settings = {
						Lua = {
							workspace = { checkThirdParty = false },
							codeLens = { enable = true },
							completion = { callSnippet = "Replace" },
							diagnostics = { globals = { "vim" } },
							hint = { enable = true },
						},
					},
				},

				-- Add more servers as needed
				-- bashls = {},
				-- pyright = {},
				-- tsserver = {},
				-- rust_analyzer = {},
			},
		},

		config = function(_, opts)
			local lspconfig = require("lspconfig")

			-- Configure diagnostics
			vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

			-- Enhanced capabilities with completion support
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				require("cmp_nvim_lsp").default_capabilities()
			)

			-- Setup function for servers
			local function setup(server)
				local server_opts = vim.tbl_deep_extend("force", {
					capabilities = vim.deepcopy(capabilities),
				}, opts.servers[server] or {})

				lspconfig[server].setup(server_opts)
			end

			-- Auto-install and setup servers
			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_keys(opts.servers),
				handlers = { setup },
			})

			-- LSP Keybindings (set when LSP attaches to buffer)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					local opts = { buffer = ev.buf, silent = true }

					-- Core navigation
					vim.keymap.set("n", "gd", vim.lsp.buf.definition,
						vim.tbl_extend("force", opts, { desc = "Go to definition" }))
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration,
						vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation,
						vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
					vim.keymap.set("n", "gt", vim.lsp.buf.type_definition,
						vim.tbl_extend("force", opts, { desc = "Go to type definition" }))

					-- References and symbols
					vim.keymap.set("n", "gr", vim.lsp.buf.references,
						vim.tbl_extend("force", opts, { desc = "Show references" }))
					vim.keymap.set("n", "<leader>ds", vim.lsp.buf.document_symbol,
						vim.tbl_extend("force", opts, { desc = "Document symbols" }))
					vim.keymap.set("n", "<leader>ws", vim.lsp.buf.workspace_symbol,
						vim.tbl_extend("force", opts, { desc = "Workspace symbols" }))

					-- Code actions and refactoring
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action,
						vim.tbl_extend("force", opts, { desc = "Code action" }))
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,
						vim.tbl_extend("force", opts, { desc = "Rename symbol" }))

					-- Formatting handled by conform.nvim (see conform.lua)

					-- Hover and help
					vim.keymap.set("n", "K", vim.lsp.buf.hover,
						vim.tbl_extend("force", opts, { desc = "Show hover info" }))
					vim.keymap.set("n", "<C-s>", vim.lsp.buf.signature_help,
						vim.tbl_extend("force", opts, { desc = "Signature help" }))

					-- Diagnostics
					vim.keymap.set("n", "[d", vim.diagnostic.goto_prev,
						vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
					vim.keymap.set("n", "]d", vim.diagnostic.goto_next,
						vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
					vim.keymap.set("n", "gl", vim.diagnostic.open_float,
						vim.tbl_extend("force", opts, { desc = "Show line diagnostics" }))
					vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist,
						vim.tbl_extend("force", opts, { desc = "Add diagnostics to loclist" }))

					-- Inlay hints toggle (Neovim 0.10+)
					if vim.lsp.inlay_hint then
						vim.keymap.set("n", "<leader>ih", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
						end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))
					end
				end,
			})

			-- Auto-format on save for specific filetypes
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = { "*.lua", "*.py", "*.js", "*.ts", "*.rs" },
				callback = function()
					if vim.b.disable_format_on_save then
						return
					end
					vim.lsp.buf.format({ async = false })
				end,
			})
		end,
	},

	-- Mason-LSPConfig Bridge
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "mason.nvim" },
		opts = {
			automatic_installation = true,
		},
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
			}
			local installed = require("nvim-treesitter.config").get_installed()
			local missing = vim.iter(ensure):filter(function(p)
				return not vim.tbl_contains(installed, p)
			end):totable()
			if #missing > 0 then
				require("nvim-treesitter").install(missing)
			end

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
					if lang and pcall(vim.treesitter.start, args.buf, lang) then
						vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			local move = require("nvim-treesitter-textobjects.move")
			local map = function(lhs, fn, q)
				vim.keymap.set({ "n", "x", "o" }, lhs, function() fn(q) end)
			end
			map("]f", move.goto_next_start, "@function.outer")
			map("]c", move.goto_next_start, "@class.outer")
			map("]F", move.goto_next_end, "@function.outer")
			map("]C", move.goto_next_end, "@class.outer")
			map("[f", move.goto_previous_start, "@function.outer")
			map("[c", move.goto_previous_start, "@class.outer")
			map("[F", move.goto_previous_end, "@function.outer")
			map("[C", move.goto_previous_end, "@class.outer")
		end,
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		opts = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			return {
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },
				mapping = cmp.mapping.preset.insert({
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "lazydev", group_index = 0 },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),
				formatting = {
					format = function(entry, vim_item)
						vim_item.menu = ({
							nvim_lsp = "[LSP]",
							luasnip = "[Snippet]",
							buffer = "[Buffer]",
							path = "[Path]",
						})[entry.source.name]
						return vim_item
					end,
				},
			}
		end,
	},
}
