-- dash-nvim: drawing. Builds the lines + highlight ranges for the whole screen
-- and writes them into the dashboard buffer.

local config = require("dash.config")
local state = require("dash.state")
local util = require("dash.util")
local icons = require("dash.icons")

local api, fn = vim.api, vim.fn
local dw = util.dw
local centered, as_pieces = util.centered, util.as_pieces

local ns = api.nvim_create_namespace("dash")

local M = {}

local function opts() return config.options end

-------------------------------------------------------------------------------
-- Styles / sizes
-------------------------------------------------------------------------------
function M.style(name)
  local styles = opts().styles
  return styles[name] or styles.primary
end

-- entries shown at once; a footer row takes one of the panel's rows
function M.visible_of(p)
  local base = p.visible or opts().layout.visible
  return math.max(1, base - (p.footer and 1 or 0))
end

-------------------------------------------------------------------------------
-- Rows
-------------------------------------------------------------------------------
local function label_of(item)
  local l = item.label
  if type(l) == "function" then l = l(item) end
  return l or ""
end

-- text of the keycap: a dynamic / unbound `badge`, else the hotkey
local function badge_of(item)
  local b = item.badge
  if type(b) == "function" then b = b(item) end
  if b == nil or b == "" then b = item.key end
  if type(b) ~= "string" then return nil end
  return b
end

