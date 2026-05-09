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
			-- Remap the functionality elsewhere if you want it
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
		}
	},
	-- Optional dependencies
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
	-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
	lazy = false,
	keys = { { "<leader>-", ":Oil<CR>", desc = "Open parent directory" },
		{
			"<leader>src",
			function()
				require("oil").open('~/src')
			end,
			desc = "Open src folder"
		},
		{
			"<leader>down",
			function()
				require("oil").open('~/Downloads')
			end,
			desc = "Open Downloads folder"
		},
		{
			"<leader>fif",
			function()
				local oil = require("oil")
				local path = (oil.get_cursor_entry() or {}).path or oil.get_current_dir() or
				    vim.fn.expand('%:p:h')
				require("fzf-lua").files({
					prompt_title = "finding files in the directory of the current buffer",
					cwd = path
				})
			end,
			desc = "Grep in directory"
		},
		{
			"<leader>fig",
			function()
				local oil = require("oil")
				local path = (oil.get_cursor_entry() or {}).path or oil.get_current_dir() or
				    vim.fn.expand('%:p:h')
				require("fzf-lua").live_grep({
					prompt_title = "grepping the directory of the current buffer",
					cwd = path
				})
			end,
			desc = "Grep in directory"
		},
		{
			'<leader>h',
			function()
				local oil = require("oil")
				oil.open('~')
			end
		},
		{
			'<leader>ep',
			function()
				local oil = require("oil")
				oil.open(vim.fn.stdpath('config') .. '/lua/plugins')
			end
		},
		{
			'<leader>conf',
			function() require("oil").open('~/.config') end
		},
		{
			'<leader>local',
			function() require("oil").open('~/.local') end
		},
		{
			'<leader>dev',
			function() require("oil").open('~/dev') end
		},
	},
}
