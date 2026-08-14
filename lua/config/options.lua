-- Editor options. Indentation lives in config/indent.lua; clipboard in
-- config/clipboard.lua. Everything else that is a plain `vim.opt` is here.

local M = {}

function M.setup()
	-- Search
	vim.o.ignorecase = true
	vim.o.smartcase = true -- ...unless the pattern contains a capital

	-- Trust project-local .nvim.lua files
	vim.o.exrc = true

	-- 24-bit colour. Set once: Neovim detects tmux correctly on its own, and
	-- the old `if vim.env.TMUX then termguicolors = true end` was setting the
	-- value it had just been set to.
	vim.opt.termguicolors = true

	vim.opt.number = true
	vim.opt.relativenumber = true
	vim.opt.cmdheight = 0 -- hide cmdline row when idle; ui2 pops it up on :

	-- Soft wrapping: break at word boundaries rather than mid-word, and keep
	-- continuation lines aligned with the indent of the line they belong to.
	vim.opt.linebreak = true
	vim.opt.breakindent = true

	local group = vim.api.nvim_create_augroup("UserOptions", { clear = true })

	-- Places where soft-wrapping is conventionally *off* (columnar / structured
	-- output where a wrapped row would misalign or mislead).
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = { "qf", "diff", "csv", "tsv", "gitrebase" },
		callback = function()
			vim.wo.wrap = false
			vim.wo.linebreak = false
		end,
	})

	-- Terminal buffers: the program owns its own line discipline.
	vim.api.nvim_create_autocmd("TermOpen", {
		group = group,
		callback = function()
			vim.wo.wrap = false
			vim.wo.linebreak = false
		end,
	})

	-- Filetype detection
	vim.filetype.add({
		extension = {
			tf = "terraform",
		},
	})

	-- Unused language providers.
	--
	-- Neovim probes for perl/ruby/node/python3 hosts to support remote plugins
	-- written in those languages. Nothing here uses one, so the probes only
	-- produce four :checkhealth warnings and a little work at startup. Say so
	-- explicitly rather than leaving the warnings to be re-diagnosed later.
	vim.g.loaded_perl_provider = 0
	vim.g.loaded_ruby_provider = 0
	vim.g.loaded_node_provider = 0
	vim.g.loaded_python3_provider = 0
end

return M
