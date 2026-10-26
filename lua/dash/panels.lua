-- dash-nvim: panels.
--
-- A panel spec in `opts.panels` is one of
--   "git"                                a preset by name
--   { "git", title = "VCS", ... }        a preset with overrides
--   { title = "...", items = { ... } }   a fully custom panel
--
-- Panel fields
--   title    text in the top border
--   style    row style ("primary", "item", or one defined in opts.styles)
--   items    list of item specs (see dash.items), or function(panel) that
--            returns that list and optionally the index to select first
--   visible  rows shown at once (default: layout.visible)
--   footer   function(selected_item, panel) -> list of { text, hl } pieces,
--            drawn in an extra row under the entries (takes one visible row)
--   empty    label shown when there are no items
--   sel      index selected on open
--   cond     function(panel) -> boolean; the panel is left out when false
--
-- Dynamic presets take extra options (set them next to the preset name):
--   recent        max, hotkeys, exclude, cwd_only
--   projects      source, reverse, max, open
--   colorschemes  exclude, filter, swatch, swatches, lazy

local config = require("dash.config")
local items_mod = require("dash.items")
local state = require("dash.state")
local util = require("dash.util")

local fn, api = vim.fn, vim.api

local M = { presets = {} }

-------------------------------------------------------------------------------
-- Static presets
-------------------------------------------------------------------------------
M.presets.actions = function()
  return {
    title = "QUICK ACTIONS", style = "primary",
    items = { "find_files", "new_file", "config", "plugins", "quit" },
  }
end

M.presets.search = function()
  return {
    title = "SEARCH", style = "primary",
    items = {
      "find_word", "find_string", "find_in_open", "buffers", "diagnostics", "marks",
      "registers", "keymaps", "commands", "help_tags", "man_pages", "resume",
    },
  }
end

M.presets.git = function()
  return {
    title = "GIT", style = "primary",
    cond = util.in_git_repo, -- only inside a git repo (override with cond = function() return true end to always show)
    items = {
      "git_files", "git_changes", "git_commits", "git_branches", "git_status",
      "git_stash", "lazygit",
    },
  }
end

M.presets.system = function()
  return {
    title = "SYSTEM", style = "item",
    items = { "health", "lsp_info", "messages", "sync", "mason", "check_updates", "nvim_help" },
  }
end

-------------------------------------------------------------------------------
-- recent files
-------------------------------------------------------------------------------
M.presets.recent = function()
  return {
    title = "RECENT FILES", style = "item",
    empty = "No recent files yet", empty_icon = "file",
    -- the bottom row shows the full path of the selected file
    footer = function(item)
      if item and item.path then
        return { { util.trunc_left(item.path, config.options.layout.panel_width - 6), "DashItemDim" } }
      end
    end,
    items = function(p)
      local max = p.max or 50
      local hotkeys = math.min(p.hotkeys or 9, 9)
      local exclude = p.exclude or { "/%.git/" }
      local has_icons, devicons = pcall(require, "nvim-web-devicons")
      local cwd = fn.getcwd()
      local items, seen = {}, {}
      for _, f in ipairs(vim.v.oldfiles or {}) do
        if #items >= max then break end
        local skip = seen[f] or fn.filereadable(f) ~= 1
        for _, pat in ipairs(exclude) do
          if not skip and f:match(pat) then skip = true end
        end
        if not skip and p.cwd_only and not vim.startswith(f, cwd) then skip = true end
        if not skip then
          seen[f] = true
          local name = fn.fnamemodify(f, ":t")
          local dir = fn.fnamemodify(f, ":~:.:h")
          if dir == "." then dir = "" end
          local icon
          if has_icons then
            icon = devicons.get_icon(name, fn.fnamemodify(f, ":e"), { default = true })
          end
          local i = #items + 1
          items[i] = {
            icon = icon or "file",
            label = name,
            dim = dir,
            path = fn.fnamemodify(f, ":~"),
            badge = tostring(i),
            key = i <= hotkeys and tostring(i) or nil,
            run = function() vim.cmd("edit " .. fn.fnameescape(f)) end,
          }
        end
      end
      return items
    end,
  }
