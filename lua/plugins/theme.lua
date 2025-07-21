return {
	-- Tokyo Night Colorscheme
	{
		"folke/tokyonight.nvim",
		lazy = false, -- Load immediately since it's our main colorscheme
		priority = 1000, -- Load before other plugins
		opts = {
			-- Four variants: "storm", "moon", "night", "day"
			style = "storm", -- The theme comes in four variants: storm, moon, night and day
			light_style = "day", -- The theme is used when the background is set to light
			transparent = false, -- Enable this to disable setting the background color
			terminal_colors = true, -- Configure the colors used when opening a :terminal in Neovim
			styles = {
				-- Style to be applied to different syntax groups
				comments = { italic = true },
				keywords = { italic = true },
				functions = {},
				variables = {},
				-- Background styles. Can be "dark", "transparent" or "normal"
				sidebars = "dark", -- style for sidebars, see below
				floats = "dark", -- style for floating windows
			},
			sidebars = { "qf", "help" }, -- Set a darker background on sidebar-like windows
			day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style
			hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines
			dim_inactive = false, -- dims inactive windows
			lualine_bold = false, -- When `true`, section headers in the lualine theme will be bold

			--- You can override specific color groups to use other groups or a hex color
			--- function will be called with a ColorScheme table
			-- on_colors = function()
			-- 	-- Customize specific colors if needed
			-- 	-- colors.hint = colors.orange
			-- 	-- colors.error = "#ff0000"
			-- end,

			--- You can override specific highlights to use other groups or a hex color
			--- function will be called with a Highlights and ColorScheme table
			on_highlights = function(highlights, colors)
				-- Custom highlight overrides
				highlights.Comment = {
					fg = colors.blue5,
					italic = true,
				}
			end,
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight")
		end,
	},
}
