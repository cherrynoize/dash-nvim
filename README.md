# dash-nvim

A multi-panel dashboard for Neovim. Panels, entries, colors, borders, icons,
layout and every key are configurable, and the original "neon" setup ships as
an example config.

```
                       ◆  N E O V I M
                 Good evening, you
                  Monday, 26 October

╭─ QUICK ACTIONS ── 1/18 ─╮   ╭─ RECENT FILES ──────────╮   ╭─ PROJECTS ──────────────╮
│   Find files          f │   │   init.lua        1     │   │   dash-nvim     ~/code  │
│   New file            n │   │   keymaps.lua     2     │   │   notes         ~/docs  │
│   ...                   │   │   ...                   │   │   ...                   │
╰─────────────────────────╯   ╰─────────────────────────╯   ╰─────────────────────────╯
```

(Illustration only; the real thing is colored and sized to your window.)

## Features

- Any number of panels, laid out in a responsive grid (1 to N columns)
- Scrolling panels with a scrollbar and an `n/N` counter, optional footer rows
- Built-in presets: **actions, search, git, system, recent files, projects, colorschemes**; the defaults show just Quick actions and Recent files
- ~35 ready-made entries (items) you reference by name, plus your own
- Everything is themable: palette, per-group highlights, row styles, borders, icon sets
- Every key is remappable, plus per-item hotkeys, mouse support and user maps
- Header, greeting, date, status chips and key hints can each be changed or removed
- Reorder / add your own sections; hooks (`on_open`, `User DashOpened`)
- Works without any optional plugin; items whose requirements are missing are hidden

## Requirements

