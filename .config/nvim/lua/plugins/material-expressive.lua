local c = {
  none               = "NONE",
  bg                 = "#12121A",
  bg_alt             = "#1C1B22",
  bg_hover           = "#2A2931",
  bg_panel           = "#16151D",
  bg_float           = "#1C1B22",
  fg                 = "#E6E1E5",
  fg_muted           = "#938F99",
  fg_faint           = "#605D64",
  primary            = "#D0BCFF",
  primary_container  = "#4F378B",
  secondary          = "#7FCFD4",
  secondary_container= "#004E59",
  tertiary           = "#FFB2CD",
  tertiary_container = "#601936",
  error              = "#F2B8B5",
  error_container    = "#8C1D18",
  warning            = "#FFE082",
  success            = "#A5D6A7",
  border             = "#35343D",
  cursorline         = "#1C1B22",
  linenr             = "#49454F",
  visual             = "#3E3B46",
  search             = "#FFB2CD",
  comment            = "#938F99",
  nontext            = "#2A2931",
}

local function hl(group, opts)
  local cmd = {}
  if opts.link then
    vim.api.nvim_set_hl(0, group, { link = opts.link, default = opts.default })
    return
  end
  if opts.fg then cmd.fg = opts.fg end
  if opts.bg then cmd.bg = opts.bg end
  if opts.sp then cmd.sp = opts.sp end
  cmd.bold = opts.bold or false
  cmd.italic = opts.italic or false
  cmd.underline = opts.underline or false
  cmd.undercurl = opts.undercurl or false
  cmd.strikethrough = opts.strikethrough or false
  cmd.reverse = opts.reverse or false
  cmd.default = opts.default or false
  vim.api.nvim_set_hl(0, group, cmd)
end

