-- dash-nvim: highlight groups. All of them come from `colors`; anything can be
-- replaced through the `highlights` option.

local config = require("dash.config")

local M = {}

function M.groups(C)
  return {
    DashNormal        = { fg = C.text, bg = C.bg },
    DashCursor        = { blend = 100, nocombine = true },
    DashBorder        = { fg = C.border },
    DashBorderActive  = { fg = C.purple },
    DashTitle         = { fg = C.muted, bold = true },
    DashTitleActive   = { fg = C.soft, bold = true },
    DashCount         = { fg = C.muted },
    DashThumb         = { fg = C.soft },
    DashMuted         = { fg = C.muted },
    DashHeader        = { fg = C.text, bold = true },
    DashHeaderDiamond = { fg = C.orange },
    DashGreeting      = { fg = C.text, bold = true },
    DashGreetingName  = { fg = C.blue, bold = true },
    -- neon blue buttons ("primary" style)
    DashBtn           = { fg = C.blue, bg = C.blue_bg },
    DashBtnKey        = { fg = C.blue_txt, bg = C.blue_key, bold = true },
    -- the focused row (any panel)
    DashBtnActive     = { fg = C.bg, bg = C.blue, bold = true },
    DashBtnActiveDim  = { fg = C.blue_dim, bg = C.blue },
    DashBtnKeyActive  = { fg = "#EAFBFF", bg = C.blue_deep, bold = true },
    -- purple rows ("item" style)
    DashItem          = { fg = C.text, bg = C.surface },
    DashItemDim       = { fg = C.muted, bg = C.surface },
    DashItemKey       = { fg = C.soft, bg = C.elevated, bold = true },
    -- status chips + hints
    DashCap           = { fg = C.elevated },
    DashChip          = { fg = C.soft, bg = C.elevated },
    DashChipAccent    = { fg = C.orange, bg = C.elevated },
    DashChipOk        = { fg = C.ok, bg = C.elevated },
    DashHint          = { fg = C.muted },
    DashHintKey       = { fg = C.soft, bold = true },
  }
end

function M.apply()
  local o = config.options
  local groups = M.groups(o.colors)

  local user = o.highlights
  if type(user) == "function" then user = user(o.colors) end
  if type(user) == "table" then
    for name, spec in pairs(user) do
      if type(spec) == "string" then spec = { link = spec } end
      if type(spec) == "table" then
        if spec.link then
          groups[name] = spec
        else
          groups[name] = vim.tbl_extend("force", groups[name] or {}, spec)
        end
      end
    end
  end

  for name, spec in pairs(groups) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

return M
