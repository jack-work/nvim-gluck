-- Minimal noice-style message routing.
-- Listens to Neovim's ext_messages events and forwards them to vim.notify
-- (which snacks.notifier renders as a toast).

local M = {}

-- Kinds we deliberately drop (visual noise / handled elsewhere).
local skip_kinds = {
	search_count = true,
	return_prompt = true,
	completion = true,
	wildlist = true,
	list_cmd = true,
}

local error_kinds = {
	emsg = true,
	echoerr = true,
	lua_error = true,
	rpc_error = true,
}

local warn_kinds = {
	wmsg = true,
}

-- Patterns that should coalesce: messages matching the same id collapse
-- into a single toast that updates in place (instead of stacking).
-- Holding `u` to undo or `.` to repeat shouldn't fill the screen.
local coalesce_patterns = {
	{ pattern = "^%d+ changes?;",         id = "undo_redo" },
	{ pattern = "^Already at",            id = "undo_redo" },
	{ pattern = "^%d+ lines? yanked",     id = "yank" },
	{ pattern = "^%d+ lines? .ed",        id = "edit_count" }, -- "10 lines indented", etc.
	{ pattern = "^%d+ fewer lines",       id = "edit_count" },
	{ pattern = "^%d+ more lines",        id = "edit_count" },
	{ pattern = "^%d+ substitutions? on", id = "subst" },
	{ pattern = "^%-%- More %-%-",        id = "more_pager" },
	{ pattern = '^"[^"]+"',               id = "buf_written" }, -- any :w variant — partial, full, [New], etc.
	{ pattern = "^[/%?]",                 id = "search" },     -- /pattern or ?pattern echoed by n/N
}

local function coalesce_id(text)
	for _, c in ipairs(coalesce_patterns) do
		if text:match(c.pattern) then return c.id end
	end
	return nil
end

local function content_to_text(content)
	if not content then return nil end
	local pieces = {}
	for _, chunk in ipairs(content) do
		pieces[#pieces + 1] = chunk[2] or ""
	end
	return table.concat(pieces)
end

-- "-- INSERT --", "-- VISUAL --" etc. — keep mode in lualine, not as toast.
local function is_mode_string(text)
	return text:match("^%-%-[^\n]*%-%-$") ~= nil
end

function M.setup()
	local ns = vim.api.nvim_create_namespace("user_msg_router")
	local id_seq = 0
	local last_id = nil

	vim.ui_attach(ns, { ext_messages = true }, function(event, ...)
		if event ~= "msg_show" then return end

		local kind, content, replace_last = ...
		if skip_kinds[kind] then return end

		local text = content_to_text(content)
		if not text or text == "" then return end
		if is_mode_string(text) then return end

		text = text:gsub("%s+$", "")

		local level = vim.log.levels.INFO
		if error_kinds[kind] then
			level = vim.log.levels.ERROR
		elseif warn_kinds[kind] then
			level = vim.log.levels.WARN
		end

		-- Pick a notification id:
		-- 1. coalesce_patterns wins (text-pattern based, e.g. undo/redo spam)
		-- 2. else honor replace_last (Neovim's signal that this updates the prior msg)
		-- 3. else fresh id (separate toast)
		local id = coalesce_id(text)
		if not id then
			if replace_last and last_id then
				id = last_id
			else
				id_seq = id_seq + 1
				id = "msg_router_" .. id_seq
			end
		end
		last_id = id

		vim.schedule(function()
			vim.notify(text, level, {
				id = id,
				title = (kind ~= "" and kind ~= "echo") and kind or nil,
			})
		end)
	end)
end

return M
