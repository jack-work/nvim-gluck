-- Insert-family keymaps under the <leader>i prefix.
-- Each mapping puts (or yanks) a small generated string: dates, GUIDs, etc.

local M = {}

local function put_line(text)
	vim.api.nvim_put({ text }, 'l', true, true)
end

local function generate_guid()
	math.randomseed(os.time() + os.clock() * 1000000)
	local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	return (template:gsub('[xy]', function(c)
		local v = (c == 'x') and math.random(0, 15) or math.random(8, 11)
		return string.format('%x', v)
	end))
end

function M.setup()
	-- which-key group label (no-op if which-key isn't loaded)
	pcall(function()
		require('which-key').add({ { '<leader>i', group = 'insert' } })
	end)

	vim.keymap.set('n', '<leader>idate', function()
		put_line(tostring(os.date()))
	end, { desc = 'Insert current date' })

	vim.keymap.set('n', '<leader>iisod', function()
		put_line(tostring(os.date('%Y-%m-%d')))
	end, { desc = 'Insert current date (ISO 8601: YYYY-MM-DD)' })

	vim.api.nvim_create_user_command('GUID', function()
		local guid = generate_guid()
		vim.fn.setreg('"', guid)
		vim.fn.setreg('+', guid)
		vim.notify('GUID copied: ' .. guid)
	end, { desc = 'Generate a GUID and copy to clipboard' })

	vim.keymap.set('n', '<leader>iguid', function()
		vim.cmd('GUID')
	end, { desc = 'Insert/copy GUID' })
end

return M
