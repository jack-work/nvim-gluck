-- ccc.nvim — inline colour highlighting and a colour picker.
--
-- Was loading eagerly and costing 3.15 ms of every startup, including the
-- startups where no file with a colour in it was ever opened. It only has
-- anything to do in filetypes that carry colour literals, so load it there.
--
-- `auto_enable` starts the highlighter when a buffer of one of these types is
-- opened, which is the behaviour the eager load was really providing.
return {
	"uga-rosa/ccc.nvim",
	ft = {
		"css", "scss", "less", "sass", "html", "vue", "svelte", "astro",
		"javascript", "javascriptreact", "typescript", "typescriptreact",
		"lua", "toml", "yaml", "json", "conf", "dosini", "xdefaults",
	},
	cmd = { "CccPick", "CccConvert", "CccHighlighterToggle", "CccHighlighterEnable" },
	keys = {
		{ "<leader>uc", "<cmd>CccPick<cr>", desc = "Pick colour (ccc)" },
	},
	-- `opts` must be a *function*. lazy.nvim evaluates every spec file during
	-- startup, so a plain table containing require("ccc.input.rgb") would run
	-- those requires immediately — pulling ccc in eagerly (the thing we are
	-- trying to avoid) and erroring besides, since ccc is not on the runtimepath
	-- until it loads. As a function, the body runs at load time instead.
	opts = function()
		return {
			highlighter = {
				auto_enable = true,
				lsp = true,
			},
			-- These restate ccc's own defaults; kept because they document
			-- what the picker cycles through.
			inputs = {
				require("ccc.input.rgb"),
				require("ccc.input.hsl"),
				require("ccc.input.cmyk"),
			},
			outputs = {
				require("ccc.output.hex"),
				require("ccc.output.css_rgb"),
				require("ccc.output.css_hsl"),
			},
			pickers = {
				require("ccc.picker.hex"),
				require("ccc.picker.css_rgb"),
				require("ccc.picker.css_hsl"),
			},
		}
	end,
}
