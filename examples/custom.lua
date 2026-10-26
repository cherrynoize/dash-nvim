-- examples/custom.lua
-- A smaller, differently styled dashboard that shows the customization hooks.
-- Try it with:  :lua require("dash").setup(dofile("/path/to/this/custom.lua"))

return {
  user = "Ada",

  -- ASCII header instead of the icon + text
  header = {
    lines = {
      "╔╦╗╔═╗╔═╗╦ ╦",
      " ║║╠═╣╚═╗╠═╣",
      "═╩╝╩ ╩╚═╝╩ ╩",
    },
  },

  greeting = function(ctx)
    return { { "Hello, ", "DashGreeting" }, { ctx.user, "DashGreetingName" } }
  end,
  date = "%d.%m.%Y",

  -- sections in a different order, plus one of our own
  sections = { "header", "spacer", "greeting", "date", "spacer", "panels", "spacer", "chips",
    function() return { "have a nice day" } end },

  panels = {
    -- a preset with different entries (and a different hotkey on one of them)
    { "actions", title = "START", items = { "find_files", { "new_file", key = "e" }, "quit" } },

    -- a fully custom panel
    {
      title = "NOTES",
      style = "item",
      items = {
        { icon = "file", label = "Inbox", key = "1", run = "edit ~/notes/inbox.md" },
        { icon = "file", label = "Journal", key = "2", run = "edit ~/notes/journal.md" },
        { icon = "terminal", label = "Today's todo", key = "3",
          run = function() vim.cmd("edit ~/notes/" .. os.date("%Y-%m-%d") .. ".md") end },
      },
    },

    { "recent", max = 20, cwd_only = true },
  },

  -- only two columns, no blank rows between entries
  layout = { max_columns = 2, gaps = false, padding = 0 },

  -- square borders
  border = { tl = "┌", tr = "┐", bl = "└", br = "┘", h = "─", v = "│", thumb = "█" },

  -- a green palette; any single highlight group can be replaced as well
  colors = {
    bg = "#0B1410", surface = "#12221A", elevated = "#1A3326", border = "#285C40",
    purple = "#34D399", text = "#ECFDF5", soft = "#6EE7B7", muted = "#10B981",
    orange = "#FBBF24", ok = "#34D399",
    blue = "#5EEAD4", blue_bg = "#0F2E2A", blue_key = "#134E4A", blue_txt = "#99F6E4",
    blue_dim = "#115E59", blue_deep = "#0D9488",
  },
  highlights = {
    DashTitleActive = { fg = "#FBBF24", bold = true },
  },

  -- different keys
  keys = {
    panel_left = "<C-h>", panel_down = "<C-j>", panel_up = "<C-k>", panel_right = "<C-l>",
    extra = {
      ["<Esc>"] = function() vim.cmd("enew") end,
    },
  },
  hints = { { "C-h/j/k/l", "panels" }, { "j k", "move" }, { "l", "select" }, { "Esc", "close" } },

  -- your own chip
  chips = {
    "cwd",
    function() return { icon = "file", text = #vim.v.oldfiles .. " recent", hl = "DashChipAccent" } end,
  },
}
