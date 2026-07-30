-- Terminal management functions
-- Generic library — receives all config at runtime via setup()

local M = {}

local Terminal = nil
local instance_counter = {}     -- { [prefix] = number }
local buffer_registry = {}      -- { [key] = { buf_id, config } }
local default_shell = nil       -- shell argv used by termopen, set in setup()

function M.set_terminal_class(terminal_class)
	Terminal = terminal_class
end

function M.set_default_shell(shell)
	default_shell = shell
end

local function buffer_valid(buf_id)
	return buf_id and vim.api.nvim_buf_is_valid(buf_id)
end

local function get_next_instance(prefix)
	instance_counter[prefix] = (instance_counter[prefix] or 0) + 1
	return instance_counter[prefix]
end

local function make_buffer_name(prefix, instance_num)
	if instance_num == 1 then
		return prefix
	end
	return prefix .. "_" .. instance_num
end

local function find_buffer_in_registry(prefix, sub_name)
	local key = sub_name and (prefix .. "_" .. sub_name) or prefix
	local entry = buffer_registry[key]
	if entry and buffer_valid(entry.buf_id) then
		return entry.buf_id
	end
	return nil
end

local function register_buffer(prefix, sub_name, buf_id, config)
	local key = sub_name and (prefix .. "_" .. sub_name) or prefix
	buffer_registry[key] = { buf_id = buf_id, config = config }
end

-- Create a terminal buffer running cmd through the configured shell.
-- searchable: if true, mark buflisted so it shows up in buffer pickers.
local function create_term_buffer(name, cmd, searchable)
	vim.cmd("enew")

	local shell_argv = default_shell or { vim.o.shell }
	-- If a cmd is supplied, run it via the shell with -c (POSIX) or pass as a single command.
	local argv
	if cmd and cmd ~= "" then
		argv = {}
		for _, v in ipairs(shell_argv) do table.insert(argv, v) end
		table.insert(argv, "-c")
		table.insert(argv, cmd .. "; exec " .. shell_argv[1])
	else
		argv = shell_argv
	end

	vim.fn.termopen(argv, {
		env = {
			VIM_SERVERNAME = vim.v.servername or "VIMSERVER",
			VIM_LISTEN_ADDRESS = vim.v.servername,
			TERM = vim.env.TERM or "xterm-256color",
			COLORTERM = vim.env.COLORTERM,
		},
	})

	local buf_id = vim.api.nvim_get_current_buf()
	pcall(vim.api.nvim_buf_set_name, buf_id, name)
	vim.bo[buf_id].buflisted = searchable or false

	-- Buffer-local UI tweaks via BufEnter (avoids leaking to other windows)
	vim.api.nvim_create_autocmd("BufEnter", {
		buffer = buf_id,
		callback = function()
			vim.wo.signcolumn = "no"
			vim.wo.number = false
			vim.wo.relativenumber = false
			vim.wo.spell = false
		end,
	})

	return buf_id
end

-- Single-process, non-singleton invocation: always create a new numbered buffer.
function M.invoke_single(term_config)
	local prefix = term_config.name
	local instance_num = get_next_instance(prefix)
	local buf_name = make_buffer_name(prefix, instance_num)
	return create_term_buffer(buf_name, term_config.cmd, term_config.searchable)
end

-- Multi-process invocation: starts/reuses several named buffers and shows the "main" one.
function M.invoke_multi(config)
	local prefix = config.name
	local main_buf = nil
	local original_buf = vim.api.nvim_get_current_buf()

	local needs_new_group = not config.singleton
	local instance_num = 1

	if needs_new_group then
		local any_exists = false
		for _, buf_cfg in ipairs(config.buffers) do
			local key = prefix .. "_" .. buf_cfg.name
			if buffer_registry[key] and buffer_valid(buffer_registry[key].buf_id) then
				any_exists = true
				break
			end
		end
		if any_exists then
			instance_num = get_next_instance(prefix)
		else
			instance_counter[prefix] = 1
			instance_num = 1
		end
	end

	for _, buf_cfg in ipairs(config.buffers) do
		local sub_name = buf_cfg.name
		local full_prefix = prefix .. "_" .. sub_name
		local buf_name = make_buffer_name(full_prefix, instance_num)

		local existing_buf = nil
		if buf_cfg.singleton or config.singleton then
			existing_buf = find_buffer_in_registry(prefix, sub_name)
		end

		if existing_buf then
			if buf_cfg.main then
				main_buf = existing_buf
			end
		else
			local is_searchable = buf_cfg.searchable or config.searchable
			local buf_id = create_term_buffer(buf_name, buf_cfg.cmd, is_searchable)
			register_buffer(prefix, sub_name, buf_id, buf_cfg)

			if buf_cfg.main then
				main_buf = buf_id
			else
				-- Switch back so non-main buffers run in the background
				vim.api.nvim_set_current_buf(original_buf)
			end
		end
	end

	if main_buf then
		vim.api.nvim_set_current_buf(main_buf)
	end
	return main_buf
end

-- :Terminal command — open a fresh shell terminal in the current window
function M.custom_terminal()
	create_term_buffer("term", nil, false)
end

return M
