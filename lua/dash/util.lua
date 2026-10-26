-- dash-nvim: small shared helpers (text, notifications, safe runners).

local M = {}
local fn = vim.fn
local dw = fn.strdisplaywidth

M.dw = dw
M.islist = vim.islist or vim.tbl_islist

function M.warn(msg)
  vim.notify("Dash: " .. msg, vim.log.levels.WARN)
end

-- truncate on the right / left with an ellipsis so the result fits in n cells
function M.trunc_right(s, n)
  if n < 2 then return "" end
  if dw(s) <= n then return s end
  return fn.strcharpart(s, 0, n - 1) .. "…"
end

function M.trunc_left(s, n)
  if n < 2 then return "" end
  if dw(s) <= n then return s end
  return "…" .. fn.strcharpart(s, fn.strchars(s) - (n - 1))
end

function M.pieces_width(pieces)
  local w = 0
  for _, p in ipairs(pieces) do w = w + dw(p[1]) end
  return w
end

-- prepend a margin so the pieces are centered in `width` (mutates `pieces`)
function M.centered(pieces, width)
  local m = math.max(0, math.floor((width - M.pieces_width(pieces)) / 2))
  table.insert(pieces, 1, { string.rep(" ", m) })
  return pieces
end

-- a string becomes one piece, a list is copied as-is
function M.as_pieces(line, hl)
  if type(line) == "string" then return { { line, hl } } end
  return vim.list_extend({}, line)
end

-- wrap f so errors become a warning instead of a stack trace; forwards arguments
function M.safe(f)
  return function(...)
    local ok, err = pcall(f, ...)
    if not ok then
      local msg = (tostring(err):gsub("^Vim%b():", ""))
      M.warn(msg)
    end
  end
end

function M.cmd(c)
  return M.safe(function() vim.cmd(c) end)
end

-- true when Telescope is available, without loading it if we can avoid it
function M.has_telescope()
  if package.loaded["telescope"] then return true end
  if fn.exists(":Telescope") == 2 then return true end
  local ok, cfg = pcall(require, "lazy.core.config")
  if ok and cfg.plugins and cfg.plugins["telescope.nvim"] then return true end
  return (pcall(require, "telescope"))
end

-- run a Telescope builtin picker
function M.pick(name, opts)
  return M.safe(function() require("telescope.builtin")[name](opts) end)
end

local terminals = {}

-- toggle a floating terminal running `command` (toggleterm.nvim when available,
-- a plain :terminal otherwise)
function M.float_term(command)
  return M.safe(function()
    if fn.executable(command) == 0 then error(command .. " is not executable", 0) end
    local ok, term = pcall(require, "toggleterm.terminal")
    if not ok then
      vim.cmd("terminal " .. command)
      vim.cmd("startinsert")
      return
    end
    if not terminals[command] then
      terminals[command] = term.Terminal:new({ cmd = command, direction = "float", hidden = true })
    end
    terminals[command]:toggle()
  end)
end

function M.git_branch()
  local ok, out = pcall(fn.systemlist, { "git", "rev-parse", "--abbrev-ref", "HEAD" })
  if ok and vim.v.shell_error == 0 and out[1] and out[1] ~= "" then return out[1] end
end

-- true when the current directory is inside a git work tree
function M.in_git_repo()
  return vim.fs.find(".git", { upward = true, path = fn.getcwd() })[1] ~= nil
end

function M.same_dir(a, b)
  if type(a) ~= "string" or type(b) ~= "string" then return false end
  return vim.fs.normalize(a) == vim.fs.normalize(b)
end

-- nil / false -> {}, "x" -> { "x" }, list -> list
function M.keylist(v)
  if not v then return {} end
  if type(v) == "string" then return { v } end
  return v
end

return M
