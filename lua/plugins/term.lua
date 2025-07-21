return {
	"akinsho/toggleterm.nvim",
	config = function()
		local status, toggleterm = pcall(require, 'toggleterm')
		if (not status) then return end

		-- Fish shell configuration
		vim.cmd("let &shell = 'fish'")
		vim.cmd("let &shellcmdflag = '-c'")
		vim.cmd("let &shellredir = '>%s 2>&1'")
		vim.cmd("let &shellpipe = '2>&1 | tee'")
		vim.cmd("set shellquote= shellxquote=")

		toggleterm.setup({
			size = 10,
			open_mapping = [[<C-3>]],
			hide_numbers = true,
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			persist_size = true,
			close_on_exit = true,
			direction = 'float',
			shell = 'fish', -- Explicitly set fish as the shell
			float_opts = {
				border = "curved",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "Normal"
				}
			}
		})

		local Terminal = require('toggleterm.terminal').Terminal

		-- Define the terminal instance for yipyap
		local nodeCLI = Terminal:new({
			cmd = "yipyap",
			direction = "float",
			shell = 'fish', -- Use fish for this terminal too
			float_opts = {
				border = "curved",
				width = 80,
				height = 50,
			},
			close_on_exit = true,
			start_in_insert = true,
		})

		-- Create toggle function
		function _TOGGLE_NODE_CLI()
			nodeCLI:toggle()
		end

		-- Define the terminal instance for aichat
		local aichat = Terminal:new({
			cmd = "aichat -r coder",
			direction = "float",
			shell = 'fish', -- Use fish for this terminal too
			float_opts = {
				border = "curved",
				width = 150,
				height = 50,
			},
			close_on_exit = true,
			start_in_insert = true,
		})

		-- Create toggle function
		function _TOGGLE_AICHAT()
			aichat:toggle()
		end

		-- Custom terminal function that uses fish
		local function custom_terminal()
			vim.cmd('enew')
			local job_id = vim.fn.termopen('fish', {
				env = {
					-- Preserve important environment variables for fish
					TERM = vim.env.TERM or 'xterm-256color',
					COLORTERM = vim.env.COLORTERM,
					-- Add any other fish-specific env vars you need
				}
			})

			vim.schedule(function()
				vim.bo.syntax = ''
				vim.wo.signcolumn = 'no'
				vim.wo.spell = false
				-- Set terminal-specific options
				vim.wo.number = false
				vim.wo.relativenumber = false
			end)
		end

		-- Override the :terminal command
		vim.api.nvim_create_user_command('Terminal', custom_terminal, {
			nargs = 0,
			force = true
		})

		-- Create abbreviations to intercept :terminal
		vim.cmd('cabbrev terminal Terminal')
		vim.cmd('cabbrev term Terminal')

		vim.keymap.set("t", "<ESC><ESC>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
		-- Keymaps (fixed function names)
		vim.keymap.set("n", "<leader>yy", "<cmd>lua _TOGGLE_NODE_CLI()<CR>")
		vim.keymap.set("n", "<leader>ai", "<cmd>lua _TOGGLE_AICHAT()<CR>")
		vim.keymap.set("n", "<leader>th", ":exe 'cd %:p:h' | terminal<CR>")

		-- Additional keymap for quick fish terminal
		vim.keymap.set("n", "<leader>tm", function()
			vim.cmd('enew')
			local job_id = vim.fn.termopen('fish', {
				env = {
					TERM = vim.env.TERM or 'xterm-256color',
					COLORTERM = vim.env.COLORTERM,
				}
			})

			vim.schedule(function()
				vim.bo.syntax = ''
				vim.wo.signcolumn = 'no'
				vim.wo.spell = false
				vim.wo.number = false
				vim.wo.relativenumber = false
			end)
		end, { desc = "Open fish terminal" })
	end,
}
