return {
  "hekatonkheirex/nothing-nvim",
  lazy = false,
  opts = {
    transparent = false,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
    },
    -- overrides = { Normal = { bg = "#000000" } }, -- optional
  },
  config = function(_, opts)
    require("nothing").setup(opts)
  end,
}
