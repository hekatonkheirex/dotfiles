local M = {}

local c = {
  none       = "NONE",
  bg         = "#0D1117",
  bg_alt     = "#161B22",
  bg_hover   = "#1C2333",
  bg_panel   = "#131820",
  bg_float   = "#0D1117",
  fg         = "#C9D1D9",
  fg_muted   = "#8B949E",
  fg_faint   = "#484F58",
  pink       = "#FF6489",
  blue       = "#0088FF",
  cyan       = "#048ABF",
  dark_blue  = "#0455BF",
  red        = "#ED5F5D",
  orange     = "#E9873A",
  yellow     = "#D29922",
  green      = "#79B757",
  purple     = "#BC8CFF",
  border     = "#21262D",
  cursorline = "#161B22",
  linenr     = "#484F58",
  visual     = "#253550",
  search     = "#0088FF",

  comment    = "#484F58",
  nontext    = "#21262D",
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

function M.setup()
  vim.g.colors_name = "tahoe-dark"
  vim.o.background = "dark"

  -- Editor UI
  hl("Normal",          { fg = c.fg, bg = c.bg })
  hl("NormalFloat",     { fg = c.fg, bg = c.bg_float })
  hl("FloatBorder",     { fg = c.fg_faint, bg = c.bg_float })
  hl("FloatTitle",      { fg = c.blue, bg = c.bg_float, bold = true })
  hl("EndOfBuffer",     { fg = c.bg })
  hl("Cursor",          { fg = c.bg, bg = c.fg })
  hl("CursorIM",        { fg = c.bg, bg = c.fg })
  hl("CursorColumn",    { bg = c.bg_alt })
  hl("CursorLine",      { bg = c.cursorline })
  hl("CursorLineNr",    { fg = c.fg_muted, bg = c.cursorline })
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
  hl("TabLineSel",      { fg = c.bg, bg = c.blue, bold = true })
  hl("Title",           { fg = c.blue, bold = true })
  hl("MsgArea",         { fg = c.fg, bg = c.bg })
  hl("ModeMsg",         { fg = c.fg_muted })
  hl("WarningMsg",      { fg = c.orange })
  hl("ErrorMsg",        { fg = c.red })
  hl("MoreMsg",         { fg = c.blue })
  hl("Question",        { fg = c.blue })
  hl("Directory",       { fg = c.blue })

  -- Visual / Selection
  hl("Visual",          { bg = c.visual })
  hl("VisualNOS",       { bg = c.visual })
  hl("Search",          { fg = c.bg, bg = c.search })
  hl("CurSearch",       { fg = c.bg, bg = c.pink })
  hl("IncSearch",       { fg = c.bg, bg = c.pink })
  hl("Substitute",      { fg = c.bg, bg = c.orange })
  hl("MatchParen",      { fg = c.pink, bold = true })

  -- Popup / Pmenu
  hl("Pmenu",           { fg = c.fg, bg = c.bg_panel })
  hl("PmenuSel",        { fg = c.fg, bg = c.bg_hover })
  hl("PmenuThumb",      { bg = c.fg_faint })
  hl("PmenuSbar",       { bg = c.border })
  hl("WildMenu",        { fg = c.bg, bg = c.blue })

  -- Diff
  hl("DiffAdd",         { bg = "#1C3A1F" })
  hl("DiffChange",      { bg = "#1C2833" })
  hl("DiffDelete",      { bg = "#3A1C1C" })
  hl("DiffText",        { bg = "#1C3A5F" })
  hl("diffAdded",       { fg = c.green })
  hl("diffRemoved",     { fg = c.red })

  -- Spell
  hl("SpellBad",        { undercurl = true, sp = c.red })
  hl("SpellCap",        { undercurl = true, sp = c.orange })
  hl("SpellLocal",      { undercurl = true, sp = c.blue })
  hl("SpellRare",       { undercurl = true, sp = c.purple })

  -- Misc UI
  hl("Conceal",         { fg = c.fg_faint })
  hl("NonText",         { fg = c.nontext })
  hl("Whitespace",      { fg = c.nontext })
  hl("SpecialKey",      { fg = c.fg_faint })
  hl("QuickFixLine",    { bg = c.visual, bold = true })
  hl("DiagnosticHint",  { fg = c.cyan })
  hl("DiagnosticInfo",  { fg = c.blue })
  hl("DiagnosticWarn",  { fg = c.orange })
  hl("DiagnosticError", { fg = c.red })
  hl("DiagnosticOk",    { fg = c.green })
  hl("DiagnosticUnderlineHint",  { undercurl = true, sp = c.cyan })
  hl("DiagnosticUnderlineInfo",  { undercurl = true, sp = c.blue })
  hl("DiagnosticUnderlineWarn",  { undercurl = true, sp = c.orange })
  hl("DiagnosticUnderlineError", { undercurl = true, sp = c.red })

  -- LSP
  hl("LspReferenceText",  { bg = c.bg_hover, bold = true })
  hl("LspReferenceRead",  { bg = c.bg_hover, bold = true })
  hl("LspReferenceWrite", { bg = c.bg_hover, bold = true })
  hl("LspInlayHint",      { fg = c.fg_faint, bg = c.bg_alt })
  hl("LspCodeLens",       { fg = c.fg_faint })
  hl("LspSignatureActiveParameter", { fg = c.pink, bold = true })

  -- Syntax
  hl("Comment",         { fg = c.comment, italic = true })
  hl("LineComment",     { fg = c.comment, italic = true })
  hl("SpecialComment",  { fg = c.comment, italic = true })
  hl("Todo",            { fg = c.orange, bold = true })
  hl("String",          { fg = c.green })
  hl("Character",       { fg = c.green })
  hl("Number",          { fg = c.orange })
  hl("Float",           { fg = c.orange })
  hl("Boolean",         { fg = c.orange })
  hl("Constant",        { fg = c.orange })
  hl("Identifier",      { fg = c.fg })
  hl("Function",        { fg = c.blue })
  hl("Method",          { fg = c.blue })
  hl("VariableName",    { fg = c.fg })
  hl("Keyword",         { fg = c.pink })
  hl("Conditional",     { fg = c.pink })
  hl("Repeat",          { fg = c.pink })
  hl("Label",           { fg = c.pink })
  hl("Operator",        { fg = c.purple })
  hl("Exception",       { fg = c.pink })
  hl("Include",         { fg = c.pink })
  hl("Define",          { fg = c.pink })
  hl("Macro",           { fg = c.pink })
  hl("PreProc",         { fg = c.pink })
  hl("PreCondit",       { fg = c.pink })
  hl("StorageClass",    { fg = c.pink })
  hl("Structure",       { fg = c.pink })
  hl("Typedef",         { fg = c.pink })
  hl("Type",            { fg = c.yellow })
  hl("TypeBuiltin",     { fg = c.yellow, italic = true })
  hl("Special",         { fg = c.cyan })
  hl("SpecialChar",     { fg = c.cyan })
  hl("Delimiter",       { fg = c.fg_muted })
  hl("Tag",             { fg = c.blue })
  hl("Debug",           { fg = c.orange })
  hl("Ignore",          { fg = c.fg_faint })
  hl("Underlined",      { fg = c.blue, underline = true })

  -- Treesitter
  hl("@comment",                { fg = c.comment, italic = true })
  hl("@comment.error",          { fg = c.red })
  hl("@comment.warning",        { fg = c.orange })
  hl("@comment.todo",           { fg = c.orange, bold = true })
  hl("@none",                   { fg = c.fg })
  hl("@preproc",                { fg = c.pink })
  hl("@define",                 { fg = c.pink })
  hl("@keyword",                { fg = c.pink })
  hl("@keyword.function",       { fg = c.pink })
  hl("@keyword.operator",       { fg = c.pink })
  hl("@keyword.return",         { fg = c.pink, bold = true })
  hl("@keyword.storage",        { fg = c.pink })
  hl("@keyword.repeat",         { fg = c.pink })
  hl("@keyword.exception",      { fg = c.pink })
  hl("@keyword.conditional",    { fg = c.pink })
  hl("@keyword.directive",      { fg = c.pink })
  hl("@keyword.directive.endif",{ fg = c.fg_faint })
  hl("@keyword.import",         { fg = c.pink })
  hl("@keyword.debug",          { fg = c.orange })
  hl("@punctuation.delimiter",  { fg = c.fg_muted })
  hl("@punctuation.bracket",    { fg = c.fg_muted })
  hl("@punctuation.special",    { fg = c.pink })
  hl("@string",                 { fg = c.green })
  hl("@string.regexp",          { fg = c.cyan })
  hl("@string.escape",          { fg = c.cyan })
  hl("@string.special",         { fg = c.cyan })
  hl("@string.special.symbol",  { fg = c.cyan })
  hl("@string.special.url",     { fg = c.blue, underline = true })
  hl("@string.special.path",    { fg = c.cyan })
  hl("@character",              { fg = c.green })
  hl("@number",                 { fg = c.orange })
  hl("@boolean",                { fg = c.orange })
  hl("@float",                  { fg = c.orange })
  hl("@constant",               { fg = c.orange })
  hl("@constant.builtin",       { fg = c.orange, italic = true })
  hl("@constant.macro",         { fg = c.orange })
  hl("@attribute",              { fg = c.cyan })
  hl("@symbol",                 { fg = c.cyan })
  hl("@identifier",             { fg = c.fg })
  hl("@identifier.builtin",     { fg = c.purple })
  hl("@variable",               { fg = c.fg })
  hl("@variable.builtin",       { fg = c.purple })
  hl("@variable.member",        { fg = c.fg })
  hl("@variable.parameter",     { fg = c.pink })
  hl("@variable.parameter.builtin", { fg = c.pink, italic = true })
  hl("@module",                 { fg = c.blue })
  hl("@module.builtin",         { fg = c.blue, italic = true })
  hl("@label",                  { fg = c.pink })
  hl("@type",                   { fg = c.yellow })
  hl("@type.builtin",           { fg = c.yellow, italic = true })
  hl("@type.definition",        { fg = c.yellow })
  hl("@type.qualifier",         { fg = c.pink })
  hl("@property",               { fg = c.cyan })
  hl("@function",               { fg = c.blue })
  hl("@function.builtin",       { fg = c.purple })
  hl("@function.call",          { fg = c.blue })
  hl("@function.macro",         { fg = c.purple })
  hl("@function.method",        { fg = c.blue })
  hl("@function.method.call",   { fg = c.blue })
  hl("@constructor",            { fg = c.yellow })
  hl("@operator",               { fg = c.purple })
  hl("@exception",              { fg = c.pink })
  hl("@error",                  { fg = c.red })
  hl("@tag",                    { fg = c.blue })
  hl("@tag.attribute",          { fg = c.cyan })
  hl("@tag.delimiter",          { fg = c.fg_muted })
  hl("@text",                   { fg = c.fg })
  hl("@text.strong",            { bold = true })
  hl("@text.emphasis",          { italic = true })
  hl("@text.underline",         { underline = true })
  hl("@text.strike",            { strikethrough = true })
  hl("@text.title",             { fg = c.blue, bold = true })
  hl("@text.literal",           { fg = c.green })
  hl("@text.uri",               { fg = c.blue, underline = true })
  hl("@text.math",              { fg = c.purple })
  hl("@text.note",              { fg = c.cyan })
  hl("@text.warning",           { fg = c.orange })
  hl("@text.danger",            { fg = c.red })
  hl("@text.diff.add",          { fg = c.green })
  hl("@text.diff.delete",       { fg = c.red })
  hl("@diff.plus",              { fg = c.green })
  hl("@diff.minus",             { fg = c.red })
  hl("@diff.delta",             { fg = c.orange })

  -- Markdown
  hl("@markup.heading",           { fg = c.blue, bold = true })
  hl("@markup.raw",               { fg = c.green })
  hl("@markup.link",              { fg = c.blue, underline = true })
  hl("@markup.link.url",          { fg = c.blue, underline = true })
  hl("@markup.link.label",        { fg = c.cyan })
  hl("@markup.list",              { fg = c.pink })
  hl("@markup.list.checked",      { fg = c.green })
  hl("@markup.list.unchecked",    { fg = c.fg_muted })
  hl("@markup.quote",             { fg = c.fg_muted, italic = true })
  hl("@markup.raw.markdown_inline", { fg = c.green })
  hl("@markup.strikethrough",     { strikethrough = true })

  -- NvimTree
  hl("NvimTreeNormal",           { fg = c.fg, bg = c.bg })
  hl("NvimTreeNormalNC",         { fg = c.fg, bg = c.bg })
  hl("NvimTreeWinSeparator",     { fg = c.border, bg = c.border })
  hl("NvimTreeFolderName",       { fg = c.blue })
  hl("NvimTreeFolderIcon",       { fg = c.blue })
  hl("NvimTreeOpenedFolderName", { fg = c.blue, bold = true })
  hl("NvimTreeEmptyFolderName",  { fg = c.fg_muted })
  hl("NvimTreeGitDirty",         { fg = c.orange })
  hl("NvimTreeGitNew",           { fg = c.green })
  hl("NvimTreeGitDeleted",       { fg = c.red })
  hl("NvimTreeGitStaged",        { fg = c.blue })
  hl("NvimTreeGitMerge",         { fg = c.pink })
  hl("NvimTreeGitIgnored",       { fg = c.fg_faint, italic = true })
  hl("NvimTreeRootFolder",       { fg = c.fg_muted, bold = true })
  hl("NvimTreeSpecialFile",      { fg = c.pink })
  hl("NvimTreeImageFile",        { fg = c.purple })
  hl("NvimTreeOpenedFile",       { fg = c.pink })
  hl("NvimTreeIndentMarker",     { fg = c.nontext })
  hl("NvimTreeSymlink",          { fg = c.cyan })

  -- Telescope
  hl("TelescopeNormal",          { fg = c.fg, bg = c.bg_panel })
  hl("TelescopeBorder",          { fg = c.border, bg = c.bg_panel })
  hl("TelescopePromptNormal",    { fg = c.fg, bg = c.bg_hover })
  hl("TelescopePromptBorder",    { fg = c.blue, bg = c.bg_hover })
  hl("TelescopePromptTitle",     { fg = c.bg, bg = c.blue, bold = true })
  hl("TelescopePreviewTitle",    { fg = c.bg, bg = c.green, bold = true })
  hl("TelescopeResultsTitle",    { fg = c.bg, bg = c.bg_panel })
  hl("TelescopeSelection",       { bg = c.visual })
  hl("TelescopeSelectionCaret",  { fg = c.pink })
  hl("TelescokeMultiSelection",  { fg = c.green })
  hl("TelescopeMatching",        { fg = c.pink, bold = true })
  hl("TelescopeResultsDiffAdd",  { fg = c.green })
  hl("TelescopeResultsDiffChange", { fg = c.orange })
  hl("TelescopeResultsDiffDelete", { fg = c.red })

  -- Bufferline
  hl("BufferLineTabClose",       { fg = c.fg_faint })
  hl("BufferLineTabSelected",    { fg = c.fg, bold = true })
  hl("BufferLineTabSeparator",   { fg = c.border })
  hl("BufferLineDuplicate",      { fg = c.fg_faint, italic = true })
  hl("BufferLineModified",       { fg = c.orange })
  hl("BufferLineModifiedSelected", { fg = c.orange, bold = true })
  hl("BufferLineModifiedVisible", { fg = c.orange })
  hl("BufferLinePick",           { fg = c.blue })
  hl("BufferLinePickSelected",   { fg = c.blue, bold = true })
  hl("BufferLineBackground",     { fg = c.fg_muted, bg = c.bg })
  hl("BufferLineBufferVisible",  { fg = c.fg, bg = c.bg_alt })
  hl("BufferLineBufferSelected", { fg = c.fg, bg = c.bg_hover, bold = true })
  hl("BufferLineIndicatorSelected", { fg = c.blue, bg = c.bg_hover })
  hl("BufferLineOffsetSeparator", { fg = c.border, bg = c.bg })
  hl("BufferLineSeparator",      { fg = c.border, bg = c.bg })
  hl("BufferLineSeparatorSelected", { fg = c.border, bg = c.bg_hover })
  hl("BufferLineSeparatorVisible", { fg = c.border, bg = c.bg_alt })
  hl("BufferLineCloseButton",    { fg = c.fg_faint })
  hl("BufferLineCloseButtonSelected", { fg = c.red })
  hl("BufferLineCloseButtonVisible", { fg = c.fg_muted })
  hl("BufferLineError",          { fg = c.red })
  hl("BufferLineErrorSelected",  { fg = c.red, bold = true })
  hl("BufferLineWarning",        { fg = c.orange })
  hl("BufferLineWarningSelected",{ fg = c.orange, bold = true })
  hl("BufferLineInfo",           { fg = c.blue })
  hl("BufferLineInfoSelected",   { fg = c.blue, bold = true })
  hl("BufferLineHint",           { fg = c.cyan })
  hl("BufferLineHintSelected",   { fg = c.cyan, bold = true })
  hl("BufferLineVisible",        { fg = c.fg_muted, bg = c.bg_alt })
  hl("BufferLineGroupNormal",    { fg = c.fg_muted })
  hl("BufferLineGroupNormalNC",  { fg = c.fg_faint })
  hl("BufferLineNumbers",        { fg = c.fg_faint })
  hl("BufferLineNumbersSelected",{ fg = c.fg_muted })

  -- WhichKey
  hl("WhichKey",                { fg = c.pink, bold = true })
  hl("WhichKeyGroup",           { fg = c.blue })
  hl("WhichKeyDesc",            { fg = c.fg })
  hl("WhichKeySeperator",       { fg = c.fg_muted })
  hl("WhichKeyFloat",           { bg = c.bg_panel })
  hl("WhichKeyValue",           { fg = c.fg_muted })

  -- Noice
  hl("NoiceCmdlinePopupTitle",  { fg = c.blue, bold = true })
  hl("NoiceCmdlinePopupBorder", { fg = c.blue })
  hl("NoiceCmdlineIcon",        { fg = c.pink })
  hl("NoiceMini",               { fg = c.fg_muted, bg = c.bg_panel })
  hl("NoiceCompletionItemKindDefault", { fg = c.fg_muted })
  hl("NoiceCompletionItemKindKeyword", { fg = c.pink })
  hl("NoiceCompletionItemKindVariable", { fg = c.fg })
  hl("NoiceCompletionItemKindConstant", { fg = c.orange })
  hl("NoiceCompletionItemKindFunction", { fg = c.blue })
  hl("NoiceCompletionItemKindMethod",   { fg = c.blue })
  hl("NoiceCompletionItemKindClass",    { fg = c.yellow })
  hl("NoiceCompletionItemKindType",     { fg = c.yellow })
  hl("NoiceCompletionItemKindStruct",   { fg = c.yellow })
  hl("NoiceCompletionItemKindModule",   { fg = c.blue })
  hl("NoiceCompletionItemKindProperty", { fg = c.cyan })
  hl("NoiceCompletionItemKindField",    { fg = c.cyan })
  hl("NoiceCompletionItemKindEnum",     { fg = c.yellow })
  hl("NoiceCompletionItemKindInterface",{ fg = c.yellow })
  hl("NoiceCompletionItemKindSnippet",  { fg = c.purple })
  hl("NoiceCompletionItemKindColor",    { fg = c.purple })

  -- Flash
  hl("FlashLabel",              { fg = c.bg, bg = c.pink, bold = true })
  hl("FlashBackdrop",           { fg = c.fg_faint })
  hl("FlashMatch",              { fg = c.bg, bg = c.orange, bold = true })
  hl("FlashCurrent",            { fg = c.bg, bg = c.blue, bold = true })

  -- Mini
  hl("MiniCursorword",         { underline = true, sp = c.fg_faint })
  hl("MiniCursorwordCurrent",  { underline = true, sp = c.pink })
  hl("MiniTrailspace",         { bg = c.red })
  hl("MiniIndentscopeSymbol",  { fg = c.border })
  hl("MiniJump",               { fg = c.pink, bold = true })
  hl("MiniStarterCurrent",     { fg = c.fg })

  -- Indent Blankline / Ibl
  hl("IblIndent",              { fg = c.nontext })
  hl("IblWhitespace",          { fg = c.nontext })
  hl("IblScope",               { fg = c.fg_faint })

  -- Gitsigns
  hl("GitSignsAdd",            { fg = c.green })
  hl("GitSignsChange",         { fg = c.orange })
  hl("GitSignsDelete",         { fg = c.red })
  hl("GitSignsAddLn",          { bg = "#1C3A1F" })
  hl("GitSignsChangeLn",       { bg = "#1C2833" })
  hl("GitSignsDeleteLn",       { bg = "#3A1C1C" })
  hl("GitSignsAddNr",          { fg = c.green })
  hl("GitSignsChangeNr",       { fg = c.orange })
  hl("GitSignsDeleteNr",       { fg = c.red })

  -- Snacks
  hl("SnacksNormal",           { fg = c.fg, bg = c.bg_panel })
  hl("SnacksBorder",           { fg = c.border, bg = c.bg_panel })
  hl("SnacksBackdrop",         { bg = "#000000" })
  hl("SnacksIndent",           { fg = c.nontext })
  hl("SnacksScope",            { fg = c.fg_faint })
  hl("SnacksPickerMatch",      { fg = c.pink, bold = true })
  hl("SnacksPickerSelected",   { bg = c.visual })
  hl("SnacksPickerTitle",      { fg = c.bg, bg = c.blue, bold = true })

  -- Blink / Completions
  hl("BlinkCmpMenu",           { fg = c.fg, bg = c.bg_panel })
  hl("BlinkCmpMenuBorder",     { fg = c.border, bg = c.bg_panel })
  hl("BlinkCmpSel",            { bg = c.bg_hover, bold = true })
  hl("BlinkCmpScrollBarThumb", { bg = c.fg_faint })
  hl("BlinkCmpScrollBarTrack", { bg = c.border })
  hl("BlinkCmpGhostText",      { fg = c.fg_faint, italic = true })
  hl("BlinkCmpLabel",          { fg = c.fg })
  hl("BlinkCmpLabelMatch",     { fg = c.pink, bold = true })
  hl("BlinkCmpLabelDeprecated",{ fg = c.fg_faint, strikethrough = true })
  hl("BlinkCmpKindKeyword",    { fg = c.pink })
  hl("BlinkCmpKindVariable",   { fg = c.fg })
  hl("BlinkCmpKindConstant",   { fg = c.orange })
  hl("BlinkCmpKindFunction",   { fg = c.blue })
  hl("BlinkCmpKindMethod",     { fg = c.blue })
  hl("BlinkCmpKindClass",      { fg = c.yellow })
  hl("BlinkCmpKindType",       { fg = c.yellow })
  hl("BlinkCmpKindStruct",     { fg = c.yellow })
  hl("BlinkCmpKindModule",     { fg = c.blue })
  hl("BlinkCmpKindProperty",   { fg = c.cyan })
  hl("BlinkCmpKindField",      { fg = c.cyan })
  hl("BlinkCmpKindEnum",       { fg = c.yellow })
  hl("BlinkCmpKindInterface",  { fg = c.yellow })
  hl("BlinkCmpKindSnippet",    { fg = c.purple })
  hl("BlinkCmpKindColor",      { fg = c.purple })
  hl("BlinkCmpKindFile",       { fg = c.fg })
  hl("BlinkCmpKindReference",  { fg = c.green })
  hl("BlinkCmpKindFolder",     { fg = c.blue })
  hl("BlinkCmpKindUnit",       { fg = c.fg_muted })
  hl("BlinkCmpKindValue",      { fg = c.orange })

  -- Lualine theme
  vim.api.nvim_set_hl(0, "LualineNormal",  { fg = c.fg_faint, bg = c.bg_alt })
  vim.api.nvim_set_hl(0, "LualineInsert",  { fg = c.bg, bg = c.blue })
  vim.api.nvim_set_hl(0, "LualineVisual",  { fg = c.bg, bg = c.pink })
  vim.api.nvim_set_hl(0, "LualineCommand", { fg = c.bg, bg = c.purple })
  vim.api.nvim_set_hl(0, "LualineReplace", { fg = c.bg, bg = c.orange })
  vim.api.nvim_set_hl(0, "LualineTerminal",{ fg = c.bg, bg = c.green })
  vim.api.nvim_set_hl(0, "LualineInactive",{ fg = c.fg_faint, bg = c.bg })

  -- FzfLua
  hl("FzfLuaNormal",           { fg = c.fg, bg = c.bg_panel })
  hl("FzfLuaBorder",           { fg = c.border, bg = c.bg_panel })
  hl("FzfLuaTitle",            { fg = c.blue, bg = c.bg_panel, bold = true })
  hl("FzfLuaCursor",           { fg = c.bg, bg = c.pink })
  hl("FzfLuaSearch",           { fg = c.fg, bg = c.bg_hover })
  hl("FzfLuaSearchCnt",        { fg = c.fg_faint })

  -- Notify
  hl("NotifyINFOBorder",       { fg = c.blue })
  hl("NotifyINFOTitle",        { fg = c.blue })
  hl("NotifyINFOIcon",         { fg = c.blue })
  hl("NotifyWARNBorder",       { fg = c.orange })
  hl("NotifyWARNTitle",        { fg = c.orange })
  hl("NotifyWARNIcon",         { fg = c.orange })
  hl("NotifyERRORBorder",      { fg = c.red })
  hl("NotifyERRORTitle",       { fg = c.red })
  hl("NotifyERRORIcon",        { fg = c.red })
  hl("NotifyDEBUGBorder",      { fg = c.fg_faint })
  hl("NotifyDEBUGTitle",       { fg = c.fg_faint })
  hl("NotifyDEBUGIcon",        { fg = c.fg_faint })
  hl("NotifyTRACEBorder",      { fg = c.purple })
  hl("NotifyTRACETitle",       { fg = c.purple })
  hl("NotifyTRACEIcon",        { fg = c.purple })
  hl("NotifyINFOBody",         { fg = c.fg, bg = c.bg_panel })
  hl("NotifyWARNBody",         { fg = c.fg, bg = c.bg_panel })
  hl("NotifyERRORBody",        { fg = c.fg, bg = c.bg_panel })
  hl("NotifyDEBUGBody",        { fg = c.fg, bg = c.bg_panel })
  hl("NotifyTRACEBody",        { fg = c.fg, bg = c.bg_panel })
end

return M
