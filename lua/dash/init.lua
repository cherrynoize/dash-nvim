-- dash-nvim: a multi-panel, fully configurable dashboard for Neovim.
--
--   require("dash").setup({ ... })   -- see :h dash / the README for every option
--   :Dash                            -- open it any time
--
-- Public API
--   setup(opts)                     configure (and arm autostart)
--   open()                          open the dashboard in the current window
--   refresh()                       rebuild all panels of an open dashboard
--   register_item(name, spec)       add / replace an entry of the item registry
--   register_panel(name, factory)   add / replace a panel preset
--   register_chip(name, fn)         add / replace a status chip

local config = require("dash.config")
local highlights = require("dash.highlights")
local state = require("dash.state")
local render = require("dash.render")
local nav = require("dash.nav")
local panels = require("dash.panels")
local items = require("dash.items")
local util = require("dash.util")

local api, fn = vim.api, vim.fn

local M = {}

-------------------------------------------------------------------------------
-- Cursor hiding (restored whenever you leave the dashboard)
-------------------------------------------------------------------------------
local saved_cursor

local function hide_cursor()
  if not config.options.hide_cursor then return end
  if not saved_cursor then saved_cursor = vim.o.guicursor end
  vim.o.guicursor = "a:DashCursor/DashCursor"
end

local function show_cursor()
  if saved_cursor then
    vim.o.guicursor = saved_cursor
    saved_cursor = nil
  end
end

-------------------------------------------------------------------------------
-- Building blocks
-------------------------------------------------------------------------------
local function resolve_user()
  local u = config.options.user
  if u == false then return "" end
  if type(u) == "function" then
    local ok, v = pcall(u)
    u = ok and v or nil
  end
  if type(u) == "string" then return u end
  return os.getenv("USER") or os.getenv("USERNAME") or "operator"
end

local function build_panels()
  local list = {}
  for _, spec in ipairs(config.options.panels or {}) do
    local ok, p = pcall(panels.build, spec)
    if ok and p then
      list[#list + 1] = p
    elseif not ok then
      util.warn("panel failed: " .. tostring(p))
    end
  end
  if #list == 0 then
    list[1] = {
      title = "DASH", style = "primary", sel = 1, off = 0,
      items = { { icon = "file", label = "No panels configured" } },
    }
  end
  for _, p in ipairs(list) do nav.clamp_scroll(p) end
  return list
end

-------------------------------------------------------------------------------
-- Keymaps (buffer-local)
-------------------------------------------------------------------------------
local function unmap_all(buf)
  for _, lhs in ipairs(state.mapped) do
    pcall(vim.keymap.del, "n", lhs, { buffer = buf })
  end
  state.mapped = {}
end

local function bind_keys(buf)
  unmap_all(buf)
  local o = config.options
  local K = o.keys or {}

  local function map(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true })
    state.mapped[#state.mapped + 1] = lhs
  end

  -- keys that item hotkeys must never steal (and the first key of chords like gg)
  local bound = {}
  local function reserve(lhs)
    bound[lhs] = true
    if not lhs:match("^<") and #lhs > 1 then bound[lhs:sub(1, 1)] = true end
  end
  local function bind(keys, rhs)
    for _, lhs in ipairs(util.keylist(keys)) do
      reserve(lhs)
      map(lhs, rhs)
    end
  end

  -- inside a panel
  bind(K.next_item, function() nav.move(1) end)
  bind(K.prev_item, function() nav.move(-1) end)
  bind(K.page_down, function() nav.page(1) end)
  bind(K.page_up, function() nav.page(-1) end)
  bind(K.first, function() nav.goto_index(1) end)
  bind(K.last, function() nav.goto_index(-1) end)
  bind(K.select, function() nav.activate() end)

  -- between panels
  bind(K.panel_left, function() nav.nav_panel(-1, 0) end)
  bind(K.panel_down, function() nav.nav_panel(0, 1) end)
  bind(K.panel_up, function() nav.nav_panel(0, -1) end)
  bind(K.panel_right, function() nav.nav_panel(1, 0) end)
  bind(K.next_panel, function() nav.cycle_panel(1) end)
  bind(K.prev_panel, function() nav.cycle_panel(-1) end)

  -- mouse
  if o.mouse then
    map("<LeftMouse>", function() nav.click(false) end)
    map("<2-LeftMouse>", function() nav.click(true) end)
    map("<ScrollWheelDown>", function() nav.wheel(1) end)
    map("<ScrollWheelUp>", function() nav.wheel(-1) end)
    for _, k in ipairs({ "<LeftDrag>", "<LeftRelease>", "<RightMouse>", "<3-LeftMouse>", "<4-LeftMouse>" }) do
      map(k, "<Nop>")
    end
  end

  -- user maps
  for lhs, fnc in pairs(K.extra or {}) do
    reserve(lhs)
    map(lhs, function()
      local p = state.panels[state.active]
      fnc({ panel = p, item = p and p.items[p.sel] })
    end)
  end

  -- per-item hotkeys
  for pi, p in ipairs(state.panels) do
    for ii, item in ipairs(p.items) do
      local key = item.key
      if type(key) == "string" and item.hot ~= false and not bound[key] then
        bound[key] = true
        map(key, function()
          state.active = pi
          p.sel = ii
          nav.clamp_scroll(p)
          render.render()
          if item.run then item.run(item, p) end
        end)
      end
    end
  end

  -- this is a read-only screen: neutralise keys that would try to edit or
  -- move the (hidden) cursor sideways
  for _, k in ipairs(util.keylist(K.block)) do
    if not bound[k] then map(k, "<Nop>") end
  end
end

-------------------------------------------------------------------------------
-- Open / refresh
-------------------------------------------------------------------------------
function M.open()
  -- allow :Dash without a setup() call
  if not config.ready then M.setup({ autostart = false }) end
  local o = config.options

  local old = api.nvim_get_current_buf()
  local buf = api.nvim_create_buf(false, true)
  api.nvim_set_current_buf(buf)
  local win = api.nvim_get_current_win()

  -- drop the empty startup buffer
  if api.nvim_buf_is_valid(old) and old ~= buf and vim.bo[old].buftype == ""
    and api.nvim_buf_get_name(old) == "" and not vim.bo[old].modified
    and api.nvim_buf_line_count(old) <= 1
    and (api.nvim_buf_get_lines(old, 0, 1, false)[1] or "") == "" then
    pcall(api.nvim_buf_delete, old, { force = true })
  end

  for k, v in pairs({
    buftype = "nofile", bufhidden = "wipe", swapfile = false,
    buflisted = false, filetype = o.filetype or "dash",
  }) do
    vim.bo[buf][k] = v
  end

  for k, v in pairs(o.window_options or {}) do
    -- scope = "local" (like :setlocal) so nothing leaks into files opened later
    pcall(api.nvim_set_option_value, k, v, { scope = "local", win = win })
  end

  state.user = resolve_user()
  state.buf = buf
  state.active = 1
  state.hit = {}
  state.refresh_context()
  state.panels = build_panels()

  bind_keys(buf)

  -- buffer lifecycle
  local g = api.nvim_create_augroup("DashBuf", { clear = true })
  api.nvim_create_autocmd("BufEnter", {
    group = g, buffer = buf,
    callback = function()
      hide_cursor()
      vim.schedule(render.render)
    end,
  })
  api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
    group = g, buffer = buf, callback = show_cursor,
  })
  api.nvim_create_autocmd("BufWipeout", {
    group = g, buffer = buf,
    callback = function()
      if state.buf == buf then state.buf = nil end
    end,
  })

  hide_cursor()
  render.render()
  vim.schedule(render.render) -- once more after the UI has settled on its final size

  api.nvim_exec_autocmds("User", { pattern = "DashOpened", modeline = false })
  if o.on_open then
    local ok, err = pcall(o.on_open, { buf = buf, win = win })
    if not ok then util.warn("on_open: " .. tostring(err)) end
  end
