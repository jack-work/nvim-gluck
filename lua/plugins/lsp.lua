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

					-- Formatting (your requested <leader>fo)
					vim.keymap.set({ "n", "v" }, "<leader>fo", function()
						vim.lsp.buf.format({ async = true })
					end, vim.tbl_extend("force", opts, { desc = "Format code" }))

					-- Hover and help
					vim.keymap.set("n", "K", vim.lsp.buf.hover,
						vim.tbl_extend("force", opts, { desc = "Show hover info" }))
					vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help,
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

	-- Treesitter for enhanced syntax highlighting
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPost", "BufNewFile" },
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		opts = {
			highlight = { enable = true },
			indent = { enable = true },
			ensure_installed = {
				"bash", "c", "html", "javascript", "json", "lua", "luadoc", "luap",
				"markdown", "markdown_inline", "python", "query", "regex", "tsx",
				"typescript", "vim", "vimdoc", "yaml", "go",
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
			textobjects = {
				move = {
					enable = true,
					goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
					goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
					goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
					goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
				},
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
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
