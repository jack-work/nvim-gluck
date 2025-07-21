return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
      ["g."] = { "actions.toggle_hidden", mode = "n" },
    view_options = {
      -- Show files and directories that start with "."
      show_hidden = true,
      }
  },
  -- Optional dependencies
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
    keys = {{ "<leader>-", ":Oil<CR>", desc = "Open parent directory" },
    {
      "<leader>src",
      function()
        require("oil").open('~/src')
      end,
      desc = "Open src folder"
    },
    {
      "<leader>down",
      function()
        require("oil").open('~/Downloads')
      end,
      desc = "Open Downloads folder"
    },
    {
      "<leader>fig",
      function()
        local oil = require("oil")
        local path = (oil.get_cursor_entry() or {}).path or oil.get_current_dir() or vim.fn.expand('%:p:h')
        require("fzf-lua").live_grep({
          prompt_title = "grepping the directory of the current buffer",
          cwd = path
        })
      end,
      desc = "Grep in directory"
    },
    {
      '<leader>ep',
      function()
        local oil = require("oil")
        oil.open(vim.fn.stdpath('config') .. '/lua/plugins')
      end
    },
    {
      '<leader>conf',
      function() require("oil").open('~/.config') end
    },
    {
      '<leader>op',
      function()
        local oil = require("oil");
        vim.fn.setreg("*", oil.get_current_dir()..oil.get_cursor_entry().name)
      end
    }
    },
}
