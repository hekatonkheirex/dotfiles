-- Wallpaper-derived Neovim colorscheme, sourced live from Matugen's cache.
-- Used by Material 3 (when its terminal colorscheme is "matugen") and
-- always by Neo Brutalism. Mirrors claude-nvim's highlight group set so
-- switching between the two feels consistent; only the palette differs.
local M = {}

local CACHE_PATH = vim.fn.expand("~/.cache/matugen/current_palette.json")

-- Neutral fallback for first boot / before any wallpaper has been applied.
local FALLBACK = {
  dark = {
    background = "#121212", surface_dim = "#000000",
    surface_container = "#1f1f1f", surface_container_high = "#292929",
    surface_container_highest = "#333333",
    on_background = "#ededed", on_surface_variant = "#bfbfbf",
    outline = "#8f8a8a", outline_variant = "#4c4c4c",
    primary = "#df8d72", primary_fixed_dim = "#df8d72",
    secondary = "#b5a29b", secondary_fixed_dim = "#b5a29b",
    tertiary = "#7fade6", tertiary_fixed_dim = "#7fade6",
    error = "#d47c92",
  },
  light = {
    background = "#fff8f8", surface_dim = "#e0d8d9",
    surface_container = "#f5eced", surface_container_high = "#efe6e7",
    surface_container_highest = "#e9e0e1",
    on_background = "#1e1b1c", on_surface_variant = "#4f4447",
    outline = "#817477", outline_variant = "#d3c2c6",
    primary = "#76525f", primary_fixed_dim = "#e9bac9",
    secondary = "#6c595f", secondary_fixed_dim = "#d8c0c7",
    tertiary = "#4d6147", tertiary_fixed_dim = "#b6cdad",
    error = "#ba1a1a",
  },
}

local function read_roles(mode)
  local ok, lines = pcall(vim.fn.readfile, CACHE_PATH)
  if not ok or not lines or #lines == 0 then
    return FALLBACK[mode]
  end
  local decode_ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decode_ok or not data or not data["scheme-expressive"] or not data["scheme-expressive"][mode] then
    return FALLBACK[mode]
  end
  return vim.tbl_deep_extend("force", FALLBACK[mode], data["scheme-expressive"][mode])
end

-- role -> our internal palette name, following the ANSI mapping already
-- established in kitty's matugen-*.conf: red=error green=tertiary
-- yellow=primary blue=secondary (M3 has no native red/green/blue roles).
local function build_colors(mode)
  local r = read_roles(mode)
  return {
    bg = r.background,
    bgDim = r.surface_dim,
    bgContainer = r.surface_container,
    bgContainerHigh = r.surface_container_high,
    bgContainerHighest = r.surface_container_highest,

    fg = r.on_background,
    fgMuted = r.on_surface_variant,

    outline = r.outline,
    outlineVariant = r.outline_variant,

    primary = r.primary,
    primaryBright = r.primary_fixed_dim,

    secondary = r.secondary, -- "blue"
    secondaryBright = r.secondary_fixed_dim,

    tertiary = r.tertiary, -- "green"
    tertiaryBright = r.tertiary_fixed_dim,

    red = r.error,
  }
end

