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

local M = {}

function M.setup()
	vim.opt.clipboard = "unnamedplus"
	vim.g.clipboard = nil -- let the built-in provider probe the platform

	-- Forces provider resolution and reports whether a real tool was found.
	if vim.fn.has("clipboard_working") == 1 then
		return
	end

	local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
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
	local emit = osc52.copy("+")
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = vim.api.nvim_create_augroup("Osc52Mirror", { clear = true }),
		desc = "Mirror clipboard-register yanks to the host terminal via OSC 52",
		callback = function()
			local ev = vim.v.event
			if not ev.regcontents or #ev.regcontents == 0 then
				return
			end
			local reg, cb = ev.regname, vim.o.clipboard
			-- '' means the unnamed register, which only counts as a clipboard
			-- write when 'clipboard' aliases it to "+ / "*.
			local unnamed_is_clip = cb:find("unnamed") ~= nil
			if reg == "+" or reg == "*" or (reg == "" and unnamed_is_clip) then
				pcall(emit, ev.regcontents, ev.regtype)
			end
		end,
	})
end

return M
