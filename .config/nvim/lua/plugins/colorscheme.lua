local function readQuickshellColorscheme()
  local statePath = vim.fn.expand("~/.cache/quickshell/nvim-colorscheme")
  if vim.fn.filereadable(statePath) == 1 then
    local lines = vim.fn.readfile(statePath)
    local candidate = (lines[1] or ""):match("^%s*(.-)%s*$")
    if candidate == "ghost" or candidate == "ghost-light"
        or candidate == "claude" or candidate == "claude-light"
        or candidate == "nothing" or candidate == "nothing-light"
        or candidate == "matugen" or candidate == "matugen-light" then
      return candidate
    end
  end

  return "claude"
end

return {
  "LazyVim/LazyVim",
  opts = {
    colorscheme = readQuickshellColorscheme(),
  },
}
