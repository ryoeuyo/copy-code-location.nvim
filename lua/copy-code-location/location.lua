--- Path and location formatting.
local config = require("copy-code-location.config")

local M = {}

--- @param path string
--- @return string
local function normalize(path)
  path = path:gsub("\\", "/")
  path = path:gsub("/+$", "")
  if path == "" then
    return "/"
  end
  return path
end

--- Absolute, normalized path of the buffer, or nil for unnamed buffers.
--- @param bufnr integer
--- @return string|nil
local function buffer_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end
  return normalize(vim.fn.fnamemodify(name, ":p"))
end

--- Fallback for Neovim versions without `vim.fs.root()`.
--- @param bufnr integer
--- @param markers string[]
--- @return string|nil
local function find_root(bufnr, markers)
  if vim.fs and vim.fs.root then
    return vim.fs.root(bufnr, markers)
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end

  local dir = vim.fn.fnamemodify(name, ":p:h")
  while dir ~= "" do
    for _, marker in ipairs(markers) do
      local candidate = dir .. "/" .. marker
      if vim.fn.filereadable(candidate) == 1 or vim.fn.isdirectory(candidate) == 1 then
        return dir
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

--- Directory the location is made relative to.
--- @param bufnr integer|nil
--- @return string
function M.root(bufnr)
  bufnr = bufnr or 0
  local relative_to = config.options.relative_to

  if type(relative_to) == "function" then
    local root = relative_to(bufnr)
    if type(root) == "string" and root ~= "" then
      return normalize(vim.fn.fnamemodify(root, ":p"))
    end
  elseif type(relative_to) == "string" and relative_to ~= "" then
    if relative_to == "cwd" then
      return normalize(vim.fn.getcwd())
    elseif relative_to ~= "git" then
      return normalize(vim.fn.fnamemodify(relative_to, ":p"))
    end
  end

  local markers = config.options.root_markers or {}
  if #markers > 0 then
    local root = find_root(bufnr, markers)
    if root and root ~= "" then
      return normalize(root)
    end
  end

  return normalize(vim.fn.getcwd())
end

--- Path of the buffer relative to the project root.
--- @param bufnr integer|nil
--- @return string|nil
function M.path(bufnr)
  bufnr = bufnr or 0
  local absolute = buffer_path(bufnr)
  if not absolute then
    return nil
  end

  local root = M.root(bufnr)
  do
    local prefix = root .. "/"
    if absolute:sub(1, #prefix) == prefix then
      return absolute:sub(#prefix + 1)
    end
  end

  -- Buffer lives outside the root: prefer cwd, otherwise use an absolute path.
  local cwd = normalize(vim.fn.getcwd())
  local cwd_prefix = cwd .. "/"
  if absolute:sub(1, #cwd_prefix) == cwd_prefix then
    return absolute:sub(#cwd_prefix + 1)
  end

  return absolute
end

--- Builds `@path:line`, `@path:first-last` or `@path` for the buffer.
--- @param bufnr integer|nil
--- @param first integer|nil 1-based first line, omit for a whole-file location.
--- @param last integer|nil 1-based last line (inclusive), defaults to `first`.
--- @return string|nil
function M.format(bufnr, first, last)
  local path = M.path(bufnr)
  if not path then
    return nil
  end

  local location = (config.options.prefix or "") .. path
  if first then
    last = last or first
    if last == first then
      location = location .. ":" .. first
    else
      location = location .. ":" .. first .. "-" .. last
    end
  end

  return location
end

return M
