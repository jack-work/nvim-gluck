return {
	"L3MON4D3/LuaSnip",
	version = "v2.*",
	build = "make install_jsregexp",
	keys = {
		{
			"<C-K>",
			function()
				require("luasnip").expand()
			end,
			mode = "i",
			silent = true,
			desc = "LuaSnip: Expand snippet",
		},
		{
			"<C-L>",
			function()
				require("luasnip").jump(1)
			end,
			mode = { "i", "s" },
			silent = true,
			desc = "LuaSnip: Jump forward",
		},
		{
			"<C-J>",
			function()
				require("luasnip").jump(-1)
			end,
			mode = { "i", "s" },
			silent = true,
			desc = "LuaSnip: Jump backward",
		},
		{
			"<C-E>",
			function()
				local ls = require("luasnip")
				if ls.choice_active() then
					ls.change_choice(1)
				end
			end,
			mode = { "i", "s" },
			silent = true,
			desc = "LuaSnip: Change choice",
		},
	},
	config = function()
		require("luasnip.loaders.from_lua").lazy_load({
			paths = { "~/.config/nvim/snippets" }
		})
	end,
}
