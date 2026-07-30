return {
	'rebelot/kanagawa.nvim',
	lazy = false,
	priority = 1000,
	config = function()
		require('kanagawa').setup({
			transparent = true,
			terminalColors = true,
			theme = 'dragon',
			undercurl = true,
			keywordStyle = { italic = true },
		})
		vim.cmd.colorscheme('kanagawa')
	end
}
