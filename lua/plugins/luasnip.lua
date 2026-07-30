return {
	"L3MON4D3/LuaSnip",
	build = "make install_jsregexp",
	-- blink.cmp drives expansion + tab-jumping; LuaSnip just provides the snippet engine
	config = function()
		require("luasnip.loaders.from_lua").lazy_load({
			paths = { "~/.config/nvim/snippets" },
		})
	end,
}
