-- LSP logging.
--
-- Why this file exists: ~/.local/state/nvim/lsp.log reached **350 MB**.
--
-- Neovim's default LSP log level is WARN, and it writes every `window/logMessage`
-- a server sends at that level or above, forever, with no rotation and no size
-- cap. Most servers are quiet. Some are not: markdown-oxide reports routine
-- progress ("Diagnostics Started", "Update Vault Done", "VAULT Lock is good")
-- at WARN and ERROR, several times a second, for the life of the session. The
-- file only ever grows, and nothing in a default config ever notices.
--
-- So: log nothing by default, because a log nobody reads is just a disk leak.
-- When a server actually misbehaves, turn it back on for that session:
--
--     :LspLog debug      -- start recording
--     :LspLog            -- open the file
--     :LspLog off        -- stop
--
-- or set NVIM_LSP_LOG=debug in the environment before launching.

local M = {}

local LEVELS = { "trace", "debug", "info", "warn", "error", "off" }

local function log_path()
	return vim.lsp.log.get_filename()
end

--- Human-readable size of the log file, or nil if it does not exist.
local function log_size()
	local stat = (vim.uv or vim.loop).fs_stat(log_path())
	if not stat then
		return nil
	end
	local units = { "B", "KB", "MB", "GB" }
	local size, i = stat.size, 1
	while size >= 1024 and i < #units do
		size, i = size / 1024, i + 1
	end
	return string.format("%.1f %s", size, units[i]), stat.size
end

function M.setup()
	vim.lsp.log.set_level(vim.env.NVIM_LSP_LOG or vim.log.levels.OFF)

	-- A hard ceiling, in case a future session is left recording. Checked once
	-- at startup: a stat() on one file, well under a millisecond.
	local _, bytes = log_size()
	if bytes and bytes > 50 * 1024 * 1024 then
		os.remove(log_path())
		vim.schedule(function()
			vim.notify("lsp.log exceeded 50 MB and was truncated", vim.log.levels.WARN)
		end)
	end

	vim.api.nvim_create_user_command("LspLog", function(args)
		local arg = args.args
		if arg == "" then
			local size = log_size()
			vim.cmd.tabnew(log_path())
			vim.notify(("lsp.log (%s)"):format(size or "empty"), vim.log.levels.INFO)
		elseif vim.tbl_contains(LEVELS, arg) then
			vim.lsp.log.set_level(arg == "off" and vim.log.levels.OFF or arg)
			vim.notify("LSP log level: " .. arg, vim.log.levels.INFO)
		elseif arg == "clear" then
			os.remove(log_path())
			vim.notify("lsp.log removed", vim.log.levels.INFO)
		else
			vim.notify("LspLog: expected one of " .. table.concat(LEVELS, ", ") .. ", clear",
				vim.log.levels.ERROR)
		end
	end, {
		nargs = "?",
		complete = function()
			return vim.list_extend(vim.deepcopy(LEVELS), { "clear" })
		end,
		desc = "Open the LSP log, or set its level (off by default)",
	})
end

return M
