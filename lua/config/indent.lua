-- Indentation, decided once, from one table.
--
-- The rule that makes this stop feeling random: **the editor must agree with
-- the language's canonical formatter.** If nvim indents Python at 8 and black
-- reindents to 4 on save, every file fights you. So each entry below is not a
-- taste call — it is whatever that language's own formatter emits.
--
--   go/gomod/gowork  tabs, 8   gofmt
--   make, gitconfig  tabs, 8   the file format literally requires tabs
--   c / cpp          tabs, 8   kernel & nvim style
--   lua              tabs, 4   stylua's default (indent_type = "Tabs")
--   rust             4 sp      rustfmt
--   python           4 sp      PEP 8 / black / ruff
--   js/ts/json/css/  2 sp      prettier
--   html/yaml/md
--   toml             2 sp      taplo
--   nix              2 sp      nixfmt / alejandra
--   terraform/hcl    2 sp      terraform fmt
--   sh/bash          2 sp      Google shell style (shfmt -i 2)
--
-- Two subtleties that cause most of the "why does this look wrong" moments:
--
-- 1. 'tabstop' is left at 8 for every *space*-indented language. tabstop is
--    the display width of a literal \t, and 8 is what every other tool on
--    earth assumes. Setting tabstop=2 for yaml (the old config did) means a
--    stray tab renders 2 wide here and 8 wide in `git diff`, on GitHub, and in
--    everyone else's editor. Indent size for space languages is 'shiftwidth' +
--    'softtabstop'; tabstop is not the knob.
--
-- 2. 'smartindent' is off. It is a pre-treesitter C heuristic that, among
--    other crimes, yanks lines starting with `#` to column 0 — which is every
--    Python and shell comment. Treesitter's indentexpr (set in lsp.lua) plus
--    plain 'autoindent' does the job properly.
--
-- Precedence, lowest to highest:
--   global defaults  ->  this table (FileType)  ->  .editorconfig  ->  you
-- Neovim's built-in editorconfig support runs on BufReadPost/BufNewFile, i.e.
-- after FileType, so a project's .editorconfig always wins. That is correct:
-- the repo you are in outranks your preference.

local M = {}

-- tabs = indent with real \t. width = one indent level, in columns.
M.styles = {}

local function define(spec, fts)
	for _, ft in ipairs(fts) do
		M.styles[ft] = spec
	end
end

-- ── real tabs ──────────────────────────────────────────────────────────────
define({ tabs = true, width = 8 }, {
	"go", "gomod", "gowork", "gosum", "gotmpl", -- gofmt
	"make", "automake", "gitconfig", "snakemake", -- tabs are load-bearing
	"c", "cpp", "objc", "h",
})
define({ tabs = true, width = 4 }, { "lua" }) -- stylua default

-- ── 4 spaces ───────────────────────────────────────────────────────────────
define({ tabs = false, width = 4 }, {
	"rust",                                     -- rustfmt
	"python",                                   -- PEP 8 / black / ruff
	"java", "kotlin", "scala", "groovy", "cs", "php", "swift",
	"fish", "ps1",
	"tex", "plaintex", "bib",
})

-- ── 2 spaces ───────────────────────────────────────────────────────────────
define({ tabs = false, width = 2 }, {
	-- prettier's domain
	"javascript", "javascriptreact", "typescript", "typescriptreact",
	"json", "jsonc", "jsonl", "json5", "yaml", "yaml.ansible",
	"css", "scss", "less", "html", "xml", "svelte", "vue", "astro",
	"graphql", "markdown", "markdown_inline", "mdx", "handlebars",
	-- everything else with a 2-space community formatter
	"toml",                                     -- taplo
	"nix",                                      -- nixfmt / alejandra
	"terraform", "hcl", "terraform-vars",       -- terraform fmt
	"sh", "bash", "zsh",                        -- shfmt -i 2
	"ruby", "eruby", "elixir", "erlang",
	"haskell", "elm", "ocaml", "nim", "zig",
	"proto", "thrift", "cue", "jsonnet",
	"dockerfile", "just", "vim", "query", "sql", "helm",
	"http", "rest",                             -- kulala
})

