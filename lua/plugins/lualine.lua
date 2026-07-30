-- ~/.config/nvim/lua/plugins/lualine.lua
return {
	'nvim-lualine/lualine.nvim',
	dependencies = { 'nvim-tree/nvim-web-devicons', lazy = true },

	event = 'VeryLazy', -- load only after UIEnter
	config = function(_, opts)
		require('lualine').setup(opts)
		-- Force a redraw the instant macro recording starts/stops so the
		-- indicator doesn't lag behind cursor motion.
		vim.api.nvim_create_autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
			callback = function()
				-- RecordingLeave fires *before* reg_recording() clears, so defer.
				vim.schedule(function() require('lualine').refresh() end)
			end,
		})
	end,
	opts = function()
		----------------------------------------------------------
		-- 1. Custom colors: merge with the active colorscheme
		----------------------------------------------------------
		local colors = {
			-- get the *actual* colors from the current colorscheme
			bg       = '#NONE', -- transparent
			fg       = { fg = 'fg' },
			yellow   = { fg = '#e0af68' },
			cyan     = { fg = '#56b6c2' },
			darkblue = { fg = '#081633' },
			green    = { fg = '#98c379' },
			orange   = { fg = '#ff9640' },
			violet   = { fg = '#c678dd' },
			magenta  = { fg = '#c678dd' },
			blue     = { fg = '#61afef' },
			red      = { fg = '#e06c75' },
		}

		----------------------------------------------------------
		-- 2. Icons
		----------------------------------------------------------
		local icons = {
			diagnostics = {
				Error = '󰅙 ',
				Warn  = '󰀪 ',
				Hint  = '󰌶 ',
				Info  = '󰋽 ',
			},
			git = {
				added    = '󰐗 ',
				modified = '󰏬 ',
				removed  = '󰍴 ',
			},
		}

		----------------------------------------------------------
		-- 3. Components
		----------------------------------------------------------
		local mode = {
			'mode',
			fmt = function(str) return str:sub(1, 1) end, -- single letter
			padding = { left = 1, right = 0 },
		}

		local macro = {
			function()
				local reg = vim.fn.reg_recording()
				if reg == '' then return '' end
				return '󰑊 REC @' .. reg
			end,
			cond = function() return vim.fn.reg_recording() ~= '' end,
			color = { fg = '#ff5555', gui = 'bold' },
			padding = { left = 1, right = 1 },
		}

		local filename = {
			'filename',
			path = 1, -- relative path
			shorting_target = 40, -- shorten long paths
			symbols = { modified = ' ', readonly = ' 󰌾', unnamed = '' },
		}

		local diagnostics = {
			'diagnostics',
			sources = { 'nvim_diagnostic' },
			symbols = icons.diagnostics,
		}

		local diff = {
			'diff',
			symbols = icons.git,
			colored = true,
		}

		----------------------------------------------------------
		-- 4. Final config
		----------------------------------------------------------
		return {
			options = {
				theme                = 'auto', -- follow :colorscheme
				globalstatus         = true, -- one line for all windows
				component_separators = { left = '│', right = '│' },
				section_separators   = { left = '', right = '' },
				disabled_filetypes   = { statusline = { 'alpha', 'dashboard', 'lazy' } },
			},

			sections = {
				lualine_a = { mode, macro },
				lualine_b = { 'branch', diff },
				lualine_c = { filename },
				lualine_x = { diagnostics, 'filetype' },
				lualine_y = { 'progress' },
				lualine_z = { 'location' },
			},

			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { filename },
				lualine_x = { 'location' },
				lualine_y = {},
				lualine_z = {},
			},

			extensions = { 'fugitive', 'nvim-tree', 'lazy' },
		}
	end,
}
