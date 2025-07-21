return {
	'uga-rosa/ccc.nvim',
	config = function()
		require('ccc').setup({
			highlighter = {
				auto_enable = true,
				lsp = true,
			},
			inputs = {
				require('ccc.input.rgb'),
				require('ccc.input.hsl'),
				require('ccc.input.cmyk'),
			},
			outputs = {
				require('ccc.output.hex'),
				require('ccc.output.css_rgb'),
				require('ccc.output.css_hsl'),
			},
			-- Add custom patterns
			pickers = {
				require('ccc.picker.hex'),
				require('ccc.picker.css_rgb'),
				require('ccc.picker.css_hsl'),
			},
		})
	end
}
