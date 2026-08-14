-- Rust.
--
-- rustaceanvim replaces the plain lspconfig `rust_analyzer` setup — it
-- configures the server itself (do NOT also enable rust_analyzer via
-- mason-lspconfig; see the exclude in lsp.lua) and adds the things that make
-- Rust bearable in an editor: runnables/testables/debuggables pulled from
-- cargo, macro expansion, "go to parent module", grouped code actions, and a
-- hover that offers actions instead of just prose.
--
-- The server binary comes from rustup, not Mason, so it always matches the
-- toolchain that compiles the project:
--     rustup component add rust-analyzer
--
-- Formatting is left to the LSP (conform.lua has no `rust` entry, so its
-- lsp_format="fallback" takes over). That matters: rust-analyzer invokes
-- rustfmt with the crate's edition and rustfmt.toml, whereas a bare `rustfmt`
-- run by conform assumes edition 2015 and mangles `async`/`dyn` code.

return {
	{
		"mrcjkb/rustaceanvim",
		version = "^6",
		lazy = false, -- the plugin lazy-loads itself on the rust filetype
		init = function()
			vim.g.rustaceanvim = {
				tools = {
					float_win_config = { border = "rounded" },
					-- Inline test/run codelens-ish actions come from hover.
				},
				server = {
					on_attach = function(_, bufnr)
						local map = function(lhs, rhs, desc)
							vim.keymap.set("n", lhs, rhs,
								{ buffer = bufnr, silent = true, desc = desc })
						end

						-- Hover with actions (jump to impl, docs, etc.) is
						-- strictly better than the default K here.
						map("K", function() vim.cmd.RustLsp({ "hover", "actions" }) end,
							"Hover actions (Rust)")

						map("<leader>rr", function() vim.cmd.RustLsp("runnables") end,
							"Rust: runnables")
						map("<leader>rt", function() vim.cmd.RustLsp("testables") end,
							"Rust: testables")
						map("<leader>rd", function() vim.cmd.RustLsp("debuggables") end,
							"Rust: debuggables")
						map("<leader>rm", function() vim.cmd.RustLsp("expandMacro") end,
							"Rust: expand macro")
						map("<leader>rc", function() vim.cmd.RustLsp("openCargo") end,
							"Rust: open Cargo.toml")
						map("<leader>rp", function() vim.cmd.RustLsp("parentModule") end,
							"Rust: parent module")
						map("<leader>rD", function() vim.cmd.RustLsp("renderDiagnostic") end,
							"Rust: render diagnostic (full rustc output)")
						map("<leader>re", function() vim.cmd.RustLsp("explainError") end,
							"Rust: explain error (rustc --explain)")
						map("<leader>rJ", function() vim.cmd.RustLsp("joinLines") end,
							"Rust: join lines (syntax aware)")
						map("<leader>rg", function() vim.cmd.RustLsp("crateGraph") end,
							"Rust: crate graph")

						vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
					end,
					default_settings = {
						["rust-analyzer"] = {
							-- Lint with clippy on save, not just rustc. This is
							-- the single biggest quality-of-life win: you get
							-- the idiom warnings in the buffer.
							checkOnSave = true,
							check = {
								command = "clippy",
								extraArgs = { "--no-deps" }, -- don't lint dependencies
							},
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								buildScripts = { enable = true },
							},
							procMacro = {
								enable = true,
								ignored = {
									-- These expand to code r-a can't reason
									-- about and just produce noise.
									["async-trait"] = { "async_trait" },
									["napi-derive"] = { "napi" },
									["async-recursion"] = { "async_recursion" },
								},
							},
							inlayHints = {
								bindingModeHints = { enable = false },
								closureReturnTypeHints = { enable = "with_block" },
								lifetimeElisionHints = { enable = "skip_trivial", useParameterNames = true },
								parameterHints = { enable = true },
								typeHints = { enable = true },
							},
							-- Fill in match arms / struct fields properly.
							completion = {
								callable = { snippets = "fill_arguments" },
								fullFunctionSignatures = { enable = true },
							},
							imports = {
								granularity = { group = "module" },
								prefix = "self",
							},
							files = {
								excludeDirs = { ".direnv", ".git", "target", "node_modules" },
							},
						},
					},
				},
			}
		end,
	},

	-- Cargo.toml: version diagnostics, "upgrade to latest", feature lists,
	-- docs.rs/crates.io links. Runs as an in-process LSP so blink.cmp picks up
	-- crate-name and version completion through the ordinary `lsp` source —
	-- no extra completion wiring needed.
	{
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		opts = {
			completion = {
				crates = { enabled = true },
			},
			lsp = {
				enabled = true,
				actions = true,
				completion = true,
				hover = true,
			},
		},
		config = function(_, opts)
			require("crates").setup(opts)
			vim.api.nvim_create_autocmd("BufRead", {
				group = vim.api.nvim_create_augroup("UserCrates", { clear = true }),
				pattern = "Cargo.toml",
				callback = function(ev)
					local crates = require("crates")
					local map = function(lhs, rhs, desc)
						vim.keymap.set("n", lhs, rhs,
							{ buffer = ev.buf, silent = true, desc = desc })
					end
					map("<leader>ru", crates.upgrade_crate, "Crates: upgrade crate")
					map("<leader>rU", crates.upgrade_all_crates, "Crates: upgrade all")
					map("<leader>rv", crates.show_versions_popup, "Crates: versions")
					map("<leader>rf", crates.show_features_popup, "Crates: features")
					map("<leader>rR", crates.open_repository, "Crates: open repository")
					map("<leader>rh", crates.open_homepage, "Crates: open homepage")
					map("<leader>ro", crates.open_documentation, "Crates: open docs.rs")
				end,
			})
		end,
	},
}
