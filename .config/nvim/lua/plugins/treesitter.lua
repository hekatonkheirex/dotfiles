return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = { "tree-sitter-grammars/tree-sitter-hyprlang" },
  opts = function(_, opts)
    vim.list_extend(opts.ensure_installed, {
      "html",
      "javascript",
      "lua",
      "python",
      "hyprlang",
    })
  end,
}