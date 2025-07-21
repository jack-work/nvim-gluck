return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false, -- Important: snacks needs to load early
	---@type snacks.Config
	opts = {
		-- Enable the plugins you want
		bigfile = { enabled = true }, -- Optimize for large files
		dashboard = {
			enabled = true,
			sections = {
				{ section = "header" },
				{ section = "keys",   gap = 1, padding = 1 },
				{ section = "startup" },
			},
			preset = {
				header = [[
.               $$$                                 /         .
.                $$$                              $/          .
.                 $$                              $$          .
.                 $$                              $$          .
.                 $$                              $$          .
.      /$$$       $$    $$     $$        /$$$     $$  /$$     .
.     /  $$$  /   $$     $$     $$  /   / $$$  /  $$ / $$$    .
.    /    $$$/    $$     $$      $$/   /   $$$/   $$/   /     .
.   $$     $$     $$     $$      $$   $$          $$   /      .
.   $$     $$     $$     $$      $$   $$          $$  /       .
.   $$     $$     $$     $$      $$   $$          $$ $$       .
.   $$     $$     $$     $$      $$   $$          $$$$$$      .
.   $$     $$     $$     $$      /$   $$$     /   $$  $$$     .
.    $$$$$$$$     $$$ /   $$$$$$/ $$   $$$$$$/    $$   $$$ /  .
.      $$$ $$$     $$/     $$$$$   $$   $$$$$      $$   $$/   .
.           $$$                                               .
.     $$$$   $$$                                              .
.   /$$$$$$  /$                                               .
.  /     $$$/                                                 .]]
			}
		},
		explorer = { enabled = true }, -- File explorer
		indent = { enabled = true }, -- Indent guides
		input = { enabled = true }, -- Better vim.ui.input
		notifier = {
			enabled = true,
			timeout = 3000,
			margin = { top = 0, right = 1, bottom = 0 },
			style = "compact",
		},
		picker = { enabled = true }, -- Fuzzy finder (like Telescope)
		quickfile = { enabled = true }, -- Fast file loading
		scope = { enabled = true }, -- Scope highlighting
		scroll = { enabled = true }, -- Smooth scrolling
		statuscolumn = { enabled = true }, -- Enhanced status column
		words = { enabled = true }, -- Highlight word under cursor

		-- NEW ENHANCEMENTS
		-- Better command mode with command palette
		command = {
			enabled = true,
			-- Command palette for better command discovery
			palette = {
				enabled = true,
				auto_show = false, -- Show automatically when typing commands
			}
		},

		-- Function hierarchy breadcrumbs
		breadcrumbs = {
			enabled = true,
			-- Show current function/class context
			separator = " › ",
			style = "float", -- or "inline"
			auto_hide = false,
		},

		-- Lazygit integration
		lazygit = {
			enabled = true,
			-- Configuration for lazygit integration
			configure = true, -- Let snacks configure lazygit for better integration
			-- Custom lazygit config
			config = {
				os = { editPreset = "nvim-remote" },
				gui = {
					nerdFontsVersion = "3",
					border = "rounded"
				}
			},
		},

		-- Git integration enhancements
		git = {
			enabled = true,
			-- Enhanced git features
			blame_line = { enabled = true },
			browse = { enabled = true },
		},

		-- Lualine integration components
		statusline = {
			enabled = true,
			-- Components that can be used in lualine
			sections = {
				breadcrumbs = true,
				git_status = true,
				diagnostics = true,
			}
		},

		-- Enhanced terminal for lazygit and other tools
		terminal = {
			enabled = true,
			-- Better terminal integration
			win = {
				style = "minimal",
				border = "rounded",
				title_pos = "center",
			}
		},

		-- Optional plugins (enable as needed)
		animate = { enabled = false }, -- Animations
		zen = { enabled = false }, -- Zen mode

		-- Styling
		styles = {
			notification = {
				wo = { wrap = true } -- Wrap notifications
			},
			breadcrumbs = {
				-- Style for breadcrumbs
				wo = { winblend = 10 },
				border = "rounded",
			}
		},
	},

	-- Essential keybindings for snacks.nvim
	keys = {
		{ "<leader>z",  function() Snacks.zen() end,                     desc = "Toggle Zen Mode" },
		{ "<leader>Z",  function() Snacks.zen.zoom() end,                desc = "Toggle Zoom" },
		{ "<leader>sc", function() Snacks.scratch() end,                 desc = "Toggle Scratch Buffer" },
		{ "<leader>S",  function() Snacks.scratch.select() end,          desc = "Select Scratch Buffer" },
		{ "<leader>n",  function() Snacks.notifier.show_history() end,   desc = "Notification History" },
		{ "<leader>bd", function() Snacks.bufdelete() end,               desc = "Delete Buffer" },
		{ "<leader>cR", function() Snacks.rename.rename_file() end,      desc = "Rename File" },
		{ "<leader>gB", function() Snacks.gitbrowse() end,               desc = "Git Browse",                  mode = { "n", "v" } },
		{ "<leader>gb", function() Snacks.git.blame_line() end,          desc = "Git Blame Line" },
		{ "<leader>gf", function() Snacks.lazygit.log_file() end,        desc = "Lazygit Current File History" },
		{ "<leader>gg", function() Snacks.lazygit() end,                 desc = "Lazygit" },
		{ "<leader>gl", function() Snacks.lazygit.log() end,             desc = "Lazygit Log (cwd)" },
		{ "<leader>un", function() Snacks.notifier.hide() end,           desc = "Dismiss All Notifications" },
		{ "<c-/>",      function() Snacks.terminal() end,                desc = "Toggle Terminal" },
		{ "<c-_>",      function() Snacks.terminal() end,                desc = "which_key_ignore" },
		{ "]]",         function() Snacks.words.jump(vim.v.count1) end,  desc = "Next Reference",              mode = { "n", "t" } },
		{ "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference",              mode = { "n", "t" } },
		{
			"<leader>N",
			desc = "Neovim News",
			function()
				Snacks.win({
					file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
					width = 0.6,
					height = 0.6,
					wo = {
						spell = false,
						wrap = false,
						signcolumn = "yes",
						statuscolumn = " ",
						conceallevel = 3,
					},
				})
			end,
		}
	},

	-- OPTIONAL: If you're using lualine, add this configuration
	config = function(_, opts)
		require("snacks").setup(opts)

		-- Lualine integration example
		-- Add this to your lualine config:
		--[[
		require('lualine').setup({
			sections = {
				lualine_c = {
					{
						function() return require("snacks").statusline.breadcrumbs() end,
						cond = function() return require("snacks").statusline.has_breadcrumbs() end,
					}
				},
				lualine_x = {
					{
						function() return require("snacks").statusline.git_status() end,
						cond = function() return require("snacks").statusline.has_git() end,
					}
				},
			}
		})
		--]]
	end,
}
