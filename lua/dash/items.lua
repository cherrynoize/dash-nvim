-- dash-nvim: the item registry.
--
-- An item is one row of a panel. Panels refer to items by name; the registry
-- below holds the built-in ones, `opts.items` adds / overrides entries and
-- require("dash").register_item() does the same from code.
--
-- Item fields
--   icon   name from the icon set, a codepoint, or a literal glyph
--   label  string or function(item) -> string
--   key    hotkey: shown in the keycap and mapped on the dashboard (false = none)
--   badge  text for the keycap that is NOT mapped (string or function(item));
--          wins over `key` for display
--   dim    secondary text shown after the label (e.g. a directory)
--   run    command string or function(item, panel)
--   cond   function() -> boolean; the item is left out when it returns false
--   hot    set false to show `key` but not map it

local config = require("dash.config")
local util = require("dash.util")

local fn = vim.fn
local pick, cmd = util.pick, util.cmd

local M = {}

local function lazy() return fn.exists(":Lazy") == 2 end
local function mason() return fn.exists(":Mason") == 2 end
local function fugitive() return fn.exists(":Git") == 2 end
local function lazygit() return fn.executable("lazygit") == 1 end

local tel = util.has_telescope -- Telescope based items are hidden without Telescope

M.builtin = {
  -- quick actions ----------------------------------------------------------
  find_files = { icon = "find_files", label = "Find files", key = "f", cond = tel,
    run = pick("find_files") },
  new_file = { icon = "new_file", label = "New file", key = "n", run = "enew | startinsert" },
  config = { icon = "config", label = "Configuration", key = "c", cond = tel,
    run = function()
      pick("find_files", {
        cwd = fn.stdpath("config"),
        follow = true,
        prompt_title = "Find config files",
      })()
    end },
  plugins = { icon = "plugins", label = "Plugins", key = "p", cond = lazy, run = "Lazy home" },
  terminal = { icon = "terminal", label = "Terminal", key = "T", run = "terminal | startinsert" },
  quit = { icon = "quit", label = "Quit", key = "q", run = "qa" },

  -- search -----------------------------------------------------------------
  find_word = { icon = "find_word", label = "Find word", key = "w", cond = tel,
    run = pick("grep_string", {
      prompt_title = "Find word",
      word_match = "-w",
      use_regex = true,
      search = "",
    }) },
  find_string = { icon = "find_string", label = "Find string", key = "s", cond = tel,
    run = pick("live_grep", { prompt_title = "Match exact string", search = "" }) },
  find_in_open = { icon = "open_files", label = "Find in open files", key = "/", cond = tel,
    run = pick("live_grep", { grep_open_files = true, prompt_title = "Match in open files" }) },
  buffers = { icon = "buffers", label = "Open buffers", key = "b", cond = tel, run = pick("buffers") },
  diagnostics = { icon = "diagnostics", label = "Diagnostics", key = "d", cond = tel,
    run = pick("diagnostics") },
  marks = { icon = "marks", label = "Marks", key = "'", cond = tel, run = pick("marks") },
  registers = { icon = "registers", label = "Registers", key = "r", cond = tel, run = pick("registers") },
  keymaps = { icon = "keymaps", label = "Keymaps", key = "?", cond = tel, run = pick("keymaps") },
  commands = { icon = "commands", label = "Commands", key = "x", cond = tel, run = pick("commands") },
  help_tags = { icon = "help_tags", label = "Help", key = "h", cond = tel, run = pick("help_tags") },
  man_pages = { icon = "man", label = "Man pages", key = "m", cond = tel, run = pick("man_pages") },
  resume = { icon = "resume", label = "Reopen last search", key = "%", cond = tel, run = pick("resume") },

  -- git --------------------------------------------------------------------
  git_files = { icon = "git_files", label = "Tracked files", key = "t", cond = tel,
    run = pick("git_files", { prompt_title = "Git files" }) },
  git_changes = { icon = "git_changes", label = "Git changes", key = "a", cond = tel,
    run = pick("git_status", { prompt_title = "Find diff" }) },
  git_commits = { icon = "git_commits", label = "Commits", key = "o", cond = tel,
    run = pick("git_bcommits", { prompt_title = "Git commits" }) },
  git_branches = { icon = "git_branches", label = "Branches", key = "e", cond = tel,
    run = pick("git_branches", { prompt_title = "Git branches" }) },
  git_status = { icon = "git_status", label = "Git status", key = "i", cond = fugitive,
    run = "tab Git" },
  git_stash = { icon = "git_stash", label = "Stash", key = "u", cond = tel,
    run = pick("git_stash", { prompt_title = "Git stash" }) },
  lazygit = { icon = "lazygit", label = "Lazygit", key = "z", cond = lazygit,
    run = util.float_term("lazygit") },

  -- system -----------------------------------------------------------------
  health = { icon = "health", label = "Check health", key = "C", run = "checkhealth" },
  lsp_info = { icon = "lsp", label = "LSP information", key = "I", run = "checkhealth vim.lsp" },
  messages = { icon = "messages", label = "Messages", key = "M", run = "messages" },
  sync = { icon = "sync", label = "Sync plugins", key = "S", cond = lazy, run = "Lazy sync" },
  check_updates = { icon = "updates", label = "Check plugin updates", key = "U", cond = lazy,
    run = "Lazy check" },
  mason = { icon = "mason", label = "Mason", key = "N", cond = mason, run = "Mason" },
  nvim_help = { icon = "help", label = "Neovim help", key = "V", run = "help" },
}

-- the registry entry for `name` (built-in merged with opts.items), or nil
function M.lookup(name)
  local builtin = M.builtin[name]
  local user = config.options.items and config.options.items[name]
  if not builtin and not user then return nil end
  if builtin and user then return vim.tbl_deep_extend("force", builtin, user) end
  return vim.tbl_extend("force", {}, builtin or user)
end

local function normalize(item)
  local run = item.run
  if type(run) == "string" then
    item.run = cmd(run)
  elseif type(run) == "function" then
    item.run = util.safe(run)
  end
  return item
end

-- spec -> item table, or nil when it is unknown / its `cond` is false
--   "name"                            registry entry
--   { "name", key = "x", ... }        registry entry with overrides
--   { label = "...", run = ... }      a literal item
function M.resolve(spec)
  local item
  if type(spec) == "string" then
    item = M.lookup(spec)
    if not item then
      util.warn("unknown item '" .. spec .. "'")
      return nil
    end
  elseif type(spec) == "table" then
    local name = spec[1]
    if name then
      local base = M.lookup(name)
      if not base then
        util.warn("unknown item '" .. tostring(name) .. "'")
        return nil
      end
      local overrides = vim.tbl_extend("force", {}, spec)
      overrides[1] = nil
      item = vim.tbl_deep_extend("force", base, overrides)
    else
      item = vim.tbl_extend("force", {}, spec)
    end
  else
    return nil
  end
  if item.cond then
    local ok, show = pcall(item.cond)
    if ok and not show then return nil end
  end
  return normalize(item)
end

return M
