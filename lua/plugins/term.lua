-- Terminal config — declarative terminal definitions powered by lua/terminal/

--- Global cwd, ignoring any window-local :lcd / tab-local :tcd.
--- This is "where the nvim process is rooted".
local function project_cwd()
	return vim.fn.getcwd(-1, -1)
end

--- Directory of the current buffer, oil-aware, scheme-aware, with cwd fallback.
local function buffer_dir()
	if vim.bo.filetype == "oil" then
		local ok, oil = pcall(require, "oil")
		local dir = ok and oil.get_current_dir()
		if dir then
			return dir
		end
	end

	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		return project_cwd()
	end

	-- strip URI schemes: oil:///path, fugitive:///path, term:///path//123:fish
	name = name:gsub("^%a[%w+.%-]*://", "")
	if vim.bo.buftype == "terminal" then
		name = name:gsub("//%d+:.*$", "")
	end

	if vim.fn.isdirectory(name) == 1 then
		return vim.fn.fnamemodify(name, ":p")
	end
	local dir = vim.fn.fnamemodify(name, ":p:h")
	return vim.fn.isdirectory(dir) == 1 and dir or project_cwd()
end

--- One reusable floating terminal per directory: press again to toggle it back.
local term_cache = {}

local function toggle_term_in(dir)
	if dir == "git_dir" then
		dir = require("toggleterm.utils").git_dir() or project_cwd()
	end
	local key = vim.fs.normalize(dir)
	local term = term_cache[key]
	if term and term.bufnr and not vim.api.nvim_buf_is_valid(term.bufnr) then
		term = nil
	end
	if not term then
		local Terminal = require("toggleterm.terminal").Terminal
		term = Terminal:new({
			dir = key,
			direction = "float",
			display_name = vim.fn.fnamemodify(key, ":~"),
			close_on_exit = true,
			start_in_insert = true,
			float_opts = { border = "curved" },
			on_exit = function()
				term_cache[key] = nil
			end,
		})
		term_cache[key] = term
	end
	term:toggle()
end

return {
	"akinsho/toggleterm.nvim",
	lazy = false,
	config = function()
		require("terminal").setup({
			-- Shell config (fish on Linux)
			shell = {
				shell = "fish",
				shellcmdflag = "-c",
				shellredir = ">%s 2>&1",
				shellpipe = "2>&1 | tee",
				shellquote = "",
				shellxquote = "",
			},
			-- argv used by termopen for direct invocation
			shell_argv = { "fish" },

			toggleterm = {
				size = 10,
				hide_numbers = true,
				shade_terminals = true,
				shading_factor = 2,
				start_in_insert = true,
				insert_mappings = true,
				persist_size = true,
				close_on_exit = true,
				direction = "float",
				float_opts = {
					border = "curved",
					winblend = 0,
					highlights = { border = "Normal", background = "Normal" },
				},
			},

			terminals = {
				{
					name = "aichat",
					keymap = "<leader>ai",
					cmd = "aichat -r coder",
					desc = "Toggle AI Chat",
					singleton = true,
					use_ctrl = true,
					direction = "float",
					float_opts = { border = "curved", width = 150, height = 50 },
				},
				{
					name = "yipyap",
					keymap = "<leader>yy",
					cmd = "yipyap",
					desc = "Toggle yipyap",
					singleton = true,
					direction = "float",
					float_opts = { border = "curved", width = 80, height = 50 },
				},
			},

			custom_keymaps = {
				{
					mode = "n",
					keymap = "<leader>th",
					desc = "Terminal here (buffer's directory)",
					action = function()
						toggle_term_in(buffer_dir())
					end,
				},
				{
					mode = "n",
					keymap = "<leader>tm",
					desc = "Terminal in cwd (nvim process root)",
					action = function()
						toggle_term_in(project_cwd())
					end,
				},
				{
					mode = "n",
					keymap = "<leader>tg",
					desc = "Terminal in git root",
					action = function()
						toggle_term_in("git_dir")
					end,
				},
			},

			override_terminal = true,
		})
	end,
}
