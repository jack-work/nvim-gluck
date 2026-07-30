-- Use OSC 52 for clipboard (works locally on Wayland and over SSH/tmux)
vim.g.clipboard = {
	name = 'OSC 52',
	copy = {
		['+'] = require('vim.ui.clipboard.osc52').copy('+'),
		['*'] = require('vim.ui.clipboard.osc52').copy('*'),
	},
	paste = {
		['+'] = require('vim.ui.clipboard.osc52').paste('+'),
		['*'] = require('vim.ui.clipboard.osc52').paste('*'),
	},
}

require("config.lazy")

-- ui2 (Neovim 0.12+): we want only its cmdline overlay (so `:` is visible
-- with cmdheight=0), not its message rendering — msg_router handles
-- those via vim.notify/snacks. After enable(), stub out the msg.*
-- handlers so ui2 ignores msg_show et al.
pcall(function()
	local ui2 = require("vim._core.ui2")
	ui2.enable()
	if ui2.msg then
		for _, k in ipairs({ "msg_show", "msg_showmode", "msg_clear", "msg_history_show", "msg_ruler", "msg_showcmd" }) do
			ui2.msg[k] = function() end
		end
	end
end)

-- Route Neovim ext_messages straight to vim.notify (snacks.notifier).
-- Replaces what noice was doing for save/echo/error messages.
pcall(function() require("config.msg_router").setup() end)

vim.o.smartcase = true
vim.o.ignorecase = true

-- Trust project-local .nvim.lua files
vim.o.exrc = true

vim.opt.termguicolors = true
if vim.env.TMUX then
	vim.opt.termguicolors = true
end

vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation: <Tab> inserts spaces; one indent level == 8 columns
-- (matches Neovim's historical default tab width — wider, airier blocks).
vim.opt.expandtab = true   -- <Tab> -> spaces
vim.opt.tabstop = 8        -- visual width of a literal \t
vim.opt.shiftwidth = 8     -- size of >>, <<, autoindent step
vim.opt.softtabstop = 8    -- <Tab>/<BS> in insert mode operate on 8 spaces
vim.opt.smartindent = true
-- Per-filetype overrides: languages that *require* real tabs, or have
-- strong community conventions for narrower indents.
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'go', 'make', 'gitconfig' },
	callback = function()
		vim.bo.expandtab = false  -- real tabs
		vim.bo.tabstop = 8
		vim.bo.shiftwidth = 8
	end,
})
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'lua', 'yaml', 'json', 'html', 'css', 'javascript', 'typescript' },
	callback = function()
		vim.bo.tabstop = 2
		vim.bo.shiftwidth = 2
		vim.bo.softtabstop = 2
	end,
})
vim.opt.clipboard = "unnamedplus"
vim.opt.cmdheight = 0 -- hide cmdline row when idle; ui2 pops it up on :
vim.keymap.set("n", "<leader><leader>", ":noh<CR>", { desc = "Clear search highlighting", silent = true })

require('config.insert').setup()

vim.keymap.set('n', '<leader>op', function()
	local path = vim.fn.expand('%:p')
	vim.fn.setreg('+', path)
	vim.notify('Copied: ' .. path)
end, { desc = 'Copy file path' })

-- Filetype detection
vim.filetype.add({
	extension = {
		tf = "terraform",
	},
})

local diag_severities = {
	vim.diagnostic.severity.ERROR,
	vim.diagnostic.severity.WARN,
	vim.diagnostic.severity.INFO,
	vim.diagnostic.severity.HINT,
}

vim.keymap.set('n', ']d', function()
	for _, severity in ipairs(diag_severities) do
		if vim.diagnostic.get_next({ severity = severity }) then
			vim.diagnostic.jump({ count = 1, severity = severity })
			return
		end
	end
	vim.diagnostic.jump({ count = 1 })
end, { desc = 'Next diagnostic (severity-prioritized)' })

vim.keymap.set('n', '[d', function()
	for _, severity in ipairs(diag_severities) do
		if vim.diagnostic.get_prev({ severity = severity }) then
			vim.diagnostic.jump({ count = -1, severity = severity })
			return
		end
	end
	vim.diagnostic.jump({ count = -1 })
end, { desc = 'Previous diagnostic (severity-prioritized)' })

vim.keymap.set({ "n", "v" }, "<leader>jn", function() require("oil").open(vim.env.HOME .. "/notes") end,
	{ desc = "Jump: ~/notes" })
