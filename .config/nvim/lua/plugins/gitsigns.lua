return {
  {
    "lewis6991/gitsigns.nvim",
    dependencies = {
      "purarue/gitsigns-yadm.nvim",
      "nvim-lua/plenary.nvim",
    },
    opts = {
      _on_attach_pre = function(bufnr, callback)
        require("gitsigns-yadm").yadm_signs(callback, { bufnr = bufnr })
      end,
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signs_staged = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
    },
  },
}