-- Anything not listed keeps the global default below. Wide and airy, per
-- preference — for prose, logs, .txt, and one-off config formats nobody has
-- written a formatter for, there is no idiom to obey.
M.default = { tabs = false, width = 8 }

--- Was this buffer's indent already decided by an .editorconfig?
local function editorconfig_owns(bufnr)
	local ec = vim.b[bufnr].editorconfig
	return type(ec) == "table"
		and (ec.indent_style ~= nil or ec.indent_size ~= nil or ec.tab_width ~= nil)
end

--- Apply the idiomatic style for `ft` to `bufnr`.
function M.apply(bufnr, ft)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if editorconfig_owns(bufnr) then
		return
	end
	local s = M.styles[ft] or M.default
	local bo = vim.bo[bufnr]
	if s.tabs then
		bo.expandtab = false
		bo.tabstop = s.width      -- here tabstop *is* the indent size
		bo.softtabstop = 0        -- 0 => <Tab> inserts a real tab
		bo.shiftwidth = s.width
	else
		bo.expandtab = true
		bo.tabstop = 8            -- see note 1 above: never retune this
		bo.softtabstop = s.width
		bo.shiftwidth = s.width
	end
end

function M.setup()
	local d = M.default
	vim.opt.expandtab = not d.tabs
	vim.opt.tabstop = 8
	vim.opt.softtabstop = d.width
	vim.opt.shiftwidth = d.width

	vim.opt.autoindent = true
	vim.opt.smartindent = false -- see note 2 above
	vim.opt.shiftround = true   -- >> snaps to a multiple of shiftwidth

	-- Make whitespace legible on demand — the fastest way to answer
	-- "why is this line indented weirdly". <leader>ul toggles.
	vim.opt.listchars = {
		tab = "→ ",
		trail = "·",
		nbsp = "␣",
		extends = "›",
		precedes = "‹",
	}

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("UserIndent", { clear = true }),
		callback = function(ev)
			M.apply(ev.buf, ev.match)
		end,
	})

	vim.keymap.set("n", "<leader>ul", function()
		vim.wo.list = not vim.wo.list
	end, { desc = "Toggle whitespace display" })

	-- Re-derive indent from the table, discarding manual/editorconfig changes.
	vim.api.nvim_create_user_command("IndentReset", function()
		vim.b.editorconfig = nil
		M.apply(0, vim.bo.filetype)
		vim.cmd("IndentInfo")
	end, { desc = "Re-apply the idiomatic indent style for this filetype" })

	-- "Why does this buffer indent like this?"
	vim.api.nvim_create_user_command("IndentInfo", function()
		local ft = vim.bo.filetype
		local source = M.styles[ft] and ("indent.lua table (" .. ft .. ")")
			or "indent.lua default (no rule for " .. (ft ~= "" and ft or "no filetype") .. ")"
		if editorconfig_owns(0) then
			source = ".editorconfig (overrides the table)"
		end
		local style = vim.bo.expandtab
			and (vim.bo.shiftwidth .. " spaces")
			or ("tabs, " .. vim.bo.tabstop .. " wide")
		vim.notify(table.concat({
			"indent : " .. style,
			"source : " .. source,
			"opts   : et=" .. tostring(vim.bo.expandtab)
				.. " ts=" .. vim.bo.tabstop
				.. " sw=" .. vim.bo.shiftwidth
				.. " sts=" .. vim.bo.softtabstop,
			"indentexpr: " .. (vim.bo.indentexpr ~= "" and vim.bo.indentexpr or "(none)"),
		}, "\n"), vim.log.levels.INFO, { title = "IndentInfo" })
	end, { desc = "Explain this buffer's indentation" })
end

return M
