-- Resolve the Python interpreter a project actually uses, so pyright stops
-- crying "Import 'duckdb' could not be resolved" on nix-flake projects.
--
-- Order of preference:
--   1. $VIRTUAL_ENV (an activated venv wins, always)
--   2. ./.venv, ./venv
--   3. the interpreter inside `nix develop` (flake.nix) — resolved async + cached
--   4. whatever `python3` is on PATH
--
-- The nix lookup is slow (seconds, sometimes an eval), so it never blocks:
-- a cache miss returns PATH's python, kicks off a background job, and restarts
-- pyright once the real answer lands. Cache is keyed on flake.lock mtime.

local M = {}

local uv = vim.uv or vim.loop
local cache_file = vim.fn.stdpath("cache") .. "/pyenv.json"
local cache = nil
local inflight = {}

local function load_cache()
	if cache then
		return cache
	end
	cache = {}
	local f = io.open(cache_file, "r")
	if f then
		local ok, decoded = pcall(vim.json.decode, f:read("*a"))
		f:close()
		if ok and type(decoded) == "table" then
			cache = decoded
		end
	end
	return cache
end

local function save_cache()
	local f = io.open(cache_file, "w")
	if f then
		f:write(vim.json.encode(cache))
		f:close()
	end
end

local function stamp(root)
	local st = uv.fs_stat(root .. "/flake.lock") or uv.fs_stat(root .. "/flake.nix")
	return st and tostring(st.mtime.sec) or "0"
end

--- Push a resolved interpreter into a live pyright client (no restart needed:
--- pyright re-resolves its search paths on didChangeConfiguration).
--- NOTE: mutating config.settings is useless post-init — vim.lsp.Client copies
--- the reference at create time, before before_init runs. Set client.settings.
function M.apply(client, path)
	if vim.tbl_get(client.settings or {}, "python", "pythonPath") == path then
		return false
	end
	client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
		python = { pythonPath = path },
	})
	client:notify("workspace/didChangeConfiguration", { settings = client.settings })
	return true
end

--- Ask `nix develop` for its python3, in the background.
local function resolve_nix(root)
	if inflight[root] then
		return
	end
	inflight[root] = true
	vim.system(
		{ "nix", "develop", "--command", "sh", "-c", "command -v python3" },
		{ cwd = root, text = true },
		vim.schedule_wrap(function(res)
			inflight[root] = nil
			local path = vim.trim(res.stdout or "")
			if res.code ~= 0 or path == "" or not uv.fs_stat(path) then
				return
			end
			load_cache()[root] = { python = path, stamp = stamp(root) }
			save_cache()
			-- Retro-fit any client that started before we had the answer.
			for _, c in ipairs(vim.lsp.get_clients({ name = "pyright" })) do
				if c.root_dir == root and M.apply(c, path) then
					vim.notify("pyright: using " .. path, vim.log.levels.INFO)
				end
			end
		end)
	)
end

--- @param root string|nil project root
--- @return string path to a python interpreter
function M.python(root)
	if vim.env.VIRTUAL_ENV then
		local p = vim.env.VIRTUAL_ENV .. "/bin/python"
		if uv.fs_stat(p) then
			return p
		end
	end

	root = root or uv.cwd()

	for _, dir in ipairs({ ".venv", "venv" }) do
		local p = root .. "/" .. dir .. "/bin/python"
		if uv.fs_stat(p) then
			return p
		end
	end

	if uv.fs_stat(root .. "/flake.nix") then
		local hit = load_cache()[root]
		if hit and hit.stamp == stamp(root) and uv.fs_stat(hit.python) then
			return hit.python
		end
		resolve_nix(root) -- fills the cache, then restarts pyright
	end

	return vim.fn.exepath("python3")
end

return M
