-- lazydev: teach lua_ls about the Neovim API and about plugin types, but only
-- for the plugins actually mentioned in the file being edited.
return {
	"folke/lazydev.nvim",
	ft = "lua",
	opts = {
		library = {
			-- vim.uv stubs. lua_ls ships these as a built-in ${3rd} addon, so
			-- the separate Bilal2453/luvit-meta plugin (and its duplicate
			-- "luvit-meta/library" entry) is no longer needed — lazydev's own
			-- README dropped it. Removed.
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			{ path = "snacks.nvim", words = { "Snacks" } },
			-- Was: { path = "lazy.nvim", words = { "LazyVim" } }
			-- LazyVim is not installed here; that entry could never match.
			-- The useful trigger for lazy.nvim's own types is the word `lazy`.
			{ path = "lazy.nvim", words = { "LazyPluginSpec", "LazySpec" } },
		},
	},
}
