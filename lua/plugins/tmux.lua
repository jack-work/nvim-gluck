-- smart-splits: <C-hjkl> that crosses the boundary between nvim splits and
-- tmux panes without you having to think about which one you are in.
--
-- Was `lazy = false` and cost 4.83 ms of every startup — the most expensive
-- eager plugin here — to register nothing but keymaps. lazy.nvim's `keys`
-- creates lightweight stubs and loads the plugin on first press, so the cost
-- moves to the first time you actually navigate.
--
-- The functions are referenced through a wrapper rather than
-- `require("smart-splits").move_cursor_left` directly: spec files are
-- evaluated during startup, so a bare require here would load the plugin
-- immediately and undo the point of this.
local function cmd(name)
	return function()
		require("smart-splits")[name]()
	end
end

return {
	"mrjones2014/smart-splits.nvim",
	opts = {
		at_edge = "stop", -- or 'wrap' to cycle through
		multiplexer_integration = "tmux",
	},
	-- stylua: ignore
	keys = {
		-- Navigation. Bound in normal *and* terminal mode so they work from
		-- inside a running shell, matching the tmux-side bindings.
		{ "<C-h>", cmd("move_cursor_left"),  mode = { "n", "t" }, desc = "Move to left split" },
		{ "<C-j>", cmd("move_cursor_down"),  mode = { "n", "t" }, desc = "Move to bottom split" },
		{ "<C-k>", cmd("move_cursor_up"),    mode = { "n", "t" }, desc = "Move to top split" },
		{ "<C-l>", cmd("move_cursor_right"), mode = { "n", "t" }, desc = "Move to right split" },

		-- Resize
		{ "<M-h>", cmd("resize_left"),  desc = "Resize split left" },
		{ "<M-j>", cmd("resize_down"),  desc = "Resize split down" },
		{ "<M-k>", cmd("resize_up"),    desc = "Resize split up" },
		{ "<M-l>", cmd("resize_right"), desc = "Resize split right" },

		-- Swap the buffer with the one in the adjacent split
		{ "<C-M-h>", cmd("swap_buf_left"),  desc = "Swap buffer left" },
		{ "<C-M-j>", cmd("swap_buf_down"),  desc = "Swap buffer down" },
		{ "<C-M-k>", cmd("swap_buf_up"),    desc = "Swap buffer up" },
		{ "<C-M-l>", cmd("swap_buf_right"), desc = "Swap buffer right" },
	},
}
