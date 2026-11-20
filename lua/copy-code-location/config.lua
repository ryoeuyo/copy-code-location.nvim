--- Configuration handling for copy-code-location.nvim.
local M = {}

--- @class CopyCodeLocationKeymaps
--- @field location string|false Mapping that copies `file:line` (normal) or `file:first-last` (visual).
--- @field file string|false Mapping that copies the bare file path.

--- @class CopyCodeLocationOptions
--- @field prefix string Prepended to the location. Use "" to disable.
--- @field register string Register the location is copied to.
--- @field relative_to nil|"git"|"cwd"|string|fun(bufnr: integer): string Path base.
--- @field root_markers string[] Markers used to detect the project root.
--- @field notify boolean Show a notification after copying.
--- @field keymaps CopyCodeLocationKeymaps

--- @type CopyCodeLocationOptions
M.defaults = {
  -- `@src/main.lua:12` - the `@` makes the reference explicit for AI agents.
  prefix = "@",
  register = "+",
  -- nil / "git": project root detected via `root_markers` (falls back to cwd).
  -- "cwd": relative to the current working directory.
  -- <string>: any directory, resolved relative to cwd.
  -- <function>: receives the buffer number, returns a directory.
  relative_to = nil,
  root_markers = { ".git" },
  notify = true,
  keymaps = {
    location = false, -- e.g. "<leader>c"
    file = false, -- e.g. "<leader>C"
  },
}

--- @type CopyCodeLocationOptions
M.options = vim.deepcopy(M.defaults)

--- Merges user options into the module options.
--- @param opts CopyCodeLocationOptions|nil
--- @return CopyCodeLocationOptions
function M.setup(opts)
  opts = opts or {}
  local options = vim.deepcopy(M.defaults)

  for key, value in pairs(opts) do
    if key ~= "keymaps" then
      options[key] = value
    end
  end
  for key, value in pairs(opts.keymaps or {}) do
    options.keymaps[key] = value
  end

  M.options = options
  return options
end

--- @return CopyCodeLocationOptions
function M.get()
  return M.options
end

return M
