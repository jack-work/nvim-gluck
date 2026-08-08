-- Readline (bash/emacs) editing for Neovim's command-line mode.
--
-- Cmdline mode natively gives you only a handful of readline keys
-- (<C-b>/<C-e>/<C-w>/<C-u>/<C-h>) and spends several others on vim-specific
-- jobs (<C-a> inserts all wildcard matches, <C-d> lists completions,
-- <C-f> opens the cmdline window, <C-k> is digraphs). This module rebinds
-- the cmdline to bash's readline defaults, backed by a one-slot kill ring so
-- <C-k>/<C-u>/<C-w>/<M-d> feed <C-y> the way a real terminal does.
--
-- Completion-menu keys (Tab, <C-n>/<C-p>, <C-f> to accept) live in
-- lua/plugins/blink.lua's `cmdline.keymap` and are deliberately chosen to not
-- collide with anything here.

local M = {}

--- One-slot kill ring, shared by every kill command.
local killring = ''

local WORD = '[%w_]'

local function line_pos()
	-- getcmdpos() is 1-based and points at the char *after* the cursor.
	return vim.fn.getcmdline(), vim.fn.getcmdpos()
end

local function set(line, pos) vim.fn.setcmdline(line, pos) end

--- Start byte of the word before `pos` (readline backward-word).
--- @param class string lua pattern for "word character"
local function prev_word(line, pos, class)
	local i = pos - 1
	while i >= 1 and not line:sub(i, i):match(class) do i = i - 1 end
	while i >= 1 and line:sub(i, i):match(class) do i = i - 1 end
	return i + 1
end

--- Byte just past the end of the word after `pos` (readline forward-word).
local function next_word(line, pos, class)
	local i, n = pos, #line
	while i <= n and not line:sub(i, i):match(class) do i = i + 1 end
	while i <= n and line:sub(i, i):match(class) do i = i + 1 end
	return i
end

-- ---------------------------------------------------------------- motions --

function M.beginning_of_line() vim.fn.setcmdpos(1) end

function M.end_of_line() vim.fn.setcmdpos(#vim.fn.getcmdline() + 1) end

function M.backward_word()
	local line, pos = line_pos()
	vim.fn.setcmdpos(prev_word(line, pos, WORD))
end

function M.forward_word()
	local line, pos = line_pos()
	vim.fn.setcmdpos(next_word(line, pos, WORD))
end

-- ------------------------------------------------------------------ kills --

function M.kill_line() -- <C-k>
	local line, pos = line_pos()
	killring = line:sub(pos)
	set(line:sub(1, pos - 1), pos)
end

function M.backward_kill_line() -- <C-u>  (bash: kill to start, not whole line)
	local line, pos = line_pos()
	killring = line:sub(1, pos - 1)
	set(line:sub(pos), 1)
end

function M.kill_word() -- <M-d>
	local line, pos = line_pos()
	local e = next_word(line, pos, WORD)
	killring = line:sub(pos, e - 1)
	set(line:sub(1, pos - 1) .. line:sub(e), pos)
end

--- @param class string word-character class: WORD for <M-BS>, non-space for <C-w>
local function backward_kill(class)
	local line, pos = line_pos()
	local s = prev_word(line, pos, class)
	killring = line:sub(s, pos - 1)
	set(line:sub(1, s - 1) .. line:sub(pos), s)
end

function M.backward_kill_word() backward_kill(WORD) end          -- <M-BS>
function M.unix_word_rubout() backward_kill('%S') end            -- <C-w>

function M.yank() -- <C-y>
	if killring == '' then return end
	local line, pos = line_pos()
	set(line:sub(1, pos - 1) .. killring .. line:sub(pos), pos + #killring)
end

function M.delete_char() -- <C-d>
	local line, pos = line_pos()
	if pos > #line then return end -- bash would EOF; we no-op
	set(line:sub(1, pos - 1) .. line:sub(pos + 1), pos)
end

function M.transpose_chars() -- <C-t>
	local line, pos = line_pos()
	if #line < 2 or pos < 2 then return end
	if pos > #line then -- at EOL: swap the last two
		set(line:sub(1, #line - 2) .. line:sub(#line) .. line:sub(#line - 1, #line - 1), pos)
	else
		set(line:sub(1, pos - 2) .. line:sub(pos, pos) .. line:sub(pos - 1, pos - 1) .. line:sub(pos + 1), pos + 1)
	end
end

-- ------------------------------------------------------------------- case --

local function case_word(fn)
	local line, pos = line_pos()
	local e = next_word(line, pos, WORD)
	set(line:sub(1, pos - 1) .. fn(line:sub(pos, e - 1)) .. line:sub(e), e)
end

function M.upcase_word() case_word(string.upper) end                                   -- <M-u>
function M.downcase_word() case_word(string.lower) end                                 -- <M-l>
function M.capitalize_word() case_word(function(s)                                     -- <M-c>
	return (s:gsub('(%a)', string.upper, 1))
end) end

-- ------------------------------------------------------------------ setup --

function M.setup()
	-- Free <C-f>: it's readline's forward-char / blink's accept. Move the
	-- command-line window to <C-o>, then expose it at bash's <C-x><C-e>.
	vim.o.cedit = vim.keycode('<C-o>')

	local map = function(lhs, rhs, desc)
		vim.keymap.set('c', lhs, rhs, { desc = 'readline: ' .. desc, silent = true })
	end

	-- Motions. <C-f>/<C-b> stay plain rhs so blink's `fallback_to_mappings`
	-- can hand them back to us when no completion menu is open.
	map('<C-a>', '<Home>', 'beginning-of-line')
	map('<C-e>', M.end_of_line, 'end-of-line')
	map('<C-b>', '<Left>', 'backward-char')
	map('<C-f>', '<Right>', 'forward-char')
	map('<M-b>', M.backward_word, 'backward-word')
	map('<M-f>', M.forward_word, 'forward-word')

	-- Kills & yank.
	map('<C-k>', M.kill_line, 'kill-line')
	map('<C-u>', M.backward_kill_line, 'backward-kill-line')
	map('<C-w>', M.unix_word_rubout, 'unix-word-rubout')
	map('<M-BS>', M.backward_kill_word, 'backward-kill-word')
	map('<M-d>', M.kill_word, 'kill-word')
	map('<C-y>', M.yank, 'yank')
	map('<C-d>', M.delete_char, 'delete-char')
	map('<C-t>', M.transpose_chars, 'transpose-chars')

	-- Case.
	map('<M-u>', M.upcase_word, 'upcase-word')
	map('<M-l>', M.downcase_word, 'downcase-word')
	map('<M-c>', M.capitalize_word, 'capitalize-word')

	-- Abort, and bash's edit-command-line (full vim buffer, visual mode, the lot).
	map('<C-g>', '<C-c>', 'abort')
	map('<C-x><C-e>', '<C-o>', 'edit-command-line (cmdwin)')

	-- <C-n>/<C-p> are left to Neovim's history recall; blink intercepts them
	-- only while the completion menu is open. <C-r> stays vim's "insert
	-- register" — too useful to trade for reverse-i-search.
end

return M
