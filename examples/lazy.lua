-- examples/lazy.lua
-- returns a lazy.nvim plugin spec table

return {
  "cherrynoize/dash-nvim",

  lazy = false,
  priority = 100,

  dependencies = {
    "nvim-telescope/telescope.nvim",    -- pickers
    "nvim-tree/nvim-web-devicons",      -- file icons in Recent files
    {
      "DrKJeff16/project.nvim",         -- Projects panel
      lazy = false,
      opts = {},
      config = function(_, opts)
        require("project").setup(opts)
        pcall(require("telescope").load_extension, "projects")
      end,
    },
  },

  -- opts = {},
}
