 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1a1b26',
    base01 = '#24283b',
    base02 = '#2c3148',
    base03 = '#5d6682',
    base04 = '#9aa5ce',
    base05 = '#c0caf5',
    base06 = '#c0caf5',
    base07 = '#c0caf5',
    base08 = '#f7768e',
    base09 = '#9ece6a',
    base0A = '#bb9af7',
    base0B = '#7aa2f7',
    base0C = '#c1e996',
    base0D = '#87abf8',
    base0E = '#af89f6',
    base0F = '#cfb8f9',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#c0caf5',          bg = '#1a1b26' })
  hi('TelescopeBorder',         { fg = '#5d6682',             bg = '#1a1b26' })
  hi('TelescopePromptNormal',   { fg = '#c0caf5',          bg = '#1a1b26' })
  hi('TelescopePromptBorder',   { fg = '#5d6682',             bg = '#1a1b26' })
  hi('TelescopePromptPrefix',   { fg = '#7aa2f7',             bg = '#1a1b26' })
  hi('TelescopePromptCounter',  { fg = '#9aa5ce',  bg = '#1a1b26' })
  hi('TelescopePromptTitle',    { fg = '#1a1b26',             bg = '#7aa2f7' })
  hi('TelescopePreviewTitle',   { fg = '#1a1b26',             bg = '#bb9af7' })
  hi('TelescopeResultsTitle',   { fg = '#1a1b26',             bg = '#9ece6a' })
  hi('TelescopeSelection',      { fg = '#c0caf5',          bg = '#2c3148' })
  hi('TelescopeSelectionCaret', { fg = '#7aa2f7',             bg = '#2c3148' })
  hi('TelescopeMatching',       { fg = '#7aa2f7',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
