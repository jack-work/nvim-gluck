-- Neovim entry point.
--
-- This file is deliberately just an ordering. Anything with substance lives in
-- lua/config/ next to its own explanation:
--
--   config/clipboard.lua  cross-platform yank/paste, and why OSC 52 paste is banned
--   config/options.lua    plain editor options, wrap rules, provider opt-outs
--   config/indent.lua     one table: each language indents the way its formatter does
--   config/keymaps.lua    global maps (plugin-loading maps live in each plugin spec)
--   config/ui.lua         cmdline overlay + message routing
--   config/lsplog.lua     LSP logging, capped (it had grown to 350 MB)
--   config/insert.lua     insert-mode helpers
--   config/msg_router.lua ext_messages -> vim.notify
--   config/pyenv.lua      point pyright at the project's real interpreter
--
-- Order matters in three places: clipboard runs before plugins so nothing
-- observes a half-configured provider; config.lazy sets <leader> and loads
-- every plugin; ui.lua needs snacks.notifier to exist, so it comes after.

require("config.clipboard").setup()

require("config.lazy")

require("config.ui").setup()
require("config.options").setup()
require("config.indent").setup()
require("config.keymaps").setup()
require("config.lsplog").setup()
require("config.insert").setup()
