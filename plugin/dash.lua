-- dash-nvim: defines :Dash so the dashboard can be opened (and the plugin
-- lazy-loaded) even before setup() has run. setup() adds the other commands.
if vim.g.loaded_dash then return end
vim.g.loaded_dash = 1

vim.api.nvim_create_user_command("Dash", function()
  require("dash").open()
end, { desc = "Open the Dash dashboard" })
