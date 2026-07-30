return {
	'stevearc/oil.nvim',
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {
		columns = {
			"icon",
			"size",
			"mtime",
		},
		view_options = {
			show_hidden = true,
		},
		keymaps = {
			["g."] = { "actions.toggle_hidden", mode = "n" },
			["<C-h>"] = false,
			["<C-l>"] = false,
			["<leader>oh"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
			["<leader>or"] = "actions.refresh",
			["<leader>op"] = {
				callback = function()
					local oil = require("oil")
					local path = oil.get_current_dir() .. oil.get_cursor_entry().name
					vim.fn.setreg("+", path)
					vim.notify("Copied: " .. path)
				end,
				desc = "Copy file path",
			},
		},
	},
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	lazy = false,
	keys = {
		{ "<leader>-",  ":Oil<CR>",                                                                     desc = "Open parent directory" },
		{ "<leader>jn", function() require("oil").open(vim.env.HOME .. "/notes") end,                   desc = "Jump: ~/notes" },
		{ "<leader>jh", function() require("oil").open(vim.env.HOME) end,                               desc = "Jump: home" },
		{ "<leader>jc", function() require("oil").open(vim.env.HOME .. "/.config") end,                 desc = "Jump: ~/.config" },
		{ "<leader>jl", function() require("oil").open(vim.env.HOME .. "/.local") end,                  desc = "Jump: ~/.local" },
		{ "<leader>jd", function() require("oil").open(vim.env.HOME .. "/dev") end,                     desc = "Jump: ~/dev" },
		{ "<leader>jD", function() require("oil").open(vim.env.HOME .. "/Downloads") end,               desc = "Jump: ~/Downloads" },
		{ "<leader>jp", function() require("oil").open(vim.fn.stdpath("config") .. "/lua/plugins") end, desc = "Jump: nvim plugins" },

		{
			"<leader>fif",
			function()
				local oil = require("oil")
				local path = (oil.get_cursor_entry() or {}).path or oil.get_current_dir() or
				    vim.fn.expand('%:p:h')
				Snacks.picker.files({ cwd = path })
			end,
			desc = "Find files in oil/buffer dir",
		},
		{
			"<leader>fig",
			function()
				local oil = require("oil")
				local path = (oil.get_cursor_entry() or {}).path or oil.get_current_dir() or
				    vim.fn.expand('%:p:h')
				Snacks.picker.grep({ cwd = path })
			end,
			desc = "Grep in oil/buffer dir",
		},
	},
}
