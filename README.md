# nvim

Neovim config. Requires **Neovim 0.12+** (treesitter `main` branch, `vim.lsp.config`, ui2).

## Layout

```
init.lua              ordering only — a table of contents, no logic
lua/config/           editor behaviour, loaded explicitly from init.lua
lua/plugins/          one file per plugin, auto-imported by lazy.nvim
lua/terminal/         the declarative terminal definitions term.lua drives
snippets/             LuaSnip snippets, loaded by filetype
```

### `lua/config/`

| file | what it owns |
|---|---|
| `lazy.lua` | bootstraps lazy.nvim, sets `<leader>`. Runs before any plugin. |
| `clipboard.lua` | cross-platform yank/paste. Explains why OSC 52 *paste* is banned. |
| `options.lua` | plain `vim.opt`, wrap rules, filetype detection, provider opt-outs |
| `indent.lua` | **one table**: every language indents the way its own formatter does |
| `keymaps.lua` | global maps only |
| `ui.lua` | cmdline overlay (ui2) + message routing |
| `lsplog.lua` | LSP logging, off by default and size-capped |
| `insert.lua` | insert-mode helpers |
| `msg_router.lua` | `ext_messages` → `vim.notify` |
| `pyenv.lua` | points pyright at the project's real interpreter (nix/venv) |
| `readline.lua` | bash-style cmdline editing |

## Two rules worth not re-learning

**Indentation follows the formatter, not taste.** `config/indent.lua` is a
single table, and every entry in it is whatever that language's canonical
formatter emits — gofmt, rustfmt, black/ruff, prettier, taplo, nixfmt,
`terraform fmt`, shfmt, stylua. If the editor and the formatter disagree, every
file fights you on save. Precedence runs defaults → table → `.editorconfig`,
so the repo you are in always outranks your preference.

Ask any buffer why it looks the way it does:

```
:IndentInfo     explain this buffer's indentation and where it came from
:IndentReset    re-derive it from the table
<leader>ul      show whitespace
```

**A map that loads a plugin belongs in that plugin's `keys = {}`.** Putting it
in `config/keymaps.lua` creates the mapping eagerly and defeats lazy.nvim's
handler. Buffer-local maps live next to what they belong to (LSP maps in
`plugins/lsp.lua` under `LspAttach`, Rust maps in `plugins/rust.lua`).

## Adding a language

1. `lua/config/indent.lua` — add the filetype to the group matching its formatter.
2. `lua/plugins/conform.lua` — add the formatter, wrapped in `guard()` (or
   `first()` for alternatives like `prettierd → prettier`). Missing binaries are
   skipped silently rather than erroring on every save.
3. `lua/plugins/lsp.lua` — add the parser to the treesitter `ensure` list and the
   server to mason's `ensure_installed`. **Install the parser**, or the
   `#missing > 0` branch loads `nvim-treesitter.install` on every startup.

## Housekeeping

```
:Lazy               plugin manager
:Mason              LSP/tool installer
:ConformInfo        which formatter will run here, and why
:FormatRecheck      re-scan for formatter binaries installed mid-session
:LspLog             open the LSP log; `:LspLog debug` to start recording
:checkhealth
```

LSP logging is **off** by default. It is not a default worth restoring: the log
has no rotation and no size cap, and a chatty server (markdown-oxide reports
routine progress at `WARN`) took it to 350 MB. `config/lsplog.lua` also
truncates anything over 50 MB at startup.

## Startup

~55 ms. Two things reliably cost more than they look:

- A treesitter `ensure` list containing parsers that are not installed forces
  `nvim-treesitter.install` to load every startup (+1.4 ms).
- `opts = { ... require("plugin.mod") ... }` in a lazy spec runs that `require`
  during startup, because lazy.nvim evaluates spec files eagerly. Use
  `opts = function() return { ... } end`.

Measure before and after, don't guess:

```sh
nvim --headless --startuptime /tmp/st -c 'qa!' && grep 'NVIM STARTED' /tmp/st
```

## Before adding plugin options

Check the option exists. This config accumulated a block of `snacks.nvim`
settings — `command`, `breadcrumbs`, `statusline` — that snacks has never had.
Unknown keys are silently ignored, so it looked configured and did nothing:

```sh
ls ~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/
```
