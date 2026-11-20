# copy-code-location.nvim

Copy a code reference in the format AI agents understand, straight from Neovim:

```
@app/src/templates/template.json:124
```

Paste it into the chat and the agent knows exactly which file and line you mean.

## Features

- `@path:line` - reference for the line under the cursor.
- `@path` - reference for the whole file.
- `@path:first-last` - reference for a visual selection (or any `:range`).
- Paths are relative to the **git root** by default, so it works even when Neovim
  was started in a subdirectory.
- No default keymaps: use the commands, the `<Plug>` mappings, or `setup()`.
- `@` prefix keeps the reference unambiguous, and is configurable.

## Requirements

- Neovim >= 0.9 (0.10+ recommended, uses `vim.fs.root()`).

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "ryoeuyo/copy-code-location.nvim",
  opts = {
    keymaps = {
      location = "<leader>c", -- file:line, or file:first-last in visual mode
      file = "<leader>C", -- bare file path
    },
  },
}
```

Or without calling `setup()` at all:

```lua
{
  "ryoeuyo/copy-code-location.nvim",
  keys = {
    { "<leader>c", "<Plug>(CopyCodeLocation)", mode = { "n", "x" }, desc = "Copy code location" },
    { "<leader>C", "<Plug>(CopyCodeLocationFile)", desc = "Copy file path" },
  },
}
```

With the built-in package manager:

```sh
git clone https://github.com/ryoeuyo/copy-code-location.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/copy-code-location.nvim
```

## Usage

Commands work without any configuration:

| Command                        | Mode           | Result                          |
| ------------------------------ | -------------- | ------------------------------- |
| `:CopyCodeLocation`            | normal         | `@src/main.lua:12`              |
| `:CopyCodeLocation`            | visual / range | `@src/main.lua:12-30`           |
| `:CopyCodeLocationFile`        | normal         | `@src/main.lua`                 |

```vim
" line under the cursor
:CopyCodeLocation
" explicit range
:12,30CopyCodeLocation
" whole file
:CopyCodeLocationFile
```

Default mappings from `setup()` (see `keymaps` below):

| Mode   | Mapping | Action                          |
| ------ | ------- | ------------------------------- |
| `n`    | `<leader>c` | copy `@path:line`           |
| `x`    | `<leader>c` | copy `@path:first-last`     |
| `n`    | `<leader>C` | copy `@path`                |

`<Plug>` mappings are always available:

- `<Plug>(CopyCodeLocation)` - `n`: `@path:line`, `x`: `@path:first-last`
- `<Plug>(CopyCodeLocationFile)` - `@path`

Lua API:

```lua
local ccl = require("copy-code-location")

ccl.yank()                          -- @path:line
ccl.yank({ first = 12, last = 30 }) -- @path:12-30
ccl.yank_file()                     -- @path
ccl.yank_range()                    -- @path:first-last for the selection
```

Every function returns the copied string (or `nil` for unnamed buffers) and
respects the configured register, so you can use it in your own mappings:

```lua
vim.keymap.set("n", "<leader>c", function()
  require("copy-code-location").yank()
end)
```

## Configuration

Defaults:

```lua
require("copy-code-location").setup({
  -- Prepended to the location. Set to "" for plain `src/main.lua:12`.
  prefix = "@",

  -- Register the location is copied to.
  register = "+",

  -- Path base:
  --   nil | "git"      project root detected via `root_markers`, then cwd
  --   "cwd"            current working directory
  --   "<directory>"    any directory
  --   function(bufnr)  return a directory (runs for every copy)
  relative_to = nil,

  -- Markers used to detect the project root.
  root_markers = { ".git" },

  -- Show a notification with the copied reference.
  notify = true,

  -- Set to false to skip any keymap.
  keymaps = {
    location = false, -- e.g. "<leader>c"
    file = false, -- e.g. "<leader>C"
  },
})
```

If the buffer is outside the project root, the path is made relative to the
current working directory when possible, otherwise an absolute path is used.

## Examples

Neovim started in `repo/app/src` with the file `repo/app/src/templates/template.json`,
cursor on line 124:

```
:CopyCodeLocation
" -> @app/src/templates/template.json:124
```

Lines 12-30 selected in visual mode, `keymaps.location = "<leader>c"`:

```
" -> @app/src/templates/template.json:12-30
```

## License

MIT
