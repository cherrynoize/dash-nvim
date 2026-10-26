-- examples/lazy.lua
-- lazy.nvim plugin spec: save as ~/.config/nvim/lua/plugins/dash-nvim.lua

return {
  "cherrynoize/dash-nvim",
  url = "git@github.com:cherrynoize/dash-nvim.git", -- clone over SSH

  -- load at startup so the dashboard can open on an empty start
  lazy = false,
  priority = 100,

  dependencies = {
    "nvim-telescope/telescope.nvim",        -- pickers behind most items
    "nvim-tree/nvim-web-devicons",          -- file icons in Recent files
    {
      "DrKJeff16/project.nvim",             -- source of the Projects panel (Neovim 0.11+)
      lazy = false,
      opts = {},
      config = function(_, opts)
        require("project").setup(opts)
        pcall(require("telescope").load_extension, "projects")
      end,
    },
  },

  -- the original dashboard: copy examples/config.lua to
  -- ~/.config/nvim/lua/dash_config.lua, or inline the table here
  opts = function()
    return require("dash_config")
  end,
}