- Neovim **0.9+** (0.11+ if you use the Projects panel with project.nvim)
- A [Nerd Font](https://www.nerdfonts.com/) and `termguicolors`
- Optional:
  [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (pickers behind most items),
  [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) (file icons),
  [DrKJeff16/project.nvim](https://github.com/DrKJeff16/project.nvim) (Projects panel),
  [lazy.nvim](https://github.com/folke/lazy.nvim) (plugin items, startup time chip),
  [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) (floating Lazygit),
  [vim-fugitive](https://github.com/tpope/vim-fugitive) (`Git status` item)

## Installation

The repository is `git@github.com:cherrynoize/dash-nvim.git` (SSH), and everything
below clones it that way. The plugin ends up in your plugins directory like any
other plugin; there is nothing to configure about *where* it lives.

### lazy.nvim

```lua
-- ~/.config/nvim/lua/plugins/dash-nvim.lua
return {
  "cherrynoize/dash-nvim",
  url = "git@github.com:cherrynoize/dash-nvim.git", -- clone over SSH
  lazy = false,                                      -- needed for the startup dashboard
  priority = 100,
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
    { "DrKJeff16/project.nvim", lazy = false, opts = {} }, -- for the Projects panel
  },
  opts = {
    -- your options (see Configuration); {} = defaults
  },
}
```

`opts` calls `require("dash").setup(opts)` for you. To clone *every* plugin over SSH,
set it once in lazy's own setup instead of per plugin:

```lua
require("lazy").setup("plugins", { git = { url_format = "git@github.com:%s.git" } })
```

See `examples/lazy.lua` for a complete spec that loads `examples/config.lua`.

### vim.pack (Neovim 0.12+)

```lua
vim.pack.add({
  { src = "git@github.com:cherrynoize/dash-nvim.git" },
  -- optional: telescope, devicons, project.nvim ...
})
require("dash").setup({ ... })
```

### Built-in packages (no plugin manager)

```sh
git clone git@github.com:cherrynoize/dash-nvim.git \
  ~/.local/share/nvim/site/pack/plugins/start/dash-nvim
```

then call `require("dash").setup({})` from `init.lua`. Plugins in `start/` load
automatically before `init.lua` finishes. In `opt/` you would `:packadd dash-nvim` first.

### Using the original configuration

```sh
cp examples/config.lua ~/.config/nvim/lua/dash_config.lua
```

```lua
require("dash").setup(require("dash_config"))
```

Run `:checkhealth dash` to verify the install and see which optional pieces were found.

## Usage

| | |
|---|---|
| `:Dash`, `:Dashboard` | open the dashboard in the current window (names are configurable: `commands`) |
| `require("dash").open()` | same, from Lua |
| `require("dash").refresh()` | rebuild the panels of an open dashboard |
| `vim.g.dash_disable = true` | never open on startup |

It opens automatically when Neovim starts with no file arguments and an empty buffer
(`autostart = false` turns that off).

### Default keys

| Key | Action |
|---|---|
| `H J K L` | move between panels |
| `Tab`, `S-Tab` | next / previous panel |
| `j k`, `Up Down`, `C-n C-p` | move inside a panel (wraps; long lists scroll) |
| `l`, `Enter` | select |
| `gg`, `G` | first / last entry |
| `C-d`, `C-u`, `PageDown`, `PageUp` | page down / up |
| mouse | click = focus, double click = select, wheel = scroll |
| the key shown on a row | run that entry directly |

## Configuration

`setup()` deep-merges your table over the defaults, so you only write what
you change. **Lists are replaced, not merged** (`panels`, `chips`, `keys.next_item` ...).
The complete default table, with comments, is in
[`lua/dash/config.lua`](lua/dash/config.lua).

| Option | Default | Meaning |
|---|---|---|
| `autostart` | `true` | open on an empty startup |
| `user` | `nil` | greeting name: `nil` = `$USER` as is, a string, a function, or `false` |
| `commands` | `{ "Dash", "Dashboard" }` | commands that open the dashboard |
| `filetype` | `"dash"` | buffer filetype |
| `hide_cursor` | `true` | hide the cursor while the dashboard is focused |
| `mouse` | `true` | mouse support |
| `select_hint` | `"l"` | keycap text on the focused row when it has no key |
| `on_open` | `nil` | `function({ buf, win })` called after opening |
| `sections` | see below | order of the screen |
| `header`, `greeting`, `date` | see below | top of the screen |
| `panels` | `{ "actions", "recent" }` | the panels |
| `items` | `{}` | add / override registry items |
| `chips`, `chip_caps`, `hints` | see below | status line and key hints |
| `layout`, `border`, `window_options` | see below | geometry |
| `icons`, `colors`, `highlights`, `styles` | see below | look |
| `keys` | see below | key map |

### Panels

`panels` is a list, in reading order. Each entry is one of

```lua
panels = {
  "recent",                                  -- a preset
  { "recent", title = "FILES", max = 20 },   -- a preset with overrides
  { title = "NOTES", style = "item",         -- a custom panel
    items = { "find_files", { label = "Todo", key = "t", run = "edit ~/todo.md" } } },
}
```

Panel fields: `title`, `style`, `items`, `visible`, `footer`, `empty`, `sel`, `cond`.

| Field | Meaning |
|---|---|
| `title` | text in the top border |
| `style` | row style: `"primary"` (neon blue buttons), `"item"` (purple rows) or one of your own (`styles`) |
| `items` | list of items, or `function(panel) -> items[, selected_index]` |
| `visible` | rows shown at once (default `layout.visible`); a footer takes one |
| `footer` | `function(selected_item, panel) -> { { text, hl }, ... }` drawn in an extra bottom row |
| `empty` | label shown when the panel has no items |
| `sel` | index selected on open |
| `cond` | `function(panel) -> boolean`; the panel is left out when it returns false |

**Presets**

| Preset | Contents | Options |
|---|---|---|
| `actions` | Find files, New file, Configuration, Plugins, Quit | |
| `search` | Find word / string / in open files, Buffers, Diagnostics, Marks, Registers, Keymaps, Commands, Help, Man pages, Reopen last search | |
| `git` | Tracked files, Changes, Commits, Branches, Status, Stash, Lazygit. **Only shown inside a git repository**; pass `cond = function() return true end` to always show it | `cond` |
| `system` | Check health, LSP info, Messages, Sync, Mason, Check updates, Neovim help | |
| `recent` | recent files; footer shows the full path of the selected file | `max` (50), `hotkeys` (9, keys `1`-`9`), `exclude` (list of Lua patterns, default `{ "/%.git/" }`), `cwd_only` |
| `projects` | projects known to project.nvim; current one marked `●`; selecting `cd`s, refreshes the chips and opens a file picker | `source`, `reverse` (true), `max`, `open` |
| `colorschemes` | all colorschemes, active one marked `●`, palette strip in the footer | `exclude` (names), `filter` (function), `lazy`, `swatch`, `swatches` |

`projects` options: `source` is `"project.nvim"` (default) or a function returning a
list of directories (use it for any other project manager); `open` is
`"find_files"` (default), `"edit"`, `"none"` (only `cd`) or `function(path)`;
`reverse` flips the list, because project.nvim returns the oldest project first.

To extend a preset, build on its items:

```lua
local git = require("dash.panels").presets.git()
table.insert(git.items, "resume")
panels = { git }
```

Register your own preset (also usable as `"mine"` in `panels`):

```lua
require("dash").register_panel("todos", function(spec)
  return {
    title = "TODOS", style = "item",
    items = function() return { { label = "write docs", run = "edit docs.md" } } end,
  }
end)
```

### Items

Items are the rows. Refer to them by name, with overrides, or define them inline:

```lua
items = {
  "find_files",                          -- registry entry
  { "quit", key = "Q", label = "Exit" }, -- entry with overrides
  { icon = "file", label = "Todo", key = "t", run = "edit ~/todo.md" },  -- literal
}
```

| Field | Meaning |
|---|---|
| `icon` | icon name, codepoint (`0xF0770`) or a literal glyph |
| `label` | string or `function(item)` |
| `key` | hotkey: shown on the row **and** mapped (`false` = none) |
| `badge` | text shown in the keycap but **not** mapped (string or `function(item)`); wins over `key` for display |
| `dim` | secondary text after the label |
| `run` | command string (`"Lazy sync"`) or `function(item, panel)` |
| `cond` | `function() -> boolean`; the item is left out when it returns false |
| `hot` | `false` = show `key` but do not map it |

Built-in names (default key in parentheses). Items that need Telescope are
hidden without it; `plugins`, `sync`, `check_updates` need lazy.nvim; `mason`
needs Mason; `git_status` needs `:Git` (fugitive); `lazygit` needs the executable.

- **Actions:** `find_files` (f) `new_file` (n) `config` (c) `plugins` (p) `terminal` (T) `quit` (q)
- **Search:** `find_word` (w) `find_string` (s) `find_in_open` (/) `buffers` (b) `diagnostics` (d) `marks` (') `registers` (r) `keymaps` (?) `commands` (x) `help_tags` (h) `man_pages` (m) `resume` (%)
- **Git:** `git_files` (t) `git_changes` (a) `git_commits` (o) `git_branches` (e) `git_status` (i) `git_stash` (u) `lazygit` (z)
- **System:** `health` (C) `lsp_info` (I) `messages` (M) `sync` (S) `check_updates` (U) `mason` (N) `nvim_help` (V)

Change or add registry entries globally:

```lua
items = {
  find_files = { key = "F", label = "Files" },          -- override
  notes = { icon = "file", label = "Notes", key = "o", run = "edit ~/notes.md" },  -- new
  find_word = { cond = function() return true end },    -- show it even without Telescope
}
```

or from code: `require("dash").register_item("notes", { ... })`.

Hotkeys never override the navigation keys; if two items use the same key, the
first one wins.

### Sections, header, greeting, date

```lua
sections = { "header", "spacer", "greeting", "date", "spacer", "panels", "spacer", "chips", "spacer", "hints" }
```

Remove a name to drop a section, reorder them, or add a function
`function(ctx) -> lines` (`ctx = { width, height, user, gaps }`; a line is a string or a
list of `{ text, highlight }` pieces). Consecutive and leading `"spacer"`s collapse.

```lua
header = { icon = "◆", text = "N E O V I M" }          -- default
header = { lines = { "ascii", "art" } }                -- your own lines
header = function(ctx) return { "line 1", "line 2" } end
header = false

greeting = { messages = { morning = "Morning", afternoon = "Afternoon",
                          evening = "Evening", late = "Still up" },
             separator = " - ", show_name = true }
greeting = function(ctx) return "Hello " .. ctx.user end  -- string or pieces
greeting = false

date = "%A, %d %B"   -- os.date format, a function, or false
user = "Ada"         -- or function() return "Ada" end, or false to hide the name
```

### Chips and hints

```lua
chips = { "branch", "cwd", "version", "startup" }       -- default; built-in names
chips = { { "cwd", max = 30 }, "version" }               -- chip options
chips = { function() return { icon = "file", text = "hi", hl = "DashChipAccent" } end }
chip_caps = false                                        -- no rounded caps
hints = { { "H J K L", "panels" }, { "j k", "move" } }   -- or false
```

Register a chip for reuse: `require("dash").register_chip("mine", function(opts) return {...} end)`.
The hints are plain text; update them if you remap keys.

### Layout and borders

```lua
layout = {
  panel_width = 46,    -- outer width
  gap = 3,             -- between panels
  max_columns = 3,     -- panels per row (fewer on narrow windows)
  visible = 6,         -- rows per panel
  padding = 1,         -- blank rows above the first / below the last entry (0 = none)
  gaps = "auto",       -- blank rows between entries: true, false, or "auto" (when it fits)
  top_padding = "auto",
  wrap = true,         -- j / k wrap around
  scrollbar = true,
  counter = true,      -- "3/24" in the border of scrollable panels
}
border = { tl = "╭", tr = "╮", bl = "╰", br = "╯", h = "─", v = "│", thumb = "┃" }
```

Border characters must be one cell wide. `window_options` holds the
window-local options of the dashboard window (merged with the defaults).

### Colors, highlights, styles, icons

`colors` is a palette; all `Dash*` highlight groups are derived from it:

| Color | Used for |
|---|---|
| `bg`, `surface`, `elevated` | background, purple row background, keycap / chip background |
| `border`, `purple` | inactive / active border |
| `text`, `soft`, `muted` | text, highlighted titles, dim text |
| `orange`, `ok` | header diamond / version chip, startup chip |
| `blue`, `blue_bg`, `blue_key`, `blue_txt`, `blue_dim`, `blue_deep` | the neon button style and focused row |

```lua
colors = { purple = "#34D399", blue = "#5EEAD4" }          -- change some
highlights = { DashTitleActive = { fg = "#FBBF24", bold = true } }
highlights = { DashBorder = "Comment" }                    -- link to a group
highlights = function(c) return { DashHint = { fg = c.soft } } end
```

Groups: `DashNormal DashCursor DashBorder DashBorderActive DashTitle DashTitleActive
DashCount DashThumb DashMuted DashHeader DashHeaderDiamond DashGreeting
DashGreetingName DashBtn DashBtnKey DashBtnActive DashBtnActiveDim DashBtnKeyActive
DashItem DashItemDim DashItemKey DashCap DashChip DashChipAccent DashChipOk DashHint DashHintKey`.
Colors are re-applied on `:colorscheme`.

A **style** names the three groups a row uses: `base` (row), `dim` (secondary text), `key` (keycap).
Define your own and use it as `style = "mine"`:

```lua
highlights = { MyRow = { fg = "#fff", bg = "#222" }, MyKey = { fg = "#0ff", bg = "#333" } },
styles = {
  mine = { base = "MyRow", dim = "MyRow", key = "MyKey" },
  active = { base = "DashBtnActive", dim = "DashBtnActiveDim", key = "DashBtnKeyActive" },  -- focused row
},
```

A style can carry its own focused look with `active = { base, dim, key }`.

**Icons:** `icons = { set = "md" | "fa", overrides = { find_files = 0xF002, quit = "Q" } }`.
Override by codepoint or glyph. Add a whole set with
`require("dash.icons").sets.mine = { ... }` and `icons = { set = "mine" }`; missing names fall back to `md`.

### Keys

```lua
keys = {
  panel_left = "H", panel_down = "J", panel_up = "K", panel_right = "L",
  next_panel = "<Tab>", prev_panel = "<S-Tab>",
  next_item = { "j", "<Down>", "<C-n>" }, prev_item = { "k", "<Up>", "<C-p>" },
  page_down = { "<C-d>", "<PageDown>" }, page_up = { "<C-u>", "<PageUp>" },
  first = "gg", last = "G",
  select = { "l", "<CR>" },
  block = { "h", "<Left>", "<Right>", "a", "A", "I", "O", "x", "X", "d", "<C-r>" },
  extra = {},  -- { ["<Esc>"] = function(ctx) ... end }  ctx = { panel, item }
}
```

Every entry takes a string, a list, or `false` to disable it. `block` keys become
no-ops (the screen is read-only) unless an item or action already uses them.

### Events and API

- `User DashOpened` autocommand and `on_open({ buf, win })` after the dashboard opens
- `require("dash").setup(opts)`, `.open()`, `.refresh()`
- `.register_item(name, spec)`, `.register_panel(name, factory)`, `.register_chip(name, fn)`
- `:checkhealth dash`

## Examples

- [`examples/config.lua`](examples/config.lua): the original dashboard (6 panels, neon palette)
- [`examples/lazy.lua`](examples/lazy.lua): lazy.nvim spec with the optional dependencies
- [`examples/custom.lua`](examples/custom.lua): ASCII header, custom panel, green palette,
  two columns, other keys, custom chip

Two things worth copying from the original setup:

```lua
-- the Quick actions + search panel in one scrolling list
{ "actions", items = { "find_files", "new_file", "config", "plugins", "terminal",
  "find_word", "find_string", "find_in_open", "buffers", "diagnostics", "marks",
  "registers", "keymaps", "commands", "help_tags", "man_pages", "resume", "quit" } }

-- a Projects panel for another project manager
{ "projects", source = function() return require("my_projects").list() end }
```

## Troubleshooting

- **Empty or missing icons:** use a Nerd Font, or set `icons = { set = "fa" }`, or override single icons.
- **Panels not colored:** enable `vim.o.termguicolors`.
- **An item is missing:** its requirement (Telescope, Lazy, Mason, fugitive, lazygit) was not found. See `cond` above and `:checkhealth dash`.
- **Projects panel says "not installed" or is empty:** install project.nvim, load it eagerly (`lazy = false`) so it is set up before Dash opens, and open a file inside a project once (or `:Project add`). If the order looks upside down, set `reverse = false`.
- **Dashboard doesn't open on startup:** it only opens with no file arguments and an empty buffer, and `vim.g.dash_disable` must not be set.
- **Hotkey doesn't work:** another item with the same key came first, or the key is reserved by a navigation map.

## License

MIT, see [LICENSE](LICENSE).
