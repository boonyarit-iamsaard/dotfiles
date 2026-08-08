-- Diagnostics, LSP semantic tokens, and completion-kind icons.

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
return function(p)
  local groups = {
    -- Diagnostics -----------------------------------------------------------
    DiagnosticError = { fg = p.error },
    DiagnosticWarn = { fg = p.warn },
    DiagnosticInfo = { fg = p.info },
    DiagnosticHint = { fg = p.hint },
    DiagnosticOk = { fg = p.ok },

    DiagnosticVirtualTextError = { fg = p.error, bg = p.blend(p.error, p.bg, 0.1) },
    DiagnosticVirtualTextWarn = { fg = p.warn, bg = p.blend(p.warn, p.bg, 0.1) },
    DiagnosticVirtualTextInfo = { fg = p.info, bg = p.blend(p.info, p.bg, 0.1) },
    DiagnosticVirtualTextHint = { fg = p.hint, bg = p.blend(p.hint, p.bg, 0.1) },
    DiagnosticVirtualTextOk = { fg = p.ok, bg = p.blend(p.ok, p.bg, 0.1) },

    DiagnosticUnderlineError = { sp = p.error, undercurl = true },
    DiagnosticUnderlineWarn = { sp = p.warn, undercurl = true },
    DiagnosticUnderlineInfo = { sp = p.info, undercurl = true },
    DiagnosticUnderlineHint = { sp = p.hint, undercurl = true },
    DiagnosticUnderlineOk = { sp = p.ok, undercurl = true },

    DiagnosticFloatingError = { fg = p.error, bg = p.bg_float },
    DiagnosticFloatingWarn = { fg = p.warn, bg = p.bg_float },
    DiagnosticFloatingInfo = { fg = p.info, bg = p.bg_float },
    DiagnosticFloatingHint = { fg = p.hint, bg = p.bg_float },
    DiagnosticFloatingOk = { fg = p.ok, bg = p.bg_float },

    DiagnosticSignError = { fg = p.error },
    DiagnosticSignWarn = { fg = p.warn },
    DiagnosticSignInfo = { fg = p.info },
    DiagnosticSignHint = { fg = p.hint },
    DiagnosticSignOk = { fg = p.ok },

    DiagnosticDeprecated = { fg = p.fg_dim, strikethrough = true },
    DiagnosticUnnecessary = { fg = p.fg_disabled }, -- editorUnnecessaryCode

    -- LSP -------------------------------------------------------------------
    LspReferenceText = { bg = p.bg_word }, -- editor.wordHighlightBackground
    LspReferenceRead = { bg = p.bg_word },
    LspReferenceWrite = { bg = p.blend("#27678280", p.bg) }, -- ...StrongBackground
    LspReferenceTarget = { bg = p.bg_word },
    LspSignatureActiveParameter = { fg = p.type, bold = true },
    LspCodeLens = { fg = p.fg_dim }, -- editorCodeLens.foreground
    LspCodeLensSeparator = { fg = p.fg_gutter },
    LspInlayHint = { fg = "#969696", bg = p.blend("#307e9f1a", p.bg) }, -- editorInlayHint.*
    LspInfoBorder = { fg = p.border, bg = p.bg_float },

    -- Semantic tokens -------------------------------------------------------
    ["@lsp.type.namespace"] = { fg = p.type },
    ["@lsp.type.type"] = { fg = p.type },
    ["@lsp.type.class"] = { fg = p.type },
    ["@lsp.type.enum"] = { fg = p.type },
    ["@lsp.type.interface"] = { fg = p.type },
    ["@lsp.type.struct"] = { fg = p.type },
    ["@lsp.type.typeParameter"] = { fg = p.type },
    ["@lsp.type.parameter"] = { fg = p.type },
    ["@lsp.type.variable"] = { fg = p.text },
    ["@lsp.type.property"] = { fg = p.text },
    ["@lsp.type.enumMember"] = { fg = p.constant },
    ["@lsp.type.function"] = { fg = p.func },
    ["@lsp.type.method"] = { fg = p.func },
    ["@lsp.type.macro"] = { fg = p.func },
    ["@lsp.type.decorator"] = { fg = p.func },
    ["@lsp.type.event"] = { fg = p.func },
    ["@lsp.type.keyword"] = { fg = p.keyword },
    ["@lsp.type.modifier"] = { fg = p.keyword },
    ["@lsp.type.operator"] = { fg = p.keyword },
    ["@lsp.type.comment"] = { fg = p.comment, italic = true },
    ["@lsp.type.string"] = { fg = p.string },
    ["@lsp.type.number"] = { fg = p.constant },
    ["@lsp.type.regexp"] = { fg = p.string },
    ["@lsp.type.selfKeyword"] = { fg = p.constant },
    ["@lsp.type.builtinType"] = { fg = p.keyword },

    ["@lsp.mod.readonly"] = { fg = p.constant },
    ["@lsp.mod.deprecated"] = { strikethrough = true },
    ["@lsp.typemod.variable.readonly"] = { fg = p.constant },
    ["@lsp.typemod.variable.defaultLibrary"] = { fg = p.constant },
    ["@lsp.typemod.function.defaultLibrary"] = { fg = p.constant },
    ["@lsp.typemod.method.defaultLibrary"] = { fg = p.constant },
    ["@lsp.typemod.type.defaultLibrary"] = { fg = p.type },
    ["@lsp.typemod.class.defaultLibrary"] = { fg = p.type },
    ["@lsp.typemod.keyword.async"] = { fg = p.keyword },
  }

  -- Completion-item kinds, mirroring VS Code's symbolIcon.* family.
  local kinds = {
    Array = p.fg_ui,
    Boolean = p.fg_ui,
    Class = "#ee9d28", -- symbolIcon.classForeground
    Color = p.fg_ui,
    Constant = p.fg_ui,
    Constructor = "#b180d7", -- symbolIcon.constructorForeground
    Enum = "#ee9d28",
    EnumMember = "#75beff", -- symbolIcon.enumeratorMemberForeground
    Event = "#ee9d28",
    Field = "#75beff", -- symbolIcon.fieldForeground
    File = p.fg_ui,
    Folder = p.fg_ui,
    Function = "#b180d7", -- symbolIcon.functionForeground
    Interface = "#75beff",
    Key = p.fg_ui,
    Keyword = p.fg_ui,
    Method = "#b180d7",
    Module = p.fg_ui,
    Namespace = p.fg_ui,
    Null = p.fg_ui,
    Number = p.fg_ui,
    Object = p.fg_ui,
    Operator = p.fg_ui,
    Package = p.fg_ui,
    Property = p.fg_ui,
    Reference = p.fg_ui,
    Snippet = p.fg_ui,
    String = p.fg_ui,
    Struct = p.fg_ui,
    Text = p.fg_ui,
    TypeParameter = p.fg_ui,
    Unit = p.fg_ui,
    Value = p.fg_ui,
    Variable = p.fg_ui,
  }
  for kind, color in pairs(kinds) do
    groups["CmpItemKind" .. kind] = { fg = color }
    groups["BlinkCmpKind" .. kind] = { fg = color }
    groups["LspKind" .. kind] = { fg = color }
  end

  return groups
end