local function setup()
  vim.g.colors_name = "material-expressive"
  vim.o.background = "dark"

  -- Editor UI
  hl("Normal",          { fg = c.fg, bg = c.bg })
  hl("NormalFloat",     { fg = c.fg, bg = c.bg_float })
  hl("FloatBorder",     { fg = c.fg_faint, bg = c.bg_float })
  hl("FloatTitle",      { fg = c.primary, bg = c.bg_float, bold = true })
  hl("EndOfBuffer",     { fg = c.bg })
  hl("Cursor",          { fg = c.bg, bg = c.fg })
  hl("CursorIM",        { fg = c.bg, bg = c.fg })
  hl("CursorColumn",    { bg = c.bg_alt })
  hl("CursorLine",      { bg = c.cursorline })
  hl("CursorLineNr",    { fg = c.primary, bg = c.cursorline, bold = true })
  hl("LineNr",          { fg = c.linenr })
  hl("SignColumn",      { bg = c.bg })
  hl("ColorColumn",     { bg = c.bg_alt })
  hl("FoldColumn",      { fg = c.fg_faint, bg = c.bg })
  hl("Folded",          { fg = c.fg_muted, bg = c.bg_alt })
  hl("VertSplit",       { fg = c.border, bg = c.bg })
  hl("WinSeparator",    { fg = c.border })
  hl("WinBar",          { fg = c.fg_muted, bg = c.bg })
  hl("WinBarNC",        { fg = c.fg_faint, bg = c.bg })
  hl("StatusLine",      { fg = c.fg, bg = c.bg_alt })
  hl("StatusLineNC",    { fg = c.fg_faint, bg = c.bg })
  hl("TabLine",         { fg = c.fg_muted, bg = c.bg_alt })
  hl("TabLineFill",     { bg = c.bg })
  hl("TabLineSel",      { fg = c.bg, bg = c.primary, bold = true })
  hl("Title",           { fg = c.primary, bold = true })
  hl("MsgArea",         { fg = c.fg, bg = c.bg })
  hl("ModeMsg",         { fg = c.fg_muted })
  hl("WarningMsg",      { fg = c.warning })
  hl("ErrorMsg",        { fg = c.error })
  hl("MoreMsg",         { fg = c.secondary })
  hl("Question",        { fg = c.secondary })
  hl("Directory",       { fg = c.secondary })

  -- Visual / Selection
  hl("Visual",          { bg = c.visual })
  hl("VisualNOS",       { bg = c.visual })
  hl("Search",          { fg = c.bg, bg = c.search })
  hl("CurSearch",       { fg = c.bg, bg = c.primary })
  hl("IncSearch",       { fg = c.bg, bg = c.primary })
  hl("Substitute",      { fg = c.bg, bg = c.warning })
  hl("MatchParen",      { fg = c.primary, bold = true })

  -- Popup / Pmenu
  hl("Pmenu",           { fg = c.fg, bg = c.bg_panel })
  hl("PmenuSel",        { fg = c.fg, bg = c.bg_hover })
  hl("PmenuThumb",      { bg = c.fg_faint })
  hl("PmenuSbar",       { bg = c.border })
  hl("WildMenu",        { fg = c.bg, bg = c.primary })

  -- Diff
  hl("DiffAdd",         { bg = "#1A3D24" })
  hl("DiffChange",      { bg = "#1E2B38" })
  hl("DiffDelete",      { bg = "#4D2124" })
  hl("DiffText",        { bg = "#1C4A70" })
  hl("diffAdded",       { fg = c.success })
  hl("diffRemoved",     { fg = c.error })

  -- Spell
  hl("SpellBad",        { undercurl = true, sp = c.error })
  hl("SpellCap",        { undercurl = true, sp = c.warning })
  hl("SpellLocal",      { undercurl = true, sp = c.secondary })
  hl("SpellRare",       { undercurl = true, sp = c.tertiary })

  -- Misc UI
  hl("Conceal",         { fg = c.fg_faint })
  hl("NonText",         { fg = c.nontext })
  hl("Whitespace",      { fg = c.nontext })
  hl("SpecialKey",      { fg = c.fg_faint })
  hl("QuickFixLine",    { bg = c.visual, bold = true })
  hl("DiagnosticHint",  { fg = c.tertiary })
  hl("DiagnosticInfo",  { fg = c.secondary })
  hl("DiagnosticWarn",  { fg = c.warning })
  hl("DiagnosticError", { fg = c.error })
  hl("DiagnosticOk",    { fg = c.success })
  hl("DiagnosticUnderlineHint",  { undercurl = true, sp = c.tertiary })
  hl("DiagnosticUnderlineInfo",  { undercurl = true, sp = c.secondary })
  hl("DiagnosticUnderlineWarn",  { undercurl = true, sp = c.warning })
  hl("DiagnosticUnderlineError", { undercurl = true, sp = c.error })

  -- LSP
  hl("LspReferenceText",  { bg = c.bg_hover, bold = true })
  hl("LspReferenceRead",  { bg = c.bg_hover, bold = true })
  hl("LspReferenceWrite", { bg = c.bg_hover, bold = true })
  hl("LspInlayHint",      { fg = c.fg_faint, bg = c.bg_alt })
  hl("LspCodeLens",       { fg = c.fg_faint })
  hl("LspSignatureActiveParameter", { fg = c.tertiary, bold = true })

  -- Syntax
  hl("Comment",         { fg = c.comment, italic = true })
  hl("LineComment",     { fg = c.comment, italic = true })
  hl("SpecialComment",  { fg = c.comment, italic = true })
  hl("Todo",            { fg = c.warning, bold = true })
  hl("String",          { fg = c.success })
  hl("Character",       { fg = c.success })
  hl("Number",          { fg = c.tertiary })
  hl("Float",           { fg = c.tertiary })
  hl("Boolean",         { fg = c.tertiary })
  hl("Constant",        { fg = c.tertiary })
  hl("Identifier",      { fg = c.fg })
  hl("Function",        { fg = c.secondary })
  hl("Method",          { fg = c.secondary })
  hl("VariableName",    { fg = c.fg })
  hl("Keyword",         { fg = c.primary })
  hl("Conditional",     { fg = c.primary })
  hl("Repeat",          { fg = c.primary })
  hl("Label",           { fg = c.primary })
  hl("Operator",        { fg = c.primary })
  hl("Exception",       { fg = c.primary })
  hl("Include",         { fg = c.primary })
  hl("Define",          { fg = c.primary })
  hl("Macro",           { fg = c.primary })
  hl("PreProc",         { fg = c.primary })
  hl("PreCondit",       { fg = c.primary })
  hl("StorageClass",    { fg = c.primary })
  hl("Structure",       { fg = c.primary })
  hl("Typedef",         { fg = c.primary })
  hl("Type",            { fg = c.warning })
  hl("TypeBuiltin",     { fg = c.warning, italic = true })
  hl("Special",         { fg = c.tertiary })
  hl("SpecialChar",     { fg = c.tertiary })
  hl("Delimiter",       { fg = c.fg_muted })
  hl("Tag",             { fg = c.secondary })
  hl("Debug",           { fg = c.warning })
  hl("Ignore",          { fg = c.fg_faint })
  hl("Underlined",      { fg = c.secondary, underline = true })

  -- Treesitter
  hl("@comment",                { fg = c.comment, italic = true })
  hl("@comment.error",          { fg = c.error })
  hl("@comment.warning",        { fg = c.warning })
  hl("@comment.todo",           { fg = c.warning, bold = true })
  hl("@none",                   { fg = c.fg })
  hl("@preproc",                { fg = c.primary })
  hl("@define",                 { fg = c.primary })
  hl("@keyword",                { fg = c.primary })
  hl("@keyword.function",       { fg = c.primary })
  hl("@keyword.operator",       { fg = c.primary })
  hl("@keyword.return",         { fg = c.primary, bold = true })
  hl("@keyword.storage",        { fg = c.primary })
  hl("@keyword.repeat",         { fg = c.primary })
  hl("@keyword.exception",      { fg = c.primary })
  hl("@keyword.conditional",    { fg = c.primary })
  hl("@keyword.directive",      { fg = c.primary })
  hl("@keyword.directive.endif",{ fg = c.fg_faint })
  hl("@keyword.import",         { fg = c.primary })
  hl("@keyword.debug",          { fg = c.warning })
  hl("@punctuation.delimiter",  { fg = c.fg_muted })
  hl("@punctuation.bracket",    { fg = c.fg_muted })
  hl("@punctuation.special",    { fg = c.primary })
  hl("@string",                 { fg = c.success })
  hl("@string.regexp",          { fg = c.tertiary })
  hl("@string.escape",          { fg = c.tertiary })
  hl("@string.special",         { fg = c.tertiary })
  hl("@string.special.symbol",  { fg = c.tertiary })
  hl("@string.special.url",     { fg = c.secondary, underline = true })
  hl("@string.special.path",    { fg = c.tertiary })
  hl("@character",              { fg = c.success })
  hl("@number",                 { fg = c.tertiary })
  hl("@boolean",                { fg = c.tertiary })
  hl("@float",                  { fg = c.tertiary })
  hl("@constant",               { fg = c.tertiary })
  hl("@constant.builtin",       { fg = c.tertiary, italic = true })
  hl("@constant.macro",         { fg = c.tertiary })
  hl("@attribute",              { fg = c.tertiary })
  hl("@symbol",                 { fg = c.tertiary })
  hl("@identifier",             { fg = c.fg })
  hl("@identifier.builtin",     { fg = c.primary })
  hl("@variable",               { fg = c.fg })
  hl("@variable.builtin",       { fg = c.primary })
  hl("@variable.member",        { fg = c.fg })
  hl("@variable.parameter",     { fg = c.primary })
  hl("@variable.parameter.builtin", { fg = c.primary, italic = true })
  hl("@module",                 { fg = c.secondary })
  hl("@module.builtin",         { fg = c.secondary, italic = true })
  hl("@label",                  { fg = c.primary })
  hl("@type",                   { fg = c.warning })
  hl("@type.builtin",           { fg = c.warning, italic = true })
  hl("@type.definition",        { fg = c.warning })
  hl("@type.qualifier",         { fg = c.primary })
  hl("@property",               { fg = c.tertiary })
  hl("@function",               { fg = c.secondary })
  hl("@function.builtin",       { fg = c.primary })
  hl("@function.call",          { fg = c.secondary })
  hl("@function.macro",         { fg = c.primary })
  hl("@function.method",        { fg = c.secondary })
  hl("@function.method.call",   { fg = c.secondary })
  hl("@constructor",            { fg = c.warning })
  hl("@operator",               { fg = c.primary })
  hl("@exception",              { fg = c.primary })
  hl("@error",                  { fg = c.error })
  hl("@tag",                    { fg = c.secondary })
  hl("@tag.attribute",          { fg = c.tertiary })
  hl("@tag.delimiter",          { fg = c.fg_muted })
  hl("@text",                   { fg = c.fg })
  hl("@text.strong",            { bold = true })
  hl("@text.emphasis",          { italic = true })
  hl("@text.underline",         { underline = true })
  hl("@text.strike",            { strikethrough = true })
  hl("@text.title",             { fg = c.primary, bold = true })
  hl("@text.literal",           { fg = c.success })
  hl("@text.uri",               { fg = c.secondary, underline = true })
  hl("@text.math",              { fg = c.primary })
  hl("@text.note",              { fg = c.tertiary })
  hl("@text.warning",           { fg = c.warning })
  hl("@text.danger",            { fg = c.error })
  hl("@text.diff.add",          { fg = c.success })
  hl("@text.diff.delete",       { fg = c.error })
  hl("@diff.plus",              { fg = c.success })
  hl("@diff.minus",             { fg = c.error })
  hl("@diff.delta",             { fg = c.warning })

  -- Markdown
  hl("@markup.heading",           { fg = c.primary, bold = true })
  hl("@markup.raw",               { fg = c.success })
  hl("@markup.link",              { fg = c.secondary, underline = true })
  hl("@markup.link.url",          { fg = c.secondary, underline = true })
  hl("@markup.link.label",        { fg = c.tertiary })
  hl("@markup.list",              { fg = c.primary })
  hl("@markup.list.checked",      { fg = c.success })
  hl("@markup.list.unchecked",    { fg = c.fg_muted })
  hl("@markup.quote",             { fg = c.fg_muted, italic = true })
  hl("@markup.raw.markdown_inline", { fg = c.success })
  hl("@markup.strikethrough",     { strikethrough = true })

  -- NvimTree
  hl("NvimTreeNormal",           { fg = c.fg, bg = c.bg })
  hl("NvimTreeNormalNC",         { fg = c.fg, bg = c.bg })
  hl("NvimTreeWinSeparator",     { fg = c.border, bg = c.border })
  hl("NvimTreeFolderName",       { fg = c.secondary })
  hl("NvimTreeFolderIcon",       { fg = c.secondary })
  hl("NvimTreeOpenedFolderName", { fg = c.secondary, bold = true })
  hl("NvimTreeEmptyFolderName",  { fg = c.fg_muted })
  hl("NvimTreeGitDirty",         { fg = c.warning })
  hl("NvimTreeGitNew",           { fg = c.success })
  hl("NvimTreeGitDeleted",       { fg = c.error })
  hl("NvimTreeGitStaged",        { fg = c.secondary })
  hl("NvimTreeGitMerge",         { fg = c.primary })
  hl("NvimTreeGitIgnored",       { fg = c.fg_faint, italic = true })
  hl("NvimTreeRootFolder",       { fg = c.fg_muted, bold = true })
  hl("NvimTreeSpecialFile",      { fg = c.primary })
  hl("NvimTreeImageFile",        { fg = c.tertiary })
  hl("NvimTreeOpenedFile",       { fg = c.primary })
  hl("NvimTreeIndentMarker",     { fg = c.nontext })
  hl("NvimTreeSymlink",          { fg = c.tertiary })

  -- Telescope
  hl("TelescopeNormal",          { fg = c.fg, bg = c.bg_panel })
  hl("TelescopeBorder",          { fg = c.border, bg = c.bg_panel })
  hl("TelescopePromptNormal",    { fg = c.fg, bg = c.bg_hover })
  hl("TelescopePromptBorder",    { fg = c.primary, bg = c.bg_hover })
  hl("TelescopePromptTitle",     { fg = c.bg, bg = c.primary, bold = true })
  hl("TelescopePreviewTitle",    { fg = c.bg, bg = c.success, bold = true })
  hl("TelescopeResultsTitle",    { fg = c.bg, bg = c.bg_panel })
  hl("TelescopeSelection",       { bg = c.visual })
  hl("TelescopeSelectionCaret",  { fg = c.primary })
  hl("TelescokeMultiSelection",  { fg = c.success })
  hl("TelescopeMatching",        { fg = c.primary, bold = true })
  hl("TelescopeResultsDiffAdd",  { fg = c.success })
  hl("TelescopeResultsDiffChange", { fg = c.warning })
  hl("TelescopeResultsDiffDelete", { fg = c.error })

  -- Bufferline
  hl("BufferLineTabClose",       { fg = c.fg_faint })
  hl("BufferLineTabSelected",    { fg = c.fg, bold = true })
  hl("BufferLineTabSeparator",   { fg = c.border })
  hl("BufferLineDuplicate",      { fg = c.fg_faint, italic = true })
  hl("BufferLineModified",       { fg = c.warning })
  hl("BufferLineModifiedSelected", { fg = c.warning, bold = true })
  hl("BufferLineModifiedVisible", { fg = c.warning })
  hl("BufferLinePick",           { fg = c.secondary })
  hl("BufferLinePickSelected",   { fg = c.secondary, bold = true })
  hl("BufferLineBackground",     { fg = c.fg_muted, bg = c.bg })
  hl("BufferLineBufferVisible",  { fg = c.fg, bg = c.bg_alt })
  hl("BufferLineBufferSelected", { fg = c.fg, bg = c.bg_hover, bold = true })
  hl("BufferLineIndicatorSelected", { fg = c.primary, bg = c.bg_hover })
  hl("BufferLineOffsetSeparator", { fg = c.border, bg = c.bg })
  hl("BufferLineSeparator",      { fg = c.border, bg = c.bg })
  hl("BufferLineSeparatorSelected", { fg = c.border, bg = c.bg_hover })
  hl("BufferLineSeparatorVisible", { fg = c.border, bg = c.bg_alt })
  hl("BufferLineCloseButton",    { fg = c.fg_faint })
  hl("BufferLineCloseButtonSelected", { fg = c.error })
  hl("BufferLineCloseButtonVisible", { fg = c.fg_muted })
  hl("BufferLineError",          { fg = c.error })
  hl("BufferLineErrorSelected",  { fg = c.error, bold = true })
  hl("BufferLineWarning",        { fg = c.warning })
  hl("BufferLineWarningSelected",{ fg = c.warning, bold = true })
  hl("BufferLineInfo",           { fg = c.secondary })
  hl("BufferLineInfoSelected",   { fg = c.secondary, bold = true })
  hl("BufferLineHint",           { fg = c.tertiary })
  hl("BufferLineHintSelected",   { fg = c.tertiary, bold = true })
  hl("BufferLineVisible",        { fg = c.fg_muted, bg = c.bg_alt })
  hl("BufferLineGroupNormal",    { fg = c.fg_muted })
  hl("BufferLineGroupNormalNC",  { fg = c.fg_faint })
  hl("BufferLineNumbers",        { fg = c.fg_faint })
  hl("BufferLineNumbersSelected",{ fg = c.fg_muted })

  -- WhichKey
  hl("WhichKey",                { fg = c.primary, bold = true })
  hl("WhichKeyGroup",           { fg = c.secondary })
  hl("WhichKeyDesc",            { fg = c.fg })
  hl("WhichKeySeperator",       { fg = c.fg_muted })
  hl("WhichKeyFloat",           { bg = c.bg_panel })
  hl("WhichKeyValue",           { fg = c.fg_muted })

  -- Noice
  hl("NoiceCmdlinePopupTitle",  { fg = c.primary, bold = true })
  hl("NoiceCmdlinePopupBorder", { fg = c.primary })
  hl("NoiceCmdlineIcon",        { fg = c.tertiary })
  hl("NoiceMini",               { fg = c.fg_muted, bg = c.bg_panel })
  hl("NoiceCompletionItemKindDefault", { fg = c.fg_muted })
  hl("NoiceCompletionItemKindKeyword", { fg = c.primary })
  hl("NoiceCompletionItemKindVariable", { fg = c.fg })
  hl("NoiceCompletionItemKindConstant", { fg = c.tertiary })
  hl("NoiceCompletionItemKindFunction", { fg = c.secondary })
  hl("NoiceCompletionItemKindMethod",   { fg = c.secondary })
  hl("NoiceCompletionItemKindClass",    { fg = c.warning })
  hl("NoiceCompletionItemKindType",     { fg = c.warning })
  hl("NoiceCompletionItemKindStruct",   { fg = c.warning })
  hl("NoiceCompletionItemKindModule",   { fg = c.secondary })
  hl("NoiceCompletionItemKindProperty", { fg = c.tertiary })
  hl("NoiceCompletionItemKindField",    { fg = c.tertiary })
  hl("NoiceCompletionItemKindEnum",     { fg = c.warning })
  hl("NoiceCompletionItemKindInterface",{ fg = c.warning })
  hl("NoiceCompletionItemKindSnippet",  { fg = c.primary })
  hl("NoiceCompletionItemKindColor",    { fg = c.primary })

  -- Flash
  hl("FlashLabel",              { fg = c.bg, bg = c.primary, bold = true })
  hl("FlashBackdrop",           { fg = c.fg_faint })
  hl("FlashMatch",              { fg = c.bg, bg = c.warning, bold = true })
  hl("FlashCurrent",            { fg = c.bg, bg = c.secondary, bold = true })

  -- Mini
  hl("MiniCursorword",         { underline = true, sp = c.fg_faint })
  hl("MiniCursorwordCurrent",  { underline = true, sp = c.primary })
  hl("MiniTrailspace",         { bg = c.error })
  hl("MiniIndentscopeSymbol",  { fg = c.border })
  hl("MiniJump",               { fg = c.primary, bold = true })
  hl("MiniStarterCurrent",     { fg = c.fg })

  -- Indent Blankline / Ibl
  hl("IblIndent",              { fg = c.nontext })
  hl("IblWhitespace",          { fg = c.nontext })
  hl("IblScope",               { fg = c.fg_faint })

  -- Gitsigns
  hl("GitSignsAdd",            { fg = c.success })
  hl("GitSignsChange",         { fg = c.warning })
  hl("GitSignsDelete",         { fg = c.error })
  hl("GitSignsAddLn",          { bg = "#1A3D24" })
  hl("GitSignsChangeLn",       { bg = "#1E2B38" })
  hl("GitSignsDeleteLn",       { bg = "#4D2124" })
  hl("GitSignsAddNr",          { fg = c.success })
  hl("GitSignsChangeNr",       { fg = c.warning })
  hl("GitSignsDeleteNr",       { fg = c.error })

  -- Snacks
  hl("SnacksNormal",           { fg = c.fg, bg = c.bg_panel })
  hl("SnacksBorder",           { fg = c.border, bg = c.bg_panel })
  hl("SnacksBackdrop",         { bg = "#000000" })
  hl("SnacksIndent",           { fg = c.nontext })
  hl("SnacksScope",            { fg = c.fg_faint })
  hl("SnacksPickerMatch",      { fg = c.primary, bold = true })
  hl("SnacksPickerSelected",   { bg = c.visual })
  hl("SnacksPickerTitle",      { fg = c.bg, bg = c.primary, bold = true })

  -- Blink / Completions
  hl("BlinkCmpMenu",           { fg = c.fg, bg = c.bg_panel })
  hl("BlinkCmpMenuBorder",     { fg = c.border, bg = c.bg_panel })
  hl("BlinkCmpSel",            { bg = c.bg_hover, bold = true })
  hl("BlinkCmpScrollBarThumb", { bg = c.fg_faint })
  hl("BlinkCmpScrollBarTrack", { bg = c.border })
  hl("BlinkCmpGhostText",      { fg = c.fg_faint, italic = true })
  hl("BlinkCmpLabel",          { fg = c.fg })
  hl("BlinkCmpLabelMatch",     { fg = c.primary, bold = true })
  hl("BlinkCmpLabelDeprecated",{ fg = c.fg_faint, strikethrough = true })
  hl("BlinkCmpKindKeyword",    { fg = c.primary })
  hl("BlinkCmpKindVariable",   { fg = c.fg })
  hl("BlinkCmpKindConstant",   { fg = c.tertiary })
  hl("BlinkCmpKindFunction",   { fg = c.secondary })
  hl("BlinkCmpKindMethod",     { fg = c.secondary })
  hl("BlinkCmpKindClass",      { fg = c.warning })
  hl("BlinkCmpKindType",       { fg = c.warning })
  hl("BlinkCmpKindStruct",     { fg = c.warning })
  hl("BlinkCmpKindModule",     { fg = c.secondary })
  hl("BlinkCmpKindProperty",   { fg = c.tertiary })
  hl("BlinkCmpKindField",      { fg = c.tertiary })
  hl("BlinkCmpKindEnum",       { fg = c.warning })
  hl("BlinkCmpKindInterface",  { fg = c.warning })
  hl("BlinkCmpKindSnippet",    { fg = c.primary })
  hl("BlinkCmpKindColor",      { fg = c.primary })
  hl("BlinkCmpKindFile",       { fg = c.fg })
  hl("BlinkCmpKindReference",  { fg = c.success })
  hl("BlinkCmpKindFolder",     { fg = c.secondary })
  hl("BlinkCmpKindUnit",       { fg = c.fg_muted })
  hl("BlinkCmpKindValue",      { fg = c.tertiary })

  -- Lualine theme
  vim.api.nvim_set_hl(0, "LualineNormal",  { fg = c.fg_faint, bg = c.bg_alt })
  vim.api.nvim_set_hl(0, "LualineInsert",  { fg = c.bg, bg = c.primary })
  vim.api.nvim_set_hl(0, "LualineVisual",  { fg = c.bg, bg = c.tertiary })
  vim.api.nvim_set_hl(0, "LualineCommand", { fg = c.bg, bg = c.secondary })
  vim.api.nvim_set_hl(0, "LualineReplace", { fg = c.bg, bg = c.warning })
  vim.api.nvim_set_hl(0, "LualineTerminal",{ fg = c.bg, bg = c.success })
  vim.api.nvim_set_hl(0, "LualineInactive",{ fg = c.fg_faint, bg = c.bg })

  -- FzfLua
  hl("FzfLuaNormal",           { fg = c.fg, bg = c.bg_panel })
  hl("FzfLuaBorder",           { fg = c.border, bg = c.bg_panel })
  hl("FzfLuaTitle",            { fg = c.primary, bg = c.bg_panel, bold = true })
  hl("FzfLuaCursor",           { fg = c.bg, bg = c.primary })
  hl("FzfLuaSearch",           { fg = c.fg, bg = c.bg_hover })
  hl("FzfLuaSearchCnt",        { fg = c.fg_faint })

  -- Notify
  hl("NotifyINFOBorder",       { fg = c.secondary })
  hl("NotifyINFOTitle",        { fg = c.secondary })
  hl("NotifyINFOIcon",         { fg = c.secondary })
  hl("NotifyWARNBorder",       { fg = c.warning })
  hl("NotifyWARNTitle",        { fg = c.warning })
  hl("NotifyWARNIcon",         { fg = c.warning })
  hl("NotifyERRORBorder",      { fg = c.error })
  hl("NotifyERRORTitle",       { fg = c.error })
  hl("NotifyERRORIcon",        { fg = c.error })
  hl("NotifyDEBUGBorder",      { fg = c.fg_faint })
  hl("NotifyDEBUGTitle",       { fg = c.fg_faint })
  hl("NotifyDEBUGIcon",        { fg = c.fg_faint })
  hl("NotifyTRACEBorder",      { fg = c.primary })
  hl("NotifyTRACETitle",       { fg = c.primary })
  hl("NotifyTRACEIcon",        { fg = c.primary })
  hl("NotifyINFOBody",         { fg = c.fg, bg = c.bg_panel })
  hl("NotifyWARNBody",         { fg = c.fg, bg = c.bg_panel })
  hl("NotifyERRORBody",        { fg = c.fg, bg = c.bg_panel })
  hl("NotifyDEBUGBody",        { fg = c.fg, bg = c.bg_panel })
  hl("NotifyTRACEBody",        { fg = c.fg, bg = c.bg_panel })
end

-- Expose setup globally so lazy.nvim spec validation doesn't see it on the spec table
_G.material_expressive_setup = setup

local cache_dir = vim.fn.stdpath("cache") .. "/material-expressive"
local colors_dir = cache_dir .. "/colors"
vim.fn.mkdir(colors_dir, "p")
local f = io.open(colors_dir .. "/material-expressive.lua", "w")
if f then
  f:write([[
vim.g.colors_name = "material-expressive"
if _G.material_expressive_setup then
  _G.material_expressive_setup()
else
  require("plugins.material-expressive")
  if _G.material_expressive_setup then
    _G.material_expressive_setup()
  end
end
]])
  f:close()
end
vim.opt.rtp:append(cache_dir)

local spec = {
  {
    "material-expressive",
    dir = vim.fn.stdpath("config"),
    lazy = true,
    priority = 1000,
  }
}

return spec
