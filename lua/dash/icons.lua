-- dash-nvim: icon sets (Nerd Font codepoints) and name -> glyph resolution.
--
-- Items refer to icons by name (`icon = "find_files"`), by codepoint
-- (`icon = 0xF0770`) or by a literal glyph (`icon = ""`).
-- Add your own set:  require("dash.icons").sets.mine = { find_files = 0xF002, ... }
-- and select it with  icons = { set = "mine" }  (missing names fall back to "md").

local config = require("dash.config")
local fn = vim.fn

local M = {}

M.sets = {
  -- Nerd Fonts v3 Material Design icons
  md = {
    -- quick actions
    find_files = 0xF0770, new_file = 0xF0752, config = 0xF0493, plugins = 0xF0431, quit = 0xF0425,
    terminal = 0xF07B7,
    -- search
    find_word = 0xF0349, find_string = 0xF027E, open_files = 0xF018F, buffers = 0xF0328,
    diagnostics = 0xF0026, marks = 0xF00C0, registers = 0xF0147, keymaps = 0xF030C,
    commands = 0xF018D, help_tags = 0xF02D7, man = 0xF00BA, resume = 0xF02DA,
    -- projects
    projects = 0xF0257,
    -- git
    git_files = 0xF0219, git_changes = 0xF03EB, git_commits = 0xF0718, git_branches = 0xF062C,
    git_status = 0xF02A2, lazygit = 0xF062D, git_stash = 0xF003C,
    -- system
    health = 0xF05F6, messages = 0xF0361, sync = 0xF0450, updates = 0xF01DA,
    mason = 0xF05B7, lsp = 0xF048B, help = 0xF0625,
    -- misc
    file = 0xF0214, colorscheme = 0xF03D8,
    -- status chips
    branch = 0xE0A0, folder = 0xF024B, version = 0xF0174, startup = 0xF140B,
  },
  -- Font Awesome
  fa = {
    find_files = 0xF07C, new_file = 0xF15B, config = 0xF013, plugins = 0xF1E6, quit = 0xF011,
    terminal = 0xF120,
    find_word = 0xF002, find_string = 0xF10D, open_files = 0xF0C5, buffers = 0xF24D,
    diagnostics = 0xF071, marks = 0xF02E, registers = 0xF0EA, keymaps = 0xF11C,
    commands = 0xF120, help_tags = 0xF059, man = 0xF02D, resume = 0xF01E,
    projects = 0xF115,
    git_files = 0xF1D3, git_changes = 0xF044, git_commits = 0xE729, git_branches = 0xE725,
    git_status = 0xE702, lazygit = 0xF1D2, git_stash = 0xF187,
    health = 0xF21E, messages = 0xF075, sync = 0xF021, updates = 0xF019,
    mason = 0xF0AD, lsp = 0xF0E8, help = 0xF128,
    file = 0xF016, colorscheme = 0xF1FC,
    branch = 0xE0A0, folder = 0xF07B, version = 0xF121, startup = 0xF0E7,
  },
}

local function active()
  local o = config.options.icons
  if type(o) == "string" then return o, {} end
  o = o or {}
  return o.set or "md", o.overrides or {}
end

-- the value (number or string) registered for an icon name, or nil
function M.get(name)
  local set_name, overrides = active()
  local v = overrides[name]
  if v == nil then
    local set = M.sets[set_name] or M.sets.md
    v = set[name]
  end
  if v == nil then v = M.sets.md[name] end
  return v
end

-- name | codepoint | literal glyph  ->  glyph string
function M.resolve(icon)
  if icon == nil or icon == false then return "" end
  if type(icon) == "number" then return fn.nr2char(icon) end
  if type(icon) ~= "string" then return "" end
  local v = M.get(icon)
  if v == nil then return icon end
  if type(v) == "number" then return fn.nr2char(v) end
  return v
end

return M
