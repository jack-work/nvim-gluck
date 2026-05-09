return {
	"mrjones2014/smart-splits.nvim",
	lazy = false,
	config = function()
		local smart_splits = require('smart-splits')

		smart_splits.setup({
			-- Tmux integration
			at_edge = 'stop', -- or 'wrap' to cycle through
			multiplexer_integration = 'tmux',
		})

		-- Navigation keymaps (you already have these)
		vim.keymap.set('n', '<C-h>', smart_splits.move_cursor_left, { desc = "Move to left split" })
		vim.keymap.set('n', '<C-j>', smart_splits.move_cursor_down, { desc = "Move to bottom split" })
		vim.keymap.set('n', '<C-k>', smart_splits.move_cursor_up, { desc = "Move to top split" })
		vim.keymap.set('n', '<C-l>', smart_splits.move_cursor_right, { desc = "Move to right split" })

		-- Resizing keymaps
		vim.keymap.set('n', '<M-h>', smart_splits.resize_left, { desc = "Resize split left" })
		vim.keymap.set('n', '<M-j>', smart_splits.resize_down, { desc = "Resize split down" })
		vim.keymap.set('n', '<M-k>', smart_splits.resize_up, { desc = "Resize split up" })
		vim.keymap.set('n', '<M-l>', smart_splits.resize_right, { desc = "Resize split right" })

		-- Swap buffer with adjacent split
		vim.keymap.set('n', '<C-M-h>', smart_splits.swap_buf_left, { desc = "Swap buffer left" })
		vim.keymap.set('n', '<C-M-j>', smart_splits.swap_buf_down, { desc = "Swap buffer down" })
		vim.keymap.set('n', '<C-M-k>', smart_splits.swap_buf_up, { desc = "Swap buffer up" })
		vim.keymap.set('n', '<C-M-l>', smart_splits.swap_buf_right, { desc = "Swap buffer right" })
	end,
}
