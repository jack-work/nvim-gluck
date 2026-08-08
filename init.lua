-- Clipboard: portable across Wayland, X11, macOS, Windows, WSL, and bare SSH.
--
-- Rule #1: never use OSC 52 *paste*. It writes a query escape to the terminal
-- and blocks until the terminal answers, and virtually no terminal answers
-- (it's a security hole: any program could then read your clipboard). That
-- block is the "Waiting for OSC 52 response from the terminal" hang, and with
-- clipboard=unnamedplus it fires on every p/P/d/c, not just explicit pastes.
--
-- Rule #2: don't hand-roll platform detection. Neovim's built-in provider
-- already probes, in order: pbcopy (macOS), wl-clipboard (Wayland), xclip and
-- xsel (X11), win32yank (Windows/WSL), clip.exe + powershell (WSL fallback),
-- termux-clipboard, tmux. Leaving vim.g.clipboard unset gets all of that for
-- free, on every OS, with no branching here. It is also an elseif chain that
-- returns on first match, so the probe costs ~0.4ms and the branches for other
-- platforms are never reached; there is nothing to win by trimming it.
--
-- So: let Neovim autodetect. Only if it finds *no* native tool (a bare SSH
-- session with no compositor, no X, no Windows host) mirror yanks outward with
-- OSC 52 copy, and leave paste to ordinary registers (see the note below).
local function setup_clipboard()
	vim.g.clipboard = nil -- let the built-in provider probe the platform

	-- Forces provider resolution and reports whether a real tool was found.
	if vim.fn.has('clipboard_working') == 1 then
		return
	end

	local ok, osc52 = pcall(require, 'vim.ui.clipboard.osc52')
	if not ok then
		return -- no native tool and no OSC 52: leave "+ as a plain register
	end

	-- Deliberately do NOT install a paste handler. A provider with a paste
	-- function makes "+ opaque: reads route through the provider, and anything
	-- that can't answer (OSC 52) either hangs or returns empty, which is what
	-- broke getreg('+') for plugins. Leaving vim.g.clipboard unset keeps "+ a
	-- normal in-memory register, always readable and never blocking.
	--
	-- Copy is then mirrored outward: every write to the clipboard register also
	-- gets shipped to the host terminal as an OSC 52 sequence. Yank here, paste
	-- into your local GUI apps. The reverse direction is the terminal's job
	-- (Ctrl-Shift-V / middle click), as it must be: no escape can read it back.
	local emit = osc52.copy('+')
	vim.api.nvim_create_autocmd('TextYankPost', {
		group = vim.api.nvim_create_augroup('Osc52Mirror', { clear = true }),
		desc = 'Mirror clipboard-register yanks to the host terminal via OSC 52',
		callback = function()
			local ev = vim.v.event
			if not ev.regcontents or #ev.regcontents == 0 then
				return
			end
			local reg, cb = ev.regname, vim.o.clipboard
			-- '' means the unnamed register, which only counts as a clipboard
			-- write when 'clipboard' aliases it to "+ / "*.
			local unnamed_is_clip = cb:find('unnamed') ~= nil
			if reg == '+' or reg == '*' or (reg == '' and unnamed_is_clip) then
				pcall(emit, ev.regcontents, ev.regtype)
			end
		end,
	})
end
setup_clipboard()

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
-- Soft wrapping: break at word boundaries rather than mid-word, and keep
-- continuation lines aligned with the indent of the line they belong to.
vim.opt.linebreak = true
vim.opt.breakindent = true
-- Places where soft-wrapping is conventionally *off* (columnar / structured
-- output where a wrapped row would misalign or mislead).
vim.api.nvim_create_autocmd('FileType', {
	pattern = { 'qf', 'diff', 'csv', 'tsv', 'gitrebase' },
	callback = function()
		vim.wo.wrap = false
		vim.wo.linebreak = false
	end,
})
-- Terminal buffers: the program owns its own line discipline.
vim.api.nvim_create_autocmd('TermOpen', {
	callback = function()
		vim.wo.wrap = false
		vim.wo.linebreak = false
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
