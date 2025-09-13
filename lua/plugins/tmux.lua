return {
	"mrjones2014/smart-splits.nvim",
	lazy = false, -- IMPORTANT: Don't lazy load this plugin
	config = function()
		local smart_splits = require('smart-splits')

		-- Navigation keymaps
		vim.keymap.set('n', '<C-h>', smart_splits.move_cursor_left, { desc = "Move to left split" })
		vim.keymap.set('n', '<C-j>', smart_splits.move_cursor_down, { desc = "Move to bottom split" })
		vim.keymap.set('n', '<C-k>', smart_splits.move_cursor_up, { desc = "Move to top split" })
		vim.keymap.set('n', '<C-l>', smart_splits.move_cursor_right, { desc = "Move to right split" })
		vim.keymap.set('n', '<C-\\>', smart_splits.move_cursor_previous, { desc = "Move to previous split" })

		-- Resizing keymaps (Alt/Option + hjkl)
		vim.keymap.set('n', '<M-h>', smart_splits.resize_left, { desc = "Resize split left" })
		vim.keymap.set('n', '<M-j>', smart_splits.resize_down, { desc = "Resize split down" })
		vim.keymap.set('n', '<M-k>', smart_splits.resize_up, { desc = "Resize split up" })
		vim.keymap.set('n', '<M-l>', smart_splits.resize_right, { desc = "Resize split right" })
	end,
}
