-- dash-nvim: default options. Everything here can be overridden in setup().

local M = {}

M.defaults = {
  -- open the dashboard when Neovim starts without file arguments
  autostart = true,

  -- name shown in the greeting: nil = $USER, a string, a function returning a
  -- string, or false to hide the name
  user = nil,

  -- user commands that open the dashboard
  commands = { "Dash", "Dashboard" },

  -- buffer filetype
  filetype = "dash",

  -- hide the terminal cursor while the dashboard is focused
  hide_cursor = true,

  -- mouse support (click = focus, double click = select, wheel = scroll)
  mouse = true,

  -- hint shown in the key slot of the selected row when it has no key of its own
  -- ("" or false to disable)
  select_hint = "l",

  -- called after the dashboard is opened: function({ buf = number, win = number })
  -- (the `User DashOpened` autocommand fires as well)
  on_open = nil,

  ---------------------------------------------------------------------------
  -- Content
  ---------------------------------------------------------------------------

  -- Vertical order of the screen. Strings are built-in sections:
  --   "header" "greeting" "date" "panels" "chips" "hints" "spacer"
  -- A function(ctx) may return a list of lines (a string or a list of
  -- { text, highlight } pieces) to add your own section.
  -- "spacer" is one blank line; repeated / leading spacers are collapsed.
  sections = {
    "header", "spacer", "greeting", "date", "spacer",
    "panels", "spacer", "chips", "spacer", "hints",
  },

  -- false to hide, a table, or function(ctx) returning a list of lines.
  --   { icon = "◆", text = "N E O V I M" }    icon + text
  --   { lines = { "ascii", "art" } }          your own (centered) lines
  header = {
    icon = "◆", text = "N E O V I M",
    -- icon_hl = "DashHeaderDiamond", hl = "DashHeader",
  },

  -- false to hide, a table, or function({ user, hour, width }) returning a
  -- string / list of pieces
  greeting = {
    messages = {
      late = "Working late",      -- 00:00 - 04:59
      morning = "Good morning",   -- 05:00 - 11:59
      afternoon = "Good afternoon", -- 12:00 - 17:59
      evening = "Good evening",   -- 18:00 - 23:59
    },
    separator = ", ",
    show_name = true,
  },

  -- os.date() format, a function returning a string, or false to hide
  date = "%A, %d %B",

  -- The panels, in reading order (left to right, top to bottom). Each entry is
  --   "recent"                              a preset by name
  --   { "recent", title = "FILES", max=9 }  a preset with overrides
  --   { title = "MINE", items = { ... } }   a fully custom panel
  -- Presets: actions search git system recent projects colorschemes.
  -- A panel can carry `cond = function() return boolean end`; it is left out
  -- when that returns false (the "git" preset only shows inside a git repo).
  -- See the README for every panel / item field.
  panels = { "actions", "recent" },

  -- Define or override entries of the item registry. Panels refer to items by
  -- name:  items = { "find_files", { "quit", key = "Q" }, { label = "Custom", run = "..." } }
  --   items = { find_files = { key = "F", label = "Files" }, my_item = { ... } }
  items = {},

  -- status chips under the panels. Strings are built-in chips ("branch" "cwd"
  -- "version" "startup"), { "cwd", max = 30 } passes options, a function
  -- returns { icon = "", text = "", hl = "" } (or nil to hide it).
  chips = { "branch", "cwd", "version", "startup" },
  chip_caps = { left = vim.fn.nr2char(0xe0b6), right = vim.fn.nr2char(0xe0b4) }, -- false for no caps

  -- key hints at the bottom: list of { key, description }, or false
  hints = {
    { "H J K L", "panels" },
    { "j k", "move" },
    { "l", "select" },
  },

  ---------------------------------------------------------------------------
  -- Layout
  ---------------------------------------------------------------------------
  layout = {
    panel_width = 46,   -- outer width of a panel
    gap = 3,            -- cells between panels
    max_columns = 3,    -- panels per row (fewer if the window is narrow)
    visible = 6,        -- rows per panel (a footer row takes one of them)
    padding = 1,        -- blank rows above the first / below the last entry
    gaps = "auto",      -- blank rows between entries: true / false / "auto" (if it fits)
    top_padding = "auto", -- blank rows above the content: number / "auto"
    wrap = true,        -- j / k wrap around at the ends of a panel
    scrollbar = true,   -- show the scrollbar on the right border
    counter = true,     -- show "3/24" in the top border of scrollable panels
  },

  -- characters used to draw panels (each must be one cell wide)
  border = {
    tl = "╭", tr = "╮", bl = "╰", br = "╯",
    h = "─", v = "│", thumb = "┃",
  },

  -- window-local options of the dashboard window
  window_options = {
    number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0",
    cursorline = false, cursorcolumn = false, colorcolumn = "", list = false,
    wrap = false, spell = false, scrolloff = 0, sidescrolloff = 0,
    statuscolumn = "", fillchars = "eob: ",
    winhighlight = "Normal:DashNormal,NormalNC:DashNormal,EndOfBuffer:DashNormal,CursorLine:DashNormal",
  },

  ---------------------------------------------------------------------------
  -- Look
  ---------------------------------------------------------------------------

  -- "md" (Nerd Fonts v3 Material Design) | "fa" (Font Awesome) | custom set
  -- name from require("dash.icons").sets, or { set = "md", overrides = {...} }
  -- where overrides maps an icon name to a codepoint (number) or a glyph.
  icons = { set = "md", overrides = {} },

  -- palette; every Dash highlight group is derived from these
  colors = {
    bg       = "#07040D",
    surface  = "#160C26",
    elevated = "#211139",
    border   = "#3A1F5E",
    purple   = "#A855F7",
    text     = "#F3E8FF",
    soft     = "#C084FC",
    muted    = "#8B5CF6",
    orange   = "#F97316",
    ok       = "#10B981",
    -- neon blue (buttons)
    blue      = "#00D1FF",
    blue_bg   = "#0A2240",
    blue_key  = "#12396B",
    blue_txt  = "#7DE3FF",
    blue_dim  = "#0B3A5A",
    blue_deep = "#0A86AD", -- keycap on the focused row
  },

  -- Override any highlight group: { DashBtn = { fg = "#fff", bg = "#000" } },
  -- { DashTitle = "Title" } (link), or a function(colors) returning such a table.
  highlights = {},

  -- Row styles used by panels (`style = "primary"`). Each names three highlight
  -- groups: base (row), dim (secondary text) and key (the keycap). `active` is
  -- the focused row; give a style its own `active = {...}` to override it.
  styles = {
    primary = { base = "DashBtn",  dim = "DashBtn",     key = "DashBtnKey" },
    item    = { base = "DashItem", dim = "DashItemDim", key = "DashItemKey" },
    active  = { base = "DashBtnActive", dim = "DashBtnActiveDim", key = "DashBtnKeyActive" },
  },

  ---------------------------------------------------------------------------
  -- Keys (each: a string, a list of strings, or false to disable)
  ---------------------------------------------------------------------------
  keys = {
    panel_left = "H", panel_down = "J", panel_up = "K", panel_right = "L",
    next_panel = "<Tab>", prev_panel = "<S-Tab>",
    next_item = { "j", "<Down>", "<C-n>" },
    prev_item = { "k", "<Up>", "<C-p>" },
    page_down = { "<C-d>", "<PageDown>" },
    page_up = { "<C-u>", "<PageUp>" },
    first = "gg",
    last = "G",
    select = { "l", "<CR>" },
    -- keys turned into no-ops (the screen is read-only); unless used above
    block = { "h", "<Left>", "<Right>", "a", "A", "I", "O", "x", "X", "d", "<C-r>" },
    -- your own buffer-local maps: { ["<lhs>"] = function(ctx) ... end }
    -- ctx = { panel = <panel>, item = <selected item> }
    extra = {},
  },
}

M.options = vim.deepcopy(M.defaults)
M.ready = false

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  M.ready = true
  return M.options
end

return M
