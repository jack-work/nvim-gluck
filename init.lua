require("config.lazy")

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
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Navigate to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Navigate to window below" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Navigate to window above" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Navigate to right window" })

-- Window resizing with Ctrl+Alt+hjkl
vim.keymap.set("n", "<C-A-h>", "<C-w><", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-A-j>", "<C-w>-", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-A-k>", "<C-w>+", { desc = "Increase window height" })
vim.keymap.set("n", "<C-A-l>", "<C-w>>", { desc = "Increase window width" })

-- Clear search highlighting with <leader><leader>
vim.keymap.set("n", "<leader><leader>", ":noh<CR>", { desc = "Clear search highlighting", silent = true })
vim.keymap.set("n", "<leader>bd", ":bp|bd #!<CR>", { desc = "Deletes the current buffer" })