end

-- rebuild panels (and hotkeys) of the open dashboard, e.g. after the project
-- list or the item registry changed
function M.refresh()
  local buf = state.buf
  if not (buf and api.nvim_buf_is_valid(buf)) then return end
  state.refresh_context()
  state.panels = build_panels()
  if state.active > #state.panels then state.active = 1 end
  bind_keys(buf)
  render.render()
end

-------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------
function M.setup(opts)
  config.setup(opts)
  highlights.apply()

  local o = config.options
  local g = api.nvim_create_augroup("Dash", { clear = true })

  for _, name in ipairs(o.commands or {}) do
    api.nvim_create_user_command(name, function() M.open() end, { desc = "Open the Dash dashboard" })
  end

  api.nvim_create_autocmd("ColorScheme", {
    group = g,
    callback = function()
      highlights.apply()
      render.render()
    end,
  })
  api.nvim_create_autocmd({ "VimResized", "WinResized", "UIEnter" }, {
    group = g,
    callback = function() vim.schedule(render.render) end,
  })
  api.nvim_create_autocmd("User", {
    group = g, pattern = "LazyVimStarted",
    callback = function() vim.schedule(render.render) end,
  })

  if o.autostart == false then return end

  local function autostart()
    if vim.g.dash_disable or fn.argc() > 0 then return end
    local buf = api.nvim_get_current_buf()
    if api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then return end
    if api.nvim_buf_line_count(buf) > 1 then return end
    if (api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") ~= "" then return end
    M.open()
  end

  if vim.v.vim_did_enter == 1 then
    vim.schedule(autostart)
  else
    api.nvim_create_autocmd("VimEnter", { group = g, once = true, callback = autostart })
  end
end

-------------------------------------------------------------------------------
-- Registration helpers
-------------------------------------------------------------------------------
state.rebuild = M.refresh

function M.register_item(name, spec)
  items.builtin[name] = spec
end

function M.register_panel(name, factory)
  panels.register(name, factory)
end

function M.register_chip(name, f)
  render.chips[name] = f
end

return M
