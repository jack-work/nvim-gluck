return {
	"saghen/blink.cmp",
	version = "2.*",
	-- Completion is not needed until you are typing into something. This is
	-- the pattern LazyVim uses: InsertEnter covers buffer completion,
	-- CmdlineEnter covers `:` completion, and between them there is no moment
	-- where blink is wanted but absent. Loading eagerly cost 3.75 ms, plus
	-- LuaSnip (1.89 ms) and friendly-snippets, which come along as dependencies.
	event = { "InsertEnter", "CmdlineEnter" },
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
		-- Cmdline: blink v2 enables completion here BY DEFAULT and inherits
		-- auto_insert, which rewrites `:term` into `:terminal` as you type.
		-- Keep the menu available on <Tab>, but never rewrite what was typed.
		cmdline = {
			completion = {
				list = { selection = { preselect = false, auto_insert = false } },
				menu = { auto_show = false },
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
