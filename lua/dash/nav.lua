-- dash-nvim: navigation inside and between panels, selection, mouse.

local config = require("dash.config")
local state = require("dash.state")
local render = require("dash.render")

local fn = vim.fn

local M = {}

-- keep the selection inside the list and the selection inside the visible window
function M.clamp_scroll(p)
  local n, vis = #p.items, render.visible_of(p)
  p.sel = math.max(1, math.min(p.sel, n))
  if p.sel <= p.off then p.off = p.sel - 1 end
  if p.sel > p.off + vis then p.off = p.sel - vis end
  p.off = math.max(0, math.min(p.off, math.max(0, n - vis)))
end

-- single steps wrap around (layout.wrap); pass no_wrap for page jumps / the wheel
function M.move(delta, no_wrap)
  local p = state.panels[state.active]
  local n = #p.items
  local target = p.sel + delta
  if config.options.layout.wrap ~= false and not no_wrap and math.abs(delta) == 1 then
    if target < 1 then target = n elseif target > n then target = 1 end
  end
  p.sel = target
  M.clamp_scroll(p)
  render.render()
end

function M.page(direction)
  local p = state.panels[state.active]
  M.move(direction * render.visible_of(p), true)
end

function M.goto_index(i)
  local p = state.panels[state.active]
  p.sel = i == -1 and #p.items or i
  M.clamp_scroll(p)
  render.render()
end

function M.switch_panel(i)
  state.active = i
  render.render()
end

function M.cycle_panel(step)
  local n = #state.panels
  M.switch_panel((state.active - 1 + step) % n + 1)
end

-- spatial panel movement: H/J/K/L behave like h/j/k/l on the panel grid
function M.nav_panel(dx, dy)
  local n, cols, i = #state.panels, state.ncols, state.active
  local col = (i - 1) % cols
  local target
  if dx < 0 and col > 0 then target = i - 1
  elseif dx > 0 and col < cols - 1 and i < n then target = i + 1
  elseif dy > 0 and i + cols <= n then target = i + cols
  elseif dy < 0 and i - cols >= 1 then target = i - cols end
  if target then M.switch_panel(target) end
end

function M.activate()
  local p = state.panels[state.active]
  local item = p.items[p.sel]
  if item and item.run then item.run(item, p) end
end

-- mouse ------------------------------------------------------------------------
local function mouse_hit()
  local m = fn.getmousepos()
  if not state.buf or m.winid == 0 or m.winid ~= fn.bufwinid(state.buf) then return nil end
  for _, h in ipairs(state.hit[m.line] or {}) do
    if m.wincol >= h.c1 and m.wincol <= h.c2 then return h end
  end
end

function M.click(do_activate)
  local h = mouse_hit()
  if not h then return end
  state.active = h.panel
  local p = state.panels[h.panel]
  if h.item then
    p.sel = h.item
    M.clamp_scroll(p)
  end
  render.render()
  if do_activate and h.item then M.activate() end
end

function M.wheel(delta)
  local h = mouse_hit()
  if h then state.active = h.panel end
  M.move(delta, true)
end

return M
