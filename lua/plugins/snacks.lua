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
				header = table.concat(vim.fn.readfile(vim.fn.stdpath("config") .. "/header"), "\n")
			}
		},
		explorer = { enabled = true }, -- File explorer
		indent = { enabled = true }, -- Indent guides
		input = { enabled = true }, -- Better vim.ui.input
		notifier = {
			enabled = true,
			timeout = 3000,
			margin = { top = 0, right = 1, bottom = 0 },
			style = "fancy",
			top_down = false,
		},
		picker = { enabled = true }, -- Fuzzy finder (like Telescope)
		quickfile = { enabled = true }, -- Fast file loading
		scope = { enabled = true }, -- Scope highlighting
		scroll = { enabled = true }, -- Smooth scrolling
		statuscolumn = { enabled = true }, -- Enhanced status column
		words = { enabled = true }, -- Highlight word under cursor
		animate = { enabled = false }, -- Animations

		-- Lazygit integration
		lazygit = {
			configure = true, -- let snacks write nvim-remote + theme into lazygit's config
			config = {
				os = { editPreset = "nvim-remote" },
				gui = {
					nerdFontsVersion = "3",
					border = "rounded",
				},
			},
		},

		terminal = {
			win = {
				style = "minimal",
				border = "rounded",
				title_pos = "center",
			},
		},

		-- Not listed here, on purpose: zen, scratch, rename, bufdelete,
		-- gitbrowse, git.blame_line. Those are on-demand APIs, not modules with
		-- setup() side effects — snacks loads them the moment you call them, so
		-- an `enabled` flag is meaningless. The old `zen = { enabled = false }`
		-- sat next to a <leader>z keymap that calls Snacks.zen(); the keymap
		-- worked, which is what made the flag look load-bearing.
		--
		-- Removed as fabricated: `command`/`palette`, `breadcrumbs`,
		-- `statusline`, `git.blame_line`, `git.browse`, `styles.breadcrumbs`.
		-- snacks.nvim has no such options. Unknown keys are silently ignored,
		-- so this config had been doing nothing for as long as it existed —
		-- compare `ls ~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/` against
		-- anything you are about to add here.

		styles = {
			notification = {
				wo = { wrap = true }, -- Wrap notifications
			},
		},
	},

	-- Essential keybindings for snacks.nvim
	keys = {
		-- ─── Picker (replaces fzf-lua) ─────────────────────────────────
		{ "<leader>ff", function() Snacks.picker.files() end,            desc = "Find files" },
		{ "<leader>fg", function() Snacks.picker.grep() end,             desc = "Live grep (cwd)" },
		{ "<leader>fb", function() Snacks.picker.buffers() end,          desc = "Find buffers" },
		{ "<leader>fl", function() Snacks.picker.grep_buffers() end,     desc = "Grep open buffers" },
		{ "<leader>f/", function() Snacks.picker.lines() end,            desc = "Search current buffer lines" },
		{ "<leader>fk", function() Snacks.picker.keymaps() end,          desc = "Find keymaps" },
		{ "<leader>fr", function() Snacks.picker.recent() end,           desc = "Recent files" },
		{ "<leader>fh", function() Snacks.picker.help() end,             desc = "Help tags" },
		{ "<leader>fc", function() Snacks.picker.commands() end,         desc = "Commands" },
		{
			"<leader>ft",
			function()
				vim.ui.input({ prompt = "Glob? " }, function(glob)
					if not glob or glob == "" then return end
					vim.ui.input({ prompt = "Grep for? " }, function(input)
						if not input or input == "" then return end
						Snacks.picker.grep({ args = { "-g", glob }, search = input })
					end)
				end)
			end,
			desc = "Grep with glob filter",
		},

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
		{ "]]",         function() Snacks.words.jump(vim.v.count1) end,  desc = "Next Reference",              mode = { "n" } },
		{ "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference",              mode = { "n" } },
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

	-- No `config` function needed: lazy.nvim calls require("snacks").setup(opts)
	-- for us. The block that used to live here was a commented-out lualine
	-- recipe calling snacks.statusline.breadcrumbs() / .git_status(), which are
	-- not part of snacks either. If you want a breadcrumb in lualine, the
	-- working options are nvim-navic or lualine's own `filename` with path=3.
}