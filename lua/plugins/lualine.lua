return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"folke/snacks.nvim" -- Ensure snacks loads before lualine
	},
	event = "VeryLazy",
	opts = function()
		-- Helper function to get breadcrumbs from snacks
		local function snacks_breadcrumbs()
			if package.loaded["snacks"] and require("snacks").breadcrumbs then
				local breadcrumbs = require("snacks").breadcrumbs.get()
				if breadcrumbs and #breadcrumbs > 0 then
					return table.concat(breadcrumbs, " › ")
				end
			end
			return ""
		end

		-- Custom component for showing if in a git repo
		local function git_repo_icon()
			if vim.fn.isdirectory('.git') == 1 or vim.fn.finddir('.git', '.;') ~= '' then
				return ""
			end
			return ""
		end

		-- LSP clients component
		local function lsp_clients()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				return "No LSP"
			end

			local client_names = {}
			for _, client in ipairs(clients) do
				table.insert(client_names, client.name)
			end
			return " " .. table.concat(client_names, ", ")
		end

		return {
			options = {
				theme = "auto", -- Automatically matches your colorscheme
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = true, -- Single statusline for all windows
				disabled_filetypes = {
					statusline = { "dashboard", "alpha", "starter" },
				},
			},
			sections = {
				lualine_a = {
					{
						"mode",
						fmt = function(str)
							return str:sub(1, 1) -- Show only first character of mode
						end,
					},
				},
				lualine_b = {
					{
						"branch",
						icon = "",
						color = { gui = "bold" },
					},
					{
						"diff",
						symbols = { added = " ", modified = " ", removed = " " },
						diff_color = {
							added = { fg = "#98be65" },
							modified = { fg = "#ECBE7B" },
							removed = { fg = "#ec5f67" },
						},
					},
				},
				lualine_c = {
					{
						"filename",
						path = 1, -- Show relative path
						symbols = {
							modified = " ●",
							readonly = " ",
							unnamed = "[No Name]",
						},
					},
					{
						-- Breadcrumbs from snacks.nvim
						snacks_breadcrumbs,
						cond = function()
							return snacks_breadcrumbs() ~= ""
						end,
						color = { fg = "#7aa2f7", gui = "italic" },
						separator = "",
					},
				},
				lualine_x = {
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },
						symbols = { error = " ", warn = " ", info = " ", hint = " " },
						diagnostics_color = {
							error = { fg = "#ec5f67" },
							warn = { fg = "#ECBE7B" },
							info = { fg = "#008080" },
							hint = { fg = "#10B981" },
						},
					},
					{
						-- LSP clients
						lsp_clients,
						icon = "",
						color = { fg = "#7aa2f7" },
					},
					{
						-- Git repository indicator
						git_repo_icon,
						color = { fg = "#f7768e" },
					},
					{
						"filetype",
						icons_enabled = true,
						icon_only = false,
						colored = true,
					},
				},
				lualine_y = {
					{
						"progress",
						fmt = function()
							return "%P/%L"
						end,
					},
					{
						"location",
						padding = { left = 0, right = 1 },
					},
				},
				lualine_z = {
					{
						"datetime",
						style = "%H:%M",
						color = { fg = "#7aa2f7", gui = "bold" },
					},
				},
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = {
					{
						"filename",
						path = 1,
						symbols = {
							modified = " ●",
							readonly = " ",
							unnamed = "[No Name]",
						},
					},
				},
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			extensions = {
				"neo-tree",
				"lazy",
				"mason",
				"oil",
				"trouble",
				"fugitive",
			},
		}
	end,
	config = function(_, opts)
		require("lualine").setup(opts)

		-- Auto-refresh lualine when snacks breadcrumbs update
		vim.api.nvim_create_autocmd({ "CursorMoved", "BufEnter" }, {
			callback = function()
				require("lualine").refresh()
			end,
		})
	end,
}
