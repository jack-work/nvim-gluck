-- Clipboard: portable across Wayland, X11, macOS, Windows, WSL, and bare SSH.
--
-- Semantics here are plain `unnamedplus`: y/d/c/x write the system clipboard,
-- p reads it. On this machine that resolves to wl-copy/wl-paste.
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
-- free, on every OS, with no branching here.
--
-- Rule #3 -- the one that cost real debugging time -- is below.

local M = {}
local uv = vim.uv or vim.loop

-- ── Rule #3: `has('clipboard_working')` does not mean the clipboard works ────
--
-- It means "a clipboard tool was found on PATH". Look at the provider's own
-- test (runtime/autoload/provider/clipboard.vim):
--
--     elseif !empty($WAYLAND_DISPLAY) && executable('wl-copy') && executable('wl-paste')
--
-- $WAYLAND_DISPLAY merely has to be non-empty. Nothing checks that the socket
-- it names still exists. So when the compositor restarts, or when a tmux
-- server outlives the session it was started in, or when you attach over SSH
-- to a tmux started under a graphical login, every nvim in an old pane keeps a
-- stale $WAYLAND_DISPLAY and:
--
--   * has('clipboard_working') still returns 1,
--   * provider#clipboard#Error() is still empty,
--   * wl-copy is still "chosen" and silently fails against a dead socket,
--   * so yanks vanish and the OSC 52 fallback below never engages.
--
-- Measured, with WAYLAND_DISPLAY pointed at a socket that does not exist:
--   provider chose = wl-copy, error = "", getreg('+') after yy = ""
--
-- That is the whole bug. The fix is to check the socket ourselves and, inside
-- tmux, ask tmux for the value it learned on the most recent attach -- which is
-- exactly what `update-environment` keeps current for new panes but cannot
-- push into a process that is already running.

--- Does the socket named by `name` actually exist?
--- Absolute paths are used as-is; bare names are relative to XDG_RUNTIME_DIR.
local function wayland_socket_ok(name)
	if not name or name == "" then
		return false
	end
	if name:sub(1, 1) == "/" then
		return uv.fs_stat(name) ~= nil
	end
	local dir = vim.env.XDG_RUNTIME_DIR
	return dir ~= nil and uv.fs_stat(dir .. "/" .. name) ~= nil
end

--- Read a variable out of the tmux *session* environment, which tmux refreshes
--- from the attaching client on every attach (see `update-environment`).
--- Returns nil when not in tmux, when tmux is unreachable, or when tmux
--- reports the variable as unset (it prints `-NAME` for that).
local function tmux_env(var)
	if not vim.env.TMUX then
		return nil
	end
	local ok, res = pcall(function()
		return vim.system({ "tmux", "show-environment", var }, { text = true }):wait(1000)
	end)
	if not ok or res.code ~= 0 then
		return nil
	end
	local value = vim.trim(res.stdout or ""):match("^" .. vim.pesc(var) .. "=(.*)$")
	return value ~= "" and value or nil
end

--- Re-run the provider's probe so a corrected environment takes effect.
local function reprobe()
	pcall(vim.fn["provider#clipboard#Executable"])
end

--- Point $WAYLAND_DISPLAY back at a live compositor if it has gone stale.
--- Returns "ok" (nothing to do), "repaired", or "broken".
function M.repair()
	if vim.env.WAYLAND_DISPLAY == nil then
		return "ok" -- not a Wayland session; nothing here applies
	end
	if wayland_socket_ok(vim.env.WAYLAND_DISPLAY) then
		return "ok"
	end
	local fresh = tmux_env("WAYLAND_DISPLAY")
	if fresh and fresh ~= vim.env.WAYLAND_DISPLAY and wayland_socket_ok(fresh) then
		vim.env.WAYLAND_DISPLAY = fresh
		reprobe()
		return "repaired"
	end
	return "broken"
end

--- True when a native tool exists *and*, on Wayland, can actually reach a
--- compositor. This is the honest version of has('clipboard_working').
local function clipboard_really_works()
	if vim.fn.has("clipboard_working") ~= 1 then
		return false
	end
	if vim.env.WAYLAND_DISPLAY ~= nil then
		return wayland_socket_ok(vim.env.WAYLAND_DISPLAY)
	end
	return true