local function pill(item, st, selected, width)
  local left = " " .. icons.resolve(item.icon) .. "  "
  local key = badge_of(item)
  if (key == nil or key == "") and selected and item.run then
    key = opts().select_hint or ""
  end
  key = key or ""
  local keyw = key ~= "" and (dw(key) + 2) or 0
  local room = width - dw(left) - keyw - 1
  local name = util.trunc_right(label_of(item), room)
  local spare = room - dw(name)
  local dimtxt = ""
  if item.dim and item.dim ~= "" and spare > 6 then
    dimtxt = "  " .. util.trunc_left(item.dim, spare - 2)
  end
  local gap = width - dw(left .. name .. dimtxt) - keyw
  local pieces = {
    { left .. name, st.base },
    { dimtxt, st.dim },
    { string.rep(" ", math.max(0, gap)), st.base },
  }
  if keyw > 0 then pieces[#pieces + 1] = { " " .. key .. " ", st.key } end
  return pieces
end

-- returns the panel's rows (each a list of {text, hl} pieces, panel_width wide),
-- the index of the selected row, and a map row -> item index (for the mouse)
local function panel_rows(p, is_active, gaps)
  local o = opts()
  local L, b = o.layout, o.border
  local PW = L.panel_width
  local PILL = PW - 4
  local rows, sel_row, item_at = {}, nil, {}
  local bc = is_active and "DashBorderActive" or "DashBorder"
  local st = M.style(p.style)
  local active_st = st.active or o.styles.active
  local n = #p.items
  local vis = M.visible_of(p)
  local scrollable = n > vis
  local title = p.title or ""
  local w = dw(title)

  -- top border (+ "3/24" counter on scrollable panels)
  local top = {
    { b.tl .. b.h .. " ", bc },
    { title, is_active and "DashTitleActive" or "DashTitle" },
    { " ", bc },
  }
  if scrollable and L.counter then
    local chip = string.format("%d/%d", p.sel, n)
    top[#top + 1] = { string.rep(b.h, math.max(1, PW - 8 - w - #chip)), bc }
    top[#top + 1] = { " " .. chip .. " ", "DashCount" }
    top[#top + 1] = { b.h .. b.tr, bc }
  else
    top[#top + 1] = { string.rep(b.h, math.max(1, PW - 5 - w)) .. b.tr, bc }
  end
  rows[#rows + 1] = top

  -- scrollbar geometry (the right border doubles as the track)
  local show_bar = scrollable and L.scrollbar
  local area_items = gaps and (vis * 2 - 1) or vis
  local thumb_len, thumb_start = 0, 0
  if show_bar then
    thumb_len = math.max(1, math.floor(area_items * vis / n + 0.5))
    thumb_start = math.floor((area_items - thumb_len) * p.off / (n - vis) + 0.5)
  end
  local area_row = 0
  local function right_border()
    local r = area_row
    area_row = area_row + 1
    if show_bar and r < area_items and r >= thumb_start and r < thumb_start + thumb_len then
      return { b.thumb, "DashThumb" }
    end
    return { b.v, bc }
  end
  -- a blank row carrying the panel's own entry background (between entries,
  -- for unused slots, below the last entry); part of the scrollbar track
  local function gap_row()
    return { { b.v, bc }, { " " }, { string.rep(" ", PILL), st.base }, { " " }, right_border() }
  end
  -- padding row above the first / below the last entry: same background but a
  -- plain border, not part of the scrollbar track
  local function pad_row()
    return { { b.v, bc }, { " " }, { string.rep(" ", PILL), st.base }, { " " }, { b.v, bc } }
  end

  for _ = 1, L.padding or 0 do rows[#rows + 1] = pad_row() end

  for slot = 1, vis do
    local idx = p.off + slot
    local item = p.items[idx]
    if item then
      local is_sel = is_active and idx == p.sel
      local row = { { b.v, bc }, { " " } }
      for _, piece in ipairs(pill(item, is_sel and active_st or st, is_sel, PILL)) do
        row[#row + 1] = piece
      end
      row[#row + 1] = { " " }
      row[#row + 1] = right_border()
      rows[#rows + 1] = row
      item_at[#rows] = idx
      if is_sel then sel_row = #rows end
    else
      rows[#rows + 1] = gap_row()
    end
    if gaps and slot < vis then rows[#rows + 1] = gap_row() end
  end

  -- footer: one more row of entry background below the last entry
  if p.footer then
    if gaps then rows[#rows + 1] = gap_row() end
    local ok, footer = pcall(p.footer, p.items[p.sel], p)
    if not ok or type(footer) ~= "table" then footer = {} end
    local frow = { { b.v, bc }, { " " }, { " ", st.base } }
    for _, piece in ipairs(footer) do frow[#frow + 1] = piece end
    frow[#frow + 1] = { string.rep(" ", math.max(0, PILL - 1 - util.pieces_width(footer))), st.base }
    frow[#frow + 1] = { " " }
    frow[#frow + 1] = { b.v, bc }
    rows[#rows + 1] = frow
  end

  for _ = 1, L.padding or 0 do rows[#rows + 1] = pad_row() end
  rows[#rows + 1] = { { b.bl .. string.rep(b.h, PW - 2) .. b.br, bc } }
  return rows, sel_row, item_at
end

-------------------------------------------------------------------------------
-- Chips
-------------------------------------------------------------------------------
local function startup_ms()
  local ok, stats = pcall(function() return require("lazy").stats() end)
  if ok and stats and stats.startuptime and stats.startuptime > 0 then
    return math.floor(stats.startuptime + 0.5)
  end
end

-- name -> function(opts) returning { icon, text, hl } or nil
M.chips = {
  branch = function()
    if state.branch then return { icon = "branch", text = state.branch, hl = "DashChip" } end
  end,
  cwd = function(o)
    return {
      icon = "folder",
      text = util.trunc_left(fn.fnamemodify(fn.getcwd(), ":~"), o.max or 22),
      hl = "DashChip",
    }
  end,
  version = function()
    local v = vim.version()
    return { icon = "version", text = string.format("v%d.%d.%d", v.major, v.minor, v.patch), hl = "DashChipAccent" }
  end,
  startup = function()
    local ms = startup_ms()
    if ms then return { icon = "startup", text = ms .. "ms", hl = "DashChipOk" } end
  end,
}

local function resolve_chip(spec)
  local f, o = nil, {}
  if type(spec) == "function" then
    f = spec
  elseif type(spec) == "string" then
    f = M.chips[spec]
  elseif type(spec) == "table" then
    f = type(spec[1]) == "function" and spec[1] or M.chips[spec[1]]
    o = spec
  end
  if not f then return nil end
  local ok, chip = pcall(f, o)
  if ok and type(chip) == "table" and chip.text and chip.text ~= "" then return chip end
end

-------------------------------------------------------------------------------
-- Sections
-------------------------------------------------------------------------------
local H = {}

function H.header(ctx, put)
  local h = opts().header
  if not h then return end
  if type(h) == "function" then
    for _, line in ipairs(h(ctx) or {}) do put(centered(as_pieces(line, "DashHeader"), ctx.width)) end
    return
  end
  if h.lines then
    local lines = type(h.lines) == "function" and h.lines(ctx) or h.lines
    for _, line in ipairs(lines or {}) do
      put(centered(as_pieces(line, h.hl or "DashHeader"), ctx.width))
    end
    return
  end
  local has_icon = h.icon and h.icon ~= ""
  local pieces = {}
  if has_icon then pieces[#pieces + 1] = { h.icon, h.icon_hl or "DashHeaderDiamond" } end
  pieces[#pieces + 1] = { (has_icon and "  " or "") .. (h.text or ""), h.hl or "DashHeader" }
  put(centered(pieces, ctx.width))
end

function H.greeting(ctx, put)
  local g = opts().greeting
  if not g then return end
  local hour = tonumber(os.date("%H"))
  if type(g) == "function" then
    local ok, r = pcall(g, { user = state.user, hour = hour, width = ctx.width })
    if ok and r then put(centered(as_pieces(r, "DashGreeting"), ctx.width)) end
    return
  end
  local m = g.messages or {}
  local msg
  if hour < 5 then msg = m.late
  elseif hour < 12 then msg = m.morning
  elseif hour < 18 then msg = m.afternoon
  else msg = m.evening end

  local pieces = {}
  local name = state.user
  local show_name = g.show_name ~= false and name and name ~= ""
  if msg and msg ~= "" then
    pieces[#pieces + 1] = { msg .. (show_name and (g.separator or ", ") or ""), "DashGreeting" }
  end
  if show_name then pieces[#pieces + 1] = { name, "DashGreetingName" } end
  if #pieces > 0 then put(centered(pieces, ctx.width)) end
end

function H.date(ctx, put)
  local d = opts().date
  if not d then return end
  local text
  if type(d) == "function" then text = d() else text = os.date(d) end
  if text and text ~= "" then put(centered({ { text, "DashMuted" } }, ctx.width)) end
end

function H.chips(ctx, put)
  local list = opts().chips
  if not list then return end
  local caps = opts().chip_caps or { left = "", right = "" }
  local pieces = {}
  for _, spec in ipairs(list) do
    local c = resolve_chip(spec)
    if c then
      if #pieces > 0 then pieces[#pieces + 1] = { " " } end
      local icon = icons.resolve(c.icon)
      local body = (icon ~= "" and (icon .. " ") or "") .. c.text
      pieces[#pieces + 1] = { caps.left or "", "DashCap" }
      pieces[#pieces + 1] = { " " .. body .. " ", c.hl or "DashChip" }
      pieces[#pieces + 1] = { caps.right or "", "DashCap" }
    end
  end
  if #pieces > 0 then put(centered(pieces, ctx.width)) end
end

function H.hints(ctx, put)
  local hints = opts().hints
  if not hints then return end
  local pieces = {}
  for i, h in ipairs(hints) do
    if i > 1 then pieces[#pieces + 1] = { "    " } end
    pieces[#pieces + 1] = { h[1], "DashHintKey" }
    pieces[#pieces + 1] = { " " .. (h[2] or ""), "DashHint" }
  end
  if #pieces > 0 then put(centered(pieces, ctx.width)) end
end

-------------------------------------------------------------------------------
-- Full build (one pass, with or without blank rows between entries)
-------------------------------------------------------------------------------
local function build(width, height, gaps)
  local o = opts()
  local L = o.layout
  local lines, marks, hit = {}, {}, {}
  local sel_line
  local ncols = 1

  local function emit(pieces)
    local row0, col, parts = #lines, 0, {}
    for _, p in ipairs(pieces) do
      local t = p[1]
      if #t > 0 then
        if p[2] then marks[#marks + 1] = { row0, col, col + #t, p[2] } end
        parts[#parts + 1] = t
        col = col + #t
      end
    end
    lines[#lines + 1] = table.concat(parts)
    return row0 + 1
  end

  local top = L.top_padding
  if type(top) ~= "number" then top = gaps and 2 or 1 end
  for _ = 1, top do emit({}) end

  local dirty = false -- something was drawn since the last spacer
  local function put(pieces)
    emit(pieces)
    dirty = true
  end

  local ctx = { width = width, height = height, user = state.user, gaps = gaps }

  local function draw_panels()
    local panels = state.panels or {}
    if #panels == 0 then return end
    local PW, GAP = L.panel_width, L.gap
    ncols = math.max(1, math.min(L.max_columns or 3, #panels, math.floor((width + GAP) / (PW + GAP))))
    local nrows = math.ceil(#panels / ncols)
    local block_w = ncols * PW + (ncols - 1) * GAP
    local pad = string.rep(" ", math.max(0, math.floor((width - block_w) / 2)))

    for gr = 1, nrows do
      local first = (gr - 1) * ncols + 1
      local last = math.min(first + ncols - 1, #panels)
      local grid, sel_rows, item_ats, height_rows = {}, {}, {}, 0
      for pi = first, last do
        grid[pi], sel_rows[pi], item_ats[pi] = panel_rows(panels[pi], pi == state.active, gaps)
        height_rows = math.max(height_rows, #grid[pi])
      end
      for r = 1, height_rows do
        local pieces = { { pad } }
        local hits = {}
        for pi = first, last do
          if pi > first then pieces[#pieces + 1] = { string.rep(" ", GAP) } end
          local row = grid[pi][r]
          if row then
            for _, piece in ipairs(row) do pieces[#pieces + 1] = piece end
          else
            pieces[#pieces + 1] = { string.rep(" ", PW) } -- shorter panel: blank
          end
          local c1 = #pad + (pi - first) * (PW + GAP) + 1
          hits[#hits + 1] = { c1 = c1, c2 = c1 + PW - 1, panel = pi, item = item_ats[pi][r] }
        end
        local lnum = emit(pieces)
        hit[lnum] = hits
        if state.active >= first and state.active <= last and sel_rows[state.active] == r then
          sel_line = lnum
        end
      end
      if gr < nrows then emit({}) end
    end
    dirty = true
  end

  for _, sec in ipairs(o.sections or {}) do
    if sec == "spacer" then
      if dirty then
        emit({})
        dirty = false
      end
    elseif sec == "panels" then
      draw_panels()
    elseif type(sec) == "string" and H[sec] then
      H[sec](ctx, put)
    elseif type(sec) == "function" then
      local ok, extra = pcall(sec, ctx)
      if ok and type(extra) == "table" then
        for _, line in ipairs(extra) do put(centered(as_pieces(line, "DashMuted"), width)) end
      end
    end
  end

  return { lines = lines, marks = marks, hit = hit, sel_line = sel_line, ncols = ncols }
end

-------------------------------------------------------------------------------
-- Render (called on every state change and on resize)
-------------------------------------------------------------------------------
function M.render()
  local buf = state.buf
  if not (buf and api.nvim_buf_is_valid(buf) and state.panels) then return end
  local win = fn.bufwinid(buf)
  if win == -1 then return end

  local width, height = api.nvim_win_get_width(win), api.nvim_win_get_height(win)
  local mode = opts().layout.gaps

  -- "auto": the roomy layout (blank rows between entries) if it fits
  local r
  if mode == true then
    r = build(width, height, true)
  elseif mode == false then
    r = build(width, height, false)
  else
    r = build(width, height, true)
    if #r.lines > height then r = build(width, height, false) end
  end
  state.hit = r.hit
  state.ncols = r.ncols

  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, r.lines)
  vim.bo[buf].modifiable = false
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(r.marks) do
    api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end
  -- park the (hidden) cursor on the selection so the window scrolls to follow it
  if r.sel_line then pcall(api.nvim_win_set_cursor, win, { r.sel_line, 0 }) end
end

state.render = M.render

return M