local function build_highlights(c)
  return {
    Normal       = { fg = c.fg,     bg = c.bg },
    CursorLine   = { bg = c.bgContainer },
    CursorLineNr = { fg = c.primary, bold = true },
    Visual       = { bg = c.bgContainerHigh },
    Search       = { bg = c.bgContainerHigh, fg = c.fg },
    IncSearch    = { bg = c.primary, fg = c.bg },
    LineNr       = { fg = c.outline },
    SignColumn   = { bg = c.bg },
    VertSplit    = { fg = c.outlineVariant },
    WinSeparator = { fg = c.outlineVariant },
    StatusLine   = { fg = c.fg,     bg = c.bgContainerHigh, bold = true },
    StatusLineNC = { fg = c.outline, bg = c.bgContainer },
    TermCursor   = { bg = c.fg,     fg = c.bg },
    Title        = { fg = c.tertiary, bold = true },
    WarningMsg   = { fg = c.primary },
    ErrorMsg     = { fg = c.red },

    Statement    = { fg = c.primary },
    Conditional  = { fg = c.primary },
    Repeat       = { fg = c.primary },
    Label        = { fg = c.primary },
    Operator     = { fg = c.fg },
    Keyword      = { fg = c.primary },
    Exception    = { fg = c.primary },
    PreProc      = { fg = c.secondary },
    Include      = { fg = c.secondary },
    Define       = { fg = c.secondary },
    Macro        = { fg = c.secondary },
    PreCondit    = { fg = c.secondary },
    Constant     = { fg = c.primaryBright },
    String       = { fg = c.tertiary },
    Character    = { fg = c.tertiary },
    Number       = { fg = c.primaryBright },
    Boolean      = { fg = c.primaryBright },
    Float        = { fg = c.primaryBright },
    Identifier   = { fg = c.fg },
    Function     = { fg = c.secondary },
    Underlined   = { fg = c.secondary, underline = true },
    Todo         = { bg = c.primary, fg = c.bg, bold = true },
    Comment      = { fg = c.outline, italic = true },
    Type         = { fg = c.secondaryBright },
    StorageClass = { fg = c.secondaryBright },
    Structure    = { fg = c.secondaryBright },
    Typedef      = { fg = c.secondaryBright },
    Special      = { fg = c.primary },
    SpecialChar  = { fg = c.primary },
    Tag          = { fg = c.primary },
    Delimiter    = { fg = c.outline },
    SpecialComment = { fg = c.outlineVariant, italic = true },
    Debug        = { fg = c.primary },

    DiagnosticError = { fg = c.red },
    DiagnosticWarn  = { fg = c.primary },
    DiagnosticInfo  = { fg = c.secondary },
    DiagnosticHint  = { fg = c.fgMuted },
    DiagnosticOk    = { fg = c.tertiary },

    ["@variable"]              = { fg = c.fg },
    ["@variable.builtin"]      = { fg = c.primary },
    ["@parameter"]             = { fg = c.fg },
    ["@function"]              = { fg = c.secondary },
    ["@function.builtin"]      = { fg = c.primary },
    ["@function.call"]         = { fg = c.secondary },
    ["@method"]                = { fg = c.secondary },
    ["@method.call"]           = { fg = c.secondary },
    ["@constructor"]           = { fg = c.secondaryBright },
    ["@constant"]              = { fg = c.primaryBright },
    ["@constant.builtin"]      = { fg = c.primaryBright },
    ["@constant.macro"]        = { fg = c.primaryBright },
    ["@module"]                = { fg = c.fg },
    ["@label"]                 = { fg = c.primary },
    ["@attribute"]             = { fg = c.secondaryBright },
    ["@property"]              = { fg = c.fg },
    ["@punctuation.delimiter"] = { fg = c.outline },
    ["@punctuation.bracket"]   = { fg = c.outline },
    ["@punctuation.special"]   = { fg = c.primary },
    ["@string"]                = { fg = c.tertiary },
    ["@string.regexp"]         = { fg = c.primary },
    ["@string.escape"]         = { fg = c.primary },
    ["@character"]             = { fg = c.tertiary },
    ["@boolean"]               = { fg = c.primaryBright },
    ["@number"]                = { fg = c.primaryBright },
    ["@float"]                 = { fg = c.primaryBright },
    ["@type"]                  = { fg = c.secondaryBright },
    ["@type.builtin"]          = { fg = c.secondaryBright },
    ["@variable.member"]       = { fg = c.fg },
    ["@variable.parameter"]    = { fg = c.fg },
    ["@conditional"]           = { fg = c.primary },
    ["@repeat"]                = { fg = c.primary },
    ["@operator"]              = { fg = c.fg },
    ["@keyword"]               = { fg = c.primary },
    ["@keyword.function"]      = { fg = c.primary },
    ["@keyword.operator"]      = { fg = c.primary },
    ["@keyword.return"]        = { fg = c.primary },
    ["@punctuation"]           = { fg = c.outline },
    ["@comment"]               = { fg = c.outline, italic = true },
    ["@comment.todo"]          = { bg = c.primary, fg = c.bg, bold = true },
    ["@comment.error"]         = { fg = c.red },
    ["@comment.warning"]       = { fg = c.primary },
    ["@comment.hint"]          = { fg = c.secondary },
    ["@comment.info"]          = { fg = c.secondary },

    DiffAdd    = { fg = c.tertiary, bg = c.bg },
    DiffChange = { fg = c.primary,  bg = c.bg },
    DiffDelete = { fg = c.red,      bg = c.bg },
    DiffText   = { fg = c.secondary, bg = c.bgContainer },
    GitSignsAdd    = { fg = c.tertiary },
    GitSignsChange = { fg = c.primary },
    GitSignsDelete = { fg = c.red },

    Pmenu       = { fg = c.fg, bg = c.bgContainer },
    PmenuSel    = { fg = c.bg, bg = c.primary },
    PmenuSbar   = { bg = c.bgContainerHigh },
    PmenuThumb  = { bg = c.outline },
    NormalFloat = { fg = c.fg, bg = c.bgContainer },
    FloatBorder = { fg = c.outline, bg = c.bgContainer },

    TelescopeNormal = { fg = c.fg, bg = c.bgContainer },
    TelescopeBorder = { fg = c.outline, bg = c.bgContainer },
    NvimTreeNormal  = { fg = c.fgMuted, bg = c.bgDim },
    NeoTreeNormal   = { fg = c.fgMuted, bg = c.bgDim },
  }
end

--- @param mode "dark"|"light"
function M.load(mode)
  mode = mode == "light" and "light" or "dark"
  if vim.g.colors_name then
    vim.cmd.hi("clear")
  end
  vim.o.termguicolors = true
  vim.o.background = mode
  vim.g.colors_name = mode == "light" and "matugen-light" or "matugen"

  local c = build_colors(mode)
  for group, spec in pairs(build_highlights(c)) do
    vim.api.nvim_set_hl(0, group, spec)
  end
end

return M
