return {
	"saghen/blink.cmp",
	version = "2.*",
	build = function()
		-- v2 uses Lua-driven build instead of cargo
		require("blink.cmp").build():wait(60000)
	end,
	dependencies = {
		"saghen/blink.lib",
		"rafamadriz/friendly-snippets",
		"L3MON4D3/LuaSnip",
	},
	opts = {
		keymap = {
			preset = "default",
			["<C-f>"] = { "select_and_accept" },
			["<C-b>"] = {},
			["<C-d>"] = { "scroll_documentation_down", "fallback" },
			["<C-u>"] = { "scroll_documentation_up", "fallback" },
		},
		appearance = { nerd_font_variant = "mono" },
		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 200 },
			menu = { border = "rounded" },
			list = {
				selection = { preselect = true, auto_insert = true },
			},
		},
		signature = { enabled = true },
		snippets = { preset = "luasnip" },
		sources = {
			default = { "lsp", "path", "snippets", "buffer", "lazydev" },
			providers = {
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 100,
				},
			},
		},
	},
	opts_extend = { "sources.default" },
}
