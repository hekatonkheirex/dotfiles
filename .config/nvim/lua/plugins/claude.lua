return {
  "hekatonkheirex/claude-nvim",
  lazy = false,
  opts = {
    flavour = "auto", -- "dark" | "light" | "auto"
    transparent = false,
    term_colors = false,
    styles = {
      comments = { "italic" },
      conditionals = { "italic" },
      -- add any other style overrides you like
    },
    -- highlight_overrides = { ... }, -- optional
  },
  config = function(_, opts)
    require("claude").setup(opts)
  end,
}
