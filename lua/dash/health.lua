-- dash-nvim: :checkhealth dash

local M = {}

function M.check()
  local h = vim.health
  local start = h.start or h.report_start
  local ok = h.ok or h.report_ok
  local warn = h.warn or h.report_warn
  local err = h.error or h.report_error

  start("dash-nvim")

  if vim.fn.has("nvim-0.9") == 1 then
    ok("Neovim " .. tostring(vim.version()))
  else
    err("Neovim 0.9+ is required")
  end

  if vim.o.termguicolors then
    ok("'termguicolors' is enabled")
  else
    warn("'termguicolors' is off: the dashboard colors need it (set vim.o.termguicolors = true)")
  end

  local config = require("dash.config")
  if config.ready then
    ok("setup() was called")
  else
    warn("setup() has not been called: defaults are used (call require('dash').setup({...}))")
  end

  start("dash-nvim: optional dependencies")
  local function optional(mod, what)
    if pcall(require, mod) then
      ok(mod .. " found (" .. what .. ")")
    else
      warn(mod .. " not found (" .. what .. ")")
    end
  end
  optional("telescope", "pickers behind most items; those items are hidden without it")
  optional("nvim-web-devicons", "file icons in the Recent files panel")
  optional("project", "project.nvim: source of the Projects panel")
  optional("toggleterm", "floating Lazygit terminal (plain :terminal otherwise)")
  if vim.fn.executable("lazygit") == 1 then
    ok("lazygit executable found")
  else
    warn("lazygit not found: the Lazygit item is hidden")
  end
  if vim.fn.executable("git") == 1 then
    ok("git executable found (branch chip)")
  else
    warn("git not found: the branch chip is hidden")
  end
end

return M
