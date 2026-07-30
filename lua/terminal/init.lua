-- Terminal plugin initialization
-- Generic library that receives ALL config via opts parameter

local M = {}
local terminals_lib = require("terminal.terminals")

function M.setup(opts)
	opts = opts or {}

	local toggleterm_ok, toggleterm = pcall(require, "toggleterm")
	if not toggleterm_ok then
		vim.notify("toggleterm not found", vim.log.levels.ERROR)
		return
	end

	-- Configure global shell options (POSIX-friendly)
	if opts.shell then
		vim.o.shell = opts.shell.shell or vim.o.shell
		if opts.shell.shellcmdflag then vim.o.shellcmdflag = opts.shell.shellcmdflag end
		if opts.shell.shellredir then vim.o.shellredir = opts.shell.shellredir end
		if opts.shell.shellpipe then vim.o.shellpipe = opts.shell.shellpipe end
		if opts.shell.shellquote ~= nil then vim.o.shellquote = opts.shell.shellquote end
		if opts.shell.shellxquote ~= nil then vim.o.shellxquote = opts.shell.shellxquote end
	end

	-- Shell argv used by termopen for direct invocation
	terminals_lib.set_default_shell(opts.shell_argv or { vim.o.shell })

	if opts.toggleterm then
		toggleterm.setup(opts.toggleterm)
	end

	local Terminal = require("toggleterm.terminal").Terminal
	terminals_lib.set_terminal_class(Terminal)

	local toggleterm_instances = {}

	if opts.terminals then
		for _, term_config in ipairs(opts.terminals) do
			if not term_config.name or not term_config.keymap then
				vim.notify("terminal config missing 'name' or 'keymap'", vim.log.levels.WARN)
				goto continue
			end

			local is_multi = term_config.buffers ~= nil

			if is_multi then
				vim.keymap.set("n", term_config.keymap, function()
					terminals_lib.invoke_multi(term_config)
				end, { desc = term_config.desc or ("Start " .. term_config.name) })
			else
				local term_opts = {
					cmd = term_config.cmd,
					direction = term_config.direction or "float",
					close_on_exit = term_config.close_on_exit ~= false,
					start_in_insert = term_config.start_in_insert ~= false,
					display_name = term_config.name,
				}
				if term_config.float_opts then
					term_opts.float_opts = term_config.float_opts
				end

				term_opts.on_open = function(term)
					vim.bo[term.bufnr].buflisted = term_config.searchable or false
					if term_config.use_ctrl then
						local kopts = { buffer = term.bufnr, noremap = true, silent = true }
						vim.keymap.set("t", "<C-q>", [[<C-\><C-n>:q<CR>]], kopts)
					end
				end

				local instance = Terminal:new(term_opts)
				toggleterm_instances[term_config.name] = instance

				vim.keymap.set("n", term_config.keymap, function()
					if term_config.singleton == false then
						terminals_lib.invoke_single(term_config)
					else
						instance:toggle()
					end
				end, { desc = term_config.desc or ("Toggle " .. term_config.name) })

				_G["_TOGGLE_" .. term_config.name:upper()] = function()
					instance:toggle()
				end
			end

			::continue::
		end
	end

	if opts.custom_keymaps then
		for _, kmap in ipairs(opts.custom_keymaps) do
			vim.keymap.set(
				kmap.mode or "n",
				kmap.keymap,
				kmap.action,
				{ desc = kmap.desc }
			)
		end
	end

	if opts.override_terminal ~= false then
		vim.api.nvim_create_user_command("Terminal", terminals_lib.custom_terminal, {
			nargs = 0,
			force = true,
		})
		vim.cmd("cabbrev terminal Terminal")
		vim.cmd("cabbrev term Terminal")
	end

	-- Terminal-mode escape (single press of Esc-Esc)
	vim.keymap.set("t", "<ESC><ESC>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
end

return M
