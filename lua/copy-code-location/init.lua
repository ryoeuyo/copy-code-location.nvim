--- copy-code-location.nvim - copy a `path:line` reference for AI agents.
local config = require("copy-code-location.config")
local location = require("copy-code-location.location")

local M = {}

--- @param message string
--- @param level integer|nil
local function notify(message, level)
  if config.options.notify then
    vim.notify("copy-code-location: " .. message, level or vim.log.levels.INFO)
  end
end

--- Copies the given text to the configured register.
--- @param text string|nil
--- @return string|nil Copied text, nil if the buffer has no file name.
function M.copy(text)
  if not text then
    notify("current buffer has no file name", vim.log.levels.WARN)
    return nil
  end

  local register = config.options.register or "+"
  local ok = pcall(vim.fn.setreg, register, text)
  if not ok then
    pcall(vim.fn.setreg, '"', text)
    vim.notify(
      ("copy-code-location: register '%s' is unavailable, copied to unnamed register"):format(register),
      vim.log.levels.WARN
    )
  else
    notify(text)
  end

  return text
end

--- Copies a location for the current (or given) buffer.
--- @param opts { bufnr?: integer, file_only?: boolean, first?: integer, last?: integer }|nil
--- @return string|nil
function M.yank(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or 0

  local first, last
  if not opts.file_only then
    first = opts.first or vim.fn.line(".")
    last = opts.last or first
    if first > last then
      first, last = last, first
    end
  end

  return M.copy(location.format(bufnr, first, last))
end

--- Copies the bare file path.
--- @param opts { bufnr?: integer }|nil
--- @return string|nil
function M.yank_file(opts)
  opts = opts or {}
  return M.yank({ bufnr = opts.bufnr, file_only = true })
end

--- Lines of the active visual selection, or of the last one.
--- @return integer, integer
function M.visual_range()
  local mode = vim.fn.mode()
  local first, last

  if mode:find("^[vV\22]") then
    first, last = vim.fn.line("v"), vim.fn.line(".")
  else
    first, last = vim.fn.line("'<"), vim.fn.line("'>")
  end

  if first == 0 or last == 0 then
    first, last = vim.fn.line("."), vim.fn.line(".")
  end
  if first > last then
    first, last = last, first
  end

  return first, last
end

--- Copies a `file:first-last` location for the visual selection.
--- @param opts { bufnr?: integer }|nil
--- @return string|nil
function M.yank_range(opts)
  opts = opts or {}
  local first, last = M.visual_range()
  return M.yank({ bufnr = opts.bufnr, first = first, last = last })
end

--- @param options CopyCodeLocationOptions
local function apply_keymaps(options)
  local keymaps = options.keymaps or {}

  if keymaps.location then
    vim.keymap.set("n", keymaps.location, function()
      M.yank()
    end, { desc = "Copy code location", silent = true })
    vim.keymap.set("x", keymaps.location, function()
      M.yank_range()
    end, { desc = "Copy code location (range)", silent = true })
  end

  if keymaps.file then
    vim.keymap.set("n", keymaps.file, function()
      M.yank_file()
    end, { desc = "Copy file path", silent = true })
  end
end

--- @param opts CopyCodeLocationOptions|nil
--- @return table
function M.setup(opts)
  M.load()
  local options = config.setup(opts)
  apply_keymaps(options)
  return M
end

--- Registers commands and `<Plug>` mappings. Safe to call more than once.
function M.load()
  if vim.g.loaded_copy_code_location then
    return
  end
  vim.g.loaded_copy_code_location = 1

  vim.api.nvim_create_user_command("CopyCodeLocation", function(cmd)
    M.yank({ first = cmd.line1, last = cmd.line2 })
  end, {
    range = true,
    desc = "Copy `path:line` (or `path:first-last` for a range)",
  })

  vim.api.nvim_create_user_command("CopyCodeLocationFile", function()
    M.yank_file()
  end, { desc = "Copy `path` for the current file" })

  vim.keymap.set("n", "<Plug>(CopyCodeLocation)", function()
    M.yank()
  end, { desc = "Copy code location" })
  vim.keymap.set("x", "<Plug>(CopyCodeLocation)", function()
    M.yank_range()
  end, { desc = "Copy code location (range)" })
  vim.keymap.set({ "n", "x" }, "<Plug>(CopyCodeLocationFile)", function()
    M.yank_file()
  end, { desc = "Copy file path" })
end

return M
