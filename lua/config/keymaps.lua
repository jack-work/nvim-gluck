-- Global keymaps.
--
-- Buffer-local maps live next to what they belong to: LSP maps in
-- plugins/lsp.lua (LspAttach), Rust maps in plugins/rust.lua, and any map that
-- should lazy-load a plugin belongs in that plugin's `keys = {}` so lazy.nvim
-- can defer it. Defining such a map here instead would create the mapping
-- eagerly and defeat the lazy handler — which is exactly what the duplicate
-- <leader>jn here used to do to oil.nvim.

local M = {}

function M.setup()
	local map = function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
	end

	map("n", "<leader><leader>", ":noh<CR>", "Clear search highlighting")

	map("n", "<leader>op", function()
		local path = vim.fn.expand("%:p")
		vim.fn.setreg("+", path)
		vim.notify("Copied: " .. path)
	end, "Copy file path")

	-- Diagnostic navigation, severity-prioritized: jump to the next ERROR if
	-- one exists anywhere, else the next WARN, and so on. Plain ]d/[d would
	-- walk you through hints on the way to the error that actually matters.
	local severities = {
		vim.diagnostic.severity.ERROR,
		vim.diagnostic.severity.WARN,
		vim.diagnostic.severity.INFO,
		vim.diagnostic.severity.HINT,
	}

	local function jump(count)
		for _, severity in ipairs(severities) do
			local probe = count > 0 and vim.diagnostic.get_next or vim.diagnostic.get_prev
			if probe({ severity = severity }) then
				vim.diagnostic.jump({ count = count, severity = severity })
				return
			end
		end
		vim.diagnostic.jump({ count = count })
	end

	map("n", "]d", function() jump(1) end, "Next diagnostic (severity-prioritized)")
	map("n", "[d", function() jump(-1) end, "Previous diagnostic (severity-prioritized)")
end

return M
