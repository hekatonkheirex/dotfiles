return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", vim.env.HOME .. "/.markdownlint-cli2.jsonc", "--" },
        },
      },
    },
  },
}
