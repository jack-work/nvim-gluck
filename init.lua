-- Use OSC 52 for clipboard (works locally on Wayland and over SSH/tmux)
vim.g.clipboard = {
	name = 'OSC 52',
	copy = {
		['+'] = require('vim.ui.clipboard.osc52').copy('+'),
		['*'] = require('vim.ui.clipboard.osc52').copy('*'),
	},
	paste = {
		['+'] = require('vim.ui.clipboard.osc52').paste('+'),
		['*'] = require('vim.ui.clipboard.osc52').paste('*'),
	},
}

require("config.lazy")

-- case settings
vim.o.smartcase = true
vim.o.ignorecase = true

-- Trust project-local .nvim.lua files
vim.o.exrc = true

-- Add this to your init.lua
vim.opt.termguicolors = true

-- Fix for tmux specifically
if vim.env.TMUX then
	vim.opt.termguicolors = true
end

-- Line numbers
vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers

-- Clipboard
vim.opt.clipboard = "unnamedplus" -- Use system clipboard

-- Window navigation with Ctrl+hjkl
-- vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Navigate to left window" })
-- vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Navigate to window below" })
-- vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Navigate to window above" })
-- vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Navigate to right window" })

-- Swap buffers between splits with Ctrl+Alt+hjkl (smart-splits handles this in tmux.lua)

-- Clear search highlighting with <leader><leader>
vim.keymap.set("n", "<leader><leader>", ":noh<CR>", { desc = "Clear search highlighting", silent = true })
vim.keymap.set("n", "<leader>bd", ":bp|bd #!<CR>", { desc = "Deletes the current buffer" })

vim.keymap.set('n', '<leader>date', function()
	vim.api.nvim_put({ os.date() }, 'l', true, true)
end)

-- Filetype support for when Neovim or whatever LSP can't figure it out on its own.
vim.filetype.add({
	extension = {
		tf = "terraform",
	}
})

local function generate_guid()
	math.randomseed(os.time() + os.clock() * 1000000)

	local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	local guid = template:gsub('[xy]', function(c)
		local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
		return string.format('%x', v)
	end)

	return guid
end

-- Command to generate GUID and copy to clipboard
vim.api.nvim_create_user_command('GUID', function()
	local guid = generate_guid()
	vim.fn.setreg('"', guid) -- Copy to default register
	vim.fn.setreg('+', guid) -- Copy to system clipboard
	print('GUID copied: ' .. guid)
end, {})

-- Hotkey: <leader>g to generate and copy GUID
vim.keymap.set('n', '<leader>guid', function()
	vim.cmd('GUID')
end, { desc = 'Generate GUID and copy to clipboard' })

-- Copy current file path to clipboard
vim.keymap.set('n', '<leader>op', function()
	local path = vim.fn.expand('%:p')
	vim.fn.setreg('+', path)
	vim.notify('Copied: ' .. path)
end, { desc = 'Copy file path' })
