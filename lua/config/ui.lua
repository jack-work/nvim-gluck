-- UI wiring: the cmdline overlay and where messages go.
--
-- Caveat worth keeping in view: `vim._core.ui2` is a *private* Neovim module
-- (the leading underscore is the contract). It is what replaced noice for the
-- cmdline here, and it may be renamed or restructured by any 0.12.x release.
-- Hence the pcall — if it disappears, the cmdline goes back to being a normal
-- one and nothing else breaks.

local M = {}

function M.setup()
	-- ui2 (Neovim 0.12+): we want only its cmdline overlay (so `:` is visible
	-- with cmdheight=0), not its message rendering — msg_router handles those
	-- via vim.notify/snacks. After enable(), stub out the msg.* handlers so
	-- ui2 ignores msg_show et al.
	pcall(function()
		local ui2 = require("vim._core.ui2")
		ui2.enable()
		if ui2.msg then
			for _, k in ipairs({
				"msg_show",
				"msg_showmode",
				"msg_clear",
				"msg_history_show",
				"msg_ruler",
				"msg_showcmd",
			}) do
				ui2.msg[k] = function() end
			end
		end
	end)

	-- Route Neovim ext_messages straight to vim.notify (snacks.notifier).
	-- Replaces what noice was doing for save/echo/error messages.
	pcall(function()
		require("config.msg_router").setup()
	end)
end

return M
