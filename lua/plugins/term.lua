-- Terminal config — declarative terminal definitions powered by lua/terminal/
return {
	"akinsho/toggleterm.nvim",
	lazy = false,
	config = function()
		require("terminal").setup({
			-- Shell config (fish on Linux)
			shell = {
				shell = "fish",
				shellcmdflag = "-c",
				shellredir = ">%s 2>&1",
				shellpipe = "2>&1 | tee",
				shellquote = "",
				shellxquote = "",
			},
			-- argv used by termopen for direct invocation
			shell_argv = { "fish" },

			toggleterm = {
				size = 10,
				hide_numbers = true,
				shade_terminals = true,
				shading_factor = 2,
				start_in_insert = true,
				insert_mappings = true,
				persist_size = true,
				close_on_exit = true,
				direction = "float",
				float_opts = {
					border = "curved",
					winblend = 0,
					highlights = { border = "Normal", background = "Normal" },
				},
			},

			terminals = {
				{
					name = "aichat",
					keymap = "<leader>ai",
					cmd = "aichat -r coder",
					desc = "Toggle AI Chat",
					singleton = true,
					use_ctrl = true,
					direction = "float",
					float_opts = { border = "curved", width = 150, height = 50 },
				},
				{
					name = "yipyap",
					keymap = "<leader>yy",
					cmd = "yipyap",
					desc = "Toggle yipyap",
					singleton = true,
					direction = "float",
					float_opts = { border = "curved", width = 80, height = 50 },
				},
			},

			custom_keymaps = {
				{
					mode = "n",
					keymap = "<leader>th",
					desc = "Open terminal in current dir",
					action = function()
						vim.cmd("enew")
						vim.fn.termopen("fish", { cwd = vim.fn.expand("%:p:h") })
						vim.cmd.startinsert()
					end,
				},
				{
					mode = "n",
					keymap = "<leader>tm",
					desc = "Open terminal here (oil-aware)",
					action = function()
						local ok, oil = pcall(require, "oil")
						local dir
						if ok and oil.get_current_dir then
							dir = oil.get_current_dir()
						else
							dir = vim.fn.expand("%:p:h")
						end
						vim.cmd.enew()
						vim.fn.termopen("fish", { cwd = dir })
						vim.cmd.startinsert()
					end,
				},
			},

			override_terminal = true,
		})
	end,
}
