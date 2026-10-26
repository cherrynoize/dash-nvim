-- examples/config.lua
--
-- The original single-file dashboard, expressed as a dash-nvim configuration:
-- six panels (Quick actions with the search entries merged in, Recent files,
-- Projects, Colorschemes, Git, System), the purple / neon-blue palette and
-- the default keys.
--
-- Use it as is:
--   require("dash").setup(require("dash_config"))     -- after copying this file to
--                                                      -- ~/.config/nvim/lua/dash_config.lua
-- or paste the table straight into setup() / lazy.nvim's `opts`.

return {
  autostart = true,

  -- greeting name: $USER exactly as it is (use `user = "Name"` to override)
  user = nil,

  panels = {
    -- Quick actions + search in one scrolling panel; Quit stays last
    {
      "actions",
      title = "QUICK ACTIONS",
      items = {
        "find_files", "new_file", "config", "plugins", "terminal",
        "find_word", "find_string", "find_in_open", "buffers", "diagnostics",
        "marks", "registers", "keymaps", "commands", "help_tags", "man_pages",
        "resume",
        "quit",
      },
    },

    { "recent", title = "RECENT FILES" },

    -- needs DrKJeff16/project.nvim (see examples/lazy.lua)
    { "projects", title = "PROJECTS", reverse = true },

    { "colorschemes", title = "COLORSCHEMES" },

    -- tracked files, changes, commits, branches, status, stash, lazygit;
    -- only shown inside a git repository
    { "git", title = "GIT" },

    -- purple "item" rows, like Recent files and Colorschemes
    { "system", title = "SYSTEM", style = "item" },
  },

  layout = {
    panel_width = 46,
    gap = 3,
    max_columns = 3,
    visible = 6,
    padding = 1,
    gaps = "auto",
  },

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
    blue      = "#00D1FF",
    blue_bg   = "#0A2240",
    blue_key  = "#12396B",
    blue_txt  = "#7DE3FF",
    blue_dim  = "#0B3A5A",
    blue_deep = "#0A86AD",
  },

  icons = { set = "md" },

  chips = { "branch", "cwd", "version", "startup" },

  hints = {
    { "H J K L", "panels" },
    { "j k", "move" },
    { "l", "select" },
  },

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
  },
}