end

-- Mirror clipboard-register writes to the host terminal as OSC 52. Used only
-- when there is no working native tool: a bare SSH session, or a Wayland
-- session whose socket we could not repair.
--
-- Deliberately no paste handler. A provider with a paste function makes "+
-- opaque: reads route through the provider, and anything that can't answer
-- (OSC 52) either hangs or returns empty, which is what broke getreg('+') for
-- plugins. Leaving vim.g.clipboard unset keeps "+ a normal in-memory register,
-- always readable and never blocking. Yank here, paste into your local GUI
-- apps; the reverse direction is the terminal's job (Ctrl-Shift-V / middle
-- click), as it must be -- no escape sequence can read a clipboard back.
local osc52_installed = false
local function install_osc52_mirror()
	if osc52_installed then
		return
	end
	local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
	if not ok then
		return -- no native tool and no OSC 52: leave "+ as a plain register
	end
	osc52_installed = true
	local emit = osc52.copy("+")
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = vim.api.nvim_create_augroup("Osc52Mirror", { clear = true }),
		desc = "Mirror clipboard-register yanks to the host terminal via OSC 52",
		callback = function()
			local ev = vim.v.event
			if not ev.regcontents or #ev.regcontents == 0 then
				return
			end
			local reg = ev.regname
			-- '' means the unnamed register, which only counts as a clipboard
			-- write when 'clipboard' aliases it to "+ / "*.
			local unnamed_is_clip = vim.o.clipboard:find("unnamed") ~= nil
			if reg == "+" or reg == "*" or (reg == "" and unnamed_is_clip) then
				pcall(emit, ev.regcontents, ev.regtype)
			end
		end,
	})
end

function M.setup()
	vim.opt.clipboard = "unnamedplus"
	vim.g.clipboard = nil -- let the built-in provider probe the platform

	-- Costs one fs_stat in the healthy case. Only a dead socket makes this
	-- shell out to tmux, and only then does anything else happen.
	M.repair()

	if not clipboard_really_works() then
		install_osc52_mirror()
	end

	-- Reattaching a tmux session to a different (or restarted) compositor is
	-- the common way to go stale mid-session. Both events are rare and the
	-- check is an fs_stat, so this is free in practice.
	vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
		group = vim.api.nvim_create_augroup("ClipboardRepair", { clear = true }),
		desc = "Re-point WAYLAND_DISPLAY after a tmux reattach",
		callback = function()
			if M.repair() == "repaired" then
				vim.notify("clipboard: WAYLAND_DISPLAY was stale, repaired from tmux",
					vim.log.levels.INFO)
			end
		end,
	})

	vim.api.nvim_create_user_command("ClipboardInfo", function()
		local state = M.repair()
		local lines = {
			"provider   : " .. (vim.fn["provider#clipboard#Executable"]() ~= "" and
				vim.fn["provider#clipboard#Executable"]() or "(none)"),
			"error      : " .. (vim.fn["provider#clipboard#Error"]() ~= "" and
				vim.fn["provider#clipboard#Error"]() or "(none)"),
			"clipboard  : " .. (vim.o.clipboard ~= "" and vim.o.clipboard or "(unset)"),
			"WAYLAND    : " .. tostring(vim.env.WAYLAND_DISPLAY) .. "  [" .. state .. "]",
			"DISPLAY    : " .. tostring(vim.env.DISPLAY),
			"tmux       : " .. (vim.env.TMUX and "yes" or "no"),
			"osc52      : " .. (osc52_installed and "mirroring yanks" or "not needed"),
			"round-trip : " .. (function()
				-- Prove it, don't assume it: write a sentinel and read it back.
				local saved = vim.fn.getreg("+")
				local token = "nvim-clipboard-probe-" .. tostring(uv.hrtime())
				vim.fn.setreg("+", token)
				vim.wait(200, function() return vim.fn.getreg("+") == token end, 20)
				local got = vim.fn.getreg("+") == token
				vim.fn.setreg("+", saved)
				return got and "OK" or "FAILED (yanks are being lost)"
			end)(),
		}
		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "ClipboardInfo" })
	end, { desc = "Diagnose the system clipboard (and prove a round-trip)" })
end

return M
