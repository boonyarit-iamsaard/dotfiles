-- Core editor chrome: windows, gutters, statusline, menus, messages.

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
return function(p)
  return {
    -- Base ------------------------------------------------------------------
    Normal = { fg = p.fg, bg = p.bg },
    NormalNC = { fg = p.fg, bg = p.bg },
    NormalFloat = { fg = p.fg_ui, bg = p.bg_float },
    FloatBorder = { fg = p.border, bg = p.bg_float },
    FloatTitle = { fg = p.fg_ui, bg = p.bg_float, bold = true },
    FloatFooter = { fg = p.fg_dim, bg = p.bg_float },
    Conceal = { fg = p.fg_disabled },
    EndOfBuffer = { fg = p.bg },

    -- Cursor / lines --------------------------------------------------------
    Cursor = { fg = p.bg, bg = p.fg },
    lCursor = { link = "Cursor" },
    CursorIM = { link = "Cursor" },
    TermCursor = { fg = p.bg_panel, bg = p.fg_ui }, -- terminalCursor.*
    CursorLine = { bg = p.bg_line },
    CursorColumn = { bg = p.bg_line },
    ColorColumn = { bg = p.bg_line },
    LineNr = { fg = p.fg_gutter },
    CursorLineNr = { fg = p.fg, bold = true },
    LineNrAbove = { fg = p.fg_gutter },
    LineNrBelow = { fg = p.fg_gutter },
    SignColumn = { bg = p.bg },
    FoldColumn = { fg = p.fg_dim, bg = p.bg },
    Folded = { fg = p.fg_dim, bg = p.bg_line },
    CursorLineFold = { fg = p.fg_dim, bg = p.bg_line },
    CursorLineSign = { bg = p.bg_line },

    -- Splits / windows ------------------------------------------------------
    WinSeparator = { fg = p.border },
    VertSplit = { fg = p.border },
    WinBar = { fg = p.fg_dim, bg = p.bg }, -- breadcrumb.*
    WinBarNC = { fg = p.fg_disabled, bg = p.bg },

    -- Selection / search ----------------------------------------------------
    Visual = { bg = p.bg_visual },
    VisualNOS = { bg = p.bg_visual },
    Search = { bg = p.bg_search },
    IncSearch = { bg = p.bg_search_cur },
    CurSearch = { bg = p.bg_search_cur },
    Substitute = { fg = p.bg, bg = p.git_change },
    MatchParen = { bg = p.bg_bracket, bold = true },

    -- Statusline / tabline --------------------------------------------------
    StatusLine = { fg = p.fg_dim, bg = p.bg_panel },
    StatusLineNC = { fg = p.fg_disabled, bg = p.bg_panel },
    TabLine = { fg = p.fg_dim, bg = p.bg_panel }, -- tab.inactive*
    TabLineFill = { bg = p.bg_panel },
    TabLineSel = { fg = p.fg_ui, bg = p.bg }, -- tab.active*

    -- Menus -----------------------------------------------------------------
    Pmenu = { fg = p.fg_ui, bg = p.bg_float },
    PmenuSel = { bg = p.bg_sel_menu },
    PmenuKind = { fg = p.constant, bg = p.bg_float },
    PmenuKindSel = { fg = p.constant, bg = p.bg_sel_menu },
    PmenuExtra = { fg = p.fg_dim, bg = p.bg_float },
    PmenuExtraSel = { fg = p.fg_dim, bg = p.bg_sel_menu },
    PmenuSbar = { bg = p.bg_float },
    PmenuThumb = { bg = p.fg_disabled },
    PmenuMatch = { fg = p.link, bg = p.bg_float, bold = true },
    PmenuMatchSel = { fg = p.link, bg = p.bg_sel_menu, bold = true },
    WildMenu = { link = "PmenuSel" },
    QuickFixLine = { bg = p.bg_sel_list },

    -- Messages --------------------------------------------------------------
    ErrorMsg = { fg = p.error },
    WarningMsg = { fg = p.warn },
    MoreMsg = { fg = p.link },
    ModeMsg = { fg = p.fg_ui, bold = true },
    Question = { fg = p.link },
    MsgArea = { fg = p.fg_ui },
    MsgSeparator = { fg = p.border },
    NonText = { fg = p.fg_gutter },
    SpecialKey = { fg = p.fg_gutter },
    Whitespace = { fg = p.whitespace },
    Directory = { fg = p.link },
    Title = { fg = p.fg_ui, bold = true },

    -- Indent guides (editorIndentGuide.*) -----------------------------------
    IndentLine = { fg = p.indent },
    IndentLineCurrent = { fg = p.fg_gutter },

    -- Diff ------------------------------------------------------------------
    DiffAdd = { bg = p.diff_add },
    DiffChange = { bg = p.diff_change },
    DiffDelete = { bg = p.diff_delete },
    DiffText = { bg = p.diff_text_add },
    Added = { fg = p.git_add },
    Changed = { fg = p.git_change },
    Removed = { fg = p.git_delete },

    -- Spell -----------------------------------------------------------------
    SpellBad = { sp = p.error, undercurl = true },
    SpellCap = { sp = p.warn, undercurl = true },
    SpellLocal = { sp = p.info, undercurl = true },
    SpellRare = { sp = p.hint, undercurl = true },

    -- Misc ------------------------------------------------------------------
    healthError = { fg = p.error },
    healthWarning = { fg = p.warn },
    healthSuccess = { fg = p.ok },
    debugPC = { bg = p.bg_line },
    debugBreakpoint = { fg = p.error },
  }
end
