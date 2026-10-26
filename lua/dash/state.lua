-- dash-nvim: runtime state shared by the modules.

local util = require("dash.util")

local S = {
  buf = nil,       -- dashboard buffer
  user = "",       -- name shown in the greeting
  active = 1,      -- index of the focused panel
  ncols = 1,       -- columns used by the last render
  hit = {},        -- line -> list of { c1, c2, panel, item } (mouse hit boxes)
  panels = nil,    -- built panels
  branch = nil,    -- cached git branch (refreshed on open / project switch)
  mapped = {},     -- buffer-local lhs we created (so they can be rebound)
}

-- replaced by dash.render when it loads
function S.render() end

-- rebuild all panels + redraw; replaced by dash (init) when it loads
function S.rebuild() end

function S.refresh_context()
  S.branch = util.git_branch()
end

return S