end

-------------------------------------------------------------------------------
-- projects
-------------------------------------------------------------------------------
-- turn a raw entry (string path or { path, name } table) into { path, name }
local function normalize_project(e)
  if type(e) == "string" then
    return { path = e }
  elseif type(e) == "table" and type(e.path) == "string" then
    return { path = e.path, name = e.name }
  end
end

-- returns a list of { path, name }, or nil + a message
local function project_list(p)
  local src = p.source or "project.nvim"
  local raw
  if type(src) == "function" then
    local ok, list = pcall(src)
    if not (ok and type(list) == "table") then return nil, "project source failed" end
    raw = list
  else
    local ok, project = pcall(require, "project")
    if not ok then return nil, "project.nvim not found" end
    local got, list = pcall(project.get_recent_projects)
    if not got or type(list) ~= "table" then return {} end
    raw = list
  end

  local out = {}
  for _, e in ipairs(raw) do
    local entry = normalize_project(e)
    if entry then out[#out + 1] = entry end
  end
  return out
end

-- cd into the project, refresh the chips, then open it the way the panel says
local function open_project(path, p)
  return function()
    vim.cmd("cd " .. fn.fnameescape(path))
    -- rebuild: chips and panels that depend on the cwd (e.g. Git) change
    state.rebuild()
    local how = p.open or "find_files"
    if type(how) == "function" then
      how(path)
    elseif how == "find_files" and util.has_telescope() then
      require("telescope.builtin").find_files({
        cwd = path,
        prompt_title = "Files in " .. fn.fnamemodify(path, ":t"),
      })
    elseif how == "find_files" or how == "edit" then
      vim.cmd("edit .")
    end -- "none": only cd
  end
end

M.presets.projects = function()
  return {
    title = "PROJECTS", style = "item",
    empty = "No projects yet", empty_icon = "projects",
    items = function(p)
      local list, err = project_list(p)
      if not list then return { { icon = "projects", label = err } } end
      if p.reverse ~= false then
        local rev = {}
        for i = #list, 1, -1 do rev[#rev + 1] = list[i] end
        list = rev
      end
      local max = p.max or 50
      local items, sel = {}, 1
      for _, entry in ipairs(list) do
        if #items >= max then break end
        local path = fn.expand(entry.path)
        if fn.isdirectory(path) == 1 then
          -- prefer the project's name, fall back to the folder name
          local name = entry.name
          if type(name) ~= "string" or name == "" then
            name = fn.fnamemodify(path, ":t")
          end
          if name == "" then name = path end
          local dir = fn.fnamemodify(path, ":~:h")
          if util.same_dir(path, fn.getcwd()) then sel = #items + 1 end
          items[#items + 1] = {
            icon = "projects",
            label = name,
            dim = dir ~= "." and dir or "",
            -- the project you are currently in is marked with a dot
            badge = function() return util.same_dir(path, fn.getcwd()) and "●" or nil end,
            run = open_project(path, p),
          }
        end
      end
      if #items == 0 and (p.source == nil or p.source == "project.nvim") and fn.exists(":Project") == 2 then
        return { { icon = "projects", label = "No projects found - run ':Project add' to add one", run = "Project add" } }
      end
      return items, sel
    end,
  }
end

-------------------------------------------------------------------------------
-- colorschemes (with a palette strip in the footer)
-------------------------------------------------------------------------------
local function list_colorschemes(p)
  local exclude = {}
  for _, n in ipairs(p.exclude or {}) do exclude[n] = true end
  local seen, list = {}, {}
  local function add(n)
    if n and n ~= "" and not seen[n] and not exclude[n] and (not p.filter or p.filter(n)) then
      seen[n] = true
      list[#list + 1] = n
    end
  end
  for _, n in ipairs(fn.getcompletion("", "color")) do add(n) end
  -- also pick up themes from plugins lazy.nvim hasn't loaded yet
  if p.lazy ~= false then
    local ok, cfg = pcall(require, "lazy.core.config")
    if ok and cfg.plugins then
      for _, plug in pairs(cfg.plugins) do
        if plug.dir then
          for _, f in ipairs(fn.glob(plug.dir .. "/colors/*", false, true)) do
            add((fn.fnamemodify(f, ":t:r")))
          end
        end
      end
    end
  end
  table.sort(list)
  return list
end

local DEFAULT_SWATCHES = {
  { "Normal", "bg" }, { "Keyword", "fg" }, { "Function", "fg" },
  { "String", "fg" }, { "Type", "fg" }, { "Comment", "fg" },
}

-- swatch is drawn with "▆" (lower three quarters): a bit shorter than a full
-- block, so a thin gap of panel background separates it from the last entry;
-- use "▄" for a bigger gap or "█" for none.
local function swatch_row(p)
  local specs = p.swatches or DEFAULT_SWATCHES
  local glyph = p.swatch or "▆▆▆▆▆"
  local colors = config.options.colors
  local pieces = {}
  for i, s in ipairs(specs) do
    local ok, h = pcall(api.nvim_get_hl, 0, { name = s[1], link = false })
    local v = ok and h and h[s[2]] or nil
    api.nvim_set_hl(0, "DashSw" .. i, {
      fg = v and string.format("#%06x", v) or colors.muted,
      bg = colors.surface,
    })
    pieces[#pieces + 1] = { glyph, "DashSw" .. i }
    if i < #specs then pieces[#pieces + 1] = { "  ", "DashItem" } end
  end
  return pieces
end

M.presets.colorschemes = function()
  return {
    title = "COLORSCHEMES", style = "item",
    empty = "No colorschemes found", empty_icon = "colorscheme",
    footer = function(_, p) return swatch_row(p) end,
    items = function(p)
      local cur = vim.g.colors_name or "default"
      local items, sel = {}, 1
      for i, name in ipairs(list_colorschemes(p)) do
        if name == cur then sel = i end
        items[i] = {
          icon = "colorscheme",
          label = name,
          -- the active colorscheme is marked with a dot
          badge = function() return (vim.g.colors_name or "default") == name and "●" or nil end,
          run = function()
            local ok, err = pcall(vim.cmd.colorscheme, name)
            if not ok then util.warn(tostring(err)) end
            state.render()
          end,
        }
      end
      return items, sel
    end,
  }
end

-------------------------------------------------------------------------------
-- Building
-------------------------------------------------------------------------------
local function resolve_spec(spec)
  if type(spec) == "string" then spec = { spec } end
  if type(spec) ~= "table" then return nil end
  local name = spec[1]
  if not name then return spec end
  local factory = M.presets[name]
  if not factory then
    util.warn("unknown panel preset '" .. tostring(name) .. "'")
    return nil
  end
  local merged = vim.tbl_extend("force", factory(spec), spec)
  merged[1] = nil
  return merged
end

-- spec -> ready-to-draw panel (items resolved, selection initialised), or nil
function M.build(spec)
  local p = resolve_spec(spec)
  if not p then return nil end

  if p.cond then
    local ok, show = pcall(p.cond, p)
    if ok and not show then return nil end
  end

  local raw, sel = p.items, nil
  if type(raw) == "function" then
    local ok, a, b = pcall(raw, p)
    if ok then
      raw, sel = a, b
    else
      util.warn("panel '" .. tostring(p.title) .. "': " .. tostring(a))
      raw = {}
    end
  end

  local items = {}
  for _, s in ipairs(raw or {}) do
    local item = items_mod.resolve(s)
    if item then items[#items + 1] = item end
  end
  if #items == 0 then
    items[1] = { icon = p.empty_icon or "file", label = p.empty or "Nothing here" }
  end

  local panel = vim.tbl_extend("force", {}, p)
  panel.title = p.title or ""
  panel.style = p.style or "primary"
  panel.items = items
  panel.sel = type(p.sel) == "number" and p.sel or sel or 1
  panel.off = math.max(0, panel.sel - 2)
  return panel
end

-- add or replace a preset: factory(spec) -> panel spec
function M.register(name, factory)
  M.presets[name] = factory
end

return M
