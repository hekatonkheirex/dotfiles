return {
  dir = vim.fn.stdpath("config") .. "/lua/tahoe-dark",
  lazy = false,
  priority = 1000,
  config = function()
    require("tahoe-dark").setup()
    vim.cmd.colorscheme("tahoe-dark")
  end,
}
