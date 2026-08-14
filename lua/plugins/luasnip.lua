return {
	"L3MON4D3/LuaSnip",
	build = "make install_jsregexp",
	-- Nothing here needs LuaSnip until completion exists. blink.cmp lists it in
	-- `dependencies`, so blink drags it in on InsertEnter/CmdlineEnter; without
	-- `lazy = true` this spec has no trigger of its own and loads eagerly
	-- (1.89 ms) even though its only consumer is lazy.
	lazy = true,
	-- blink.cmp drives expansion + tab-jumping; LuaSnip just provides the snippet engine
	config = function()
		require("luasnip.loaders.from_lua").lazy_load({
			paths = { "~/.config/nvim/snippets" },
		})
	end,
}
