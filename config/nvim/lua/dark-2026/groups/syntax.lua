-- Legacy syntax groups and Treesitter captures.
--
-- Colors follow the *effective* tokenColors of dark-2026.jsonc. The theme
-- stacks a GitHub Dark ruleset on top of an older Dark+ one and VS Code
-- resolves ties in favour of the later rule, so the Dark+ values are dead
-- weight upstream and are not reproduced here.

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
return function(p)
  return {
    -- Legacy groups ---------------------------------------------------------
    Comment = { fg = p.comment, italic = true },
    Constant = { fg = p.constant },
    String = { fg = p.string },
    Character = { fg = p.string },
    Number = { fg = p.constant },
    Boolean = { fg = p.constant },
    Float = { fg = p.constant },
    Identifier = { fg = p.text },
    Function = { fg = p.func },
    Statement = { fg = p.keyword },
    Conditional = { fg = p.keyword },
    Repeat = { fg = p.keyword },
    Label = { fg = p.keyword },
    Operator = { fg = p.keyword },
    Keyword = { fg = p.keyword },
    Exception = { fg = p.keyword },
    PreProc = { fg = p.keyword },
    Include = { fg = p.keyword },
    Define = { fg = p.keyword },
    Macro = { fg = p.keyword },
    PreCondit = { fg = p.keyword },
    Type = { fg = p.type },
    StorageClass = { fg = p.keyword },
    Structure = { fg = p.type },
    Typedef = { fg = p.type },
    Special = { fg = p.constant },
    SpecialChar = { fg = p.constant },
    Tag = { fg = p.tag },
    Delimiter = { fg = p.fg },
    SpecialComment = { fg = p.comment, italic = true },
    Debug = { fg = p.keyword },
    Underlined = { underline = true },
    Bold = { bold = true },
    Italic = { italic = true },
    Ignore = { fg = p.fg_disabled },
    Error = { fg = p.invalid },
    Todo = { fg = p.bg, bg = p.git_change, bold = true },

    -- Treesitter: identifiers ----------------------------------------------
    ["@variable"] = { fg = p.text }, -- variable.other
    ["@variable.builtin"] = { fg = p.constant }, -- variable.language
    ["@variable.parameter"] = { fg = p.type }, -- variable.parameter
    ["@variable.parameter.builtin"] = { fg = p.type },
    ["@variable.member"] = { fg = p.text }, -- meta.object.member
    ["@constant"] = { fg = p.constant },
    ["@constant.builtin"] = { fg = p.constant },
    ["@constant.macro"] = { fg = p.constant },
    ["@module"] = { fg = p.type }, -- entity.name.namespace
    ["@module.builtin"] = { fg = p.type },
    ["@label"] = { fg = p.keyword },

    -- Treesitter: literals --------------------------------------------------
    ["@string"] = { fg = p.string },
    ["@string.documentation"] = { fg = p.string },
    ["@string.regexp"] = { fg = p.string },
    ["@string.escape"] = { fg = p.constant },
    ["@string.special"] = { fg = p.constant },
    ["@string.special.symbol"] = { fg = p.constant },
    ["@string.special.url"] = { fg = p.link, underline = true },
    ["@string.special.path"] = { fg = p.string },
    ["@character"] = { fg = p.string },
    ["@character.special"] = { fg = p.constant },
    ["@boolean"] = { fg = p.constant },
    ["@number"] = { fg = p.constant },
    ["@number.float"] = { fg = p.constant },

    -- Treesitter: types -----------------------------------------------------
    ["@type"] = { fg = p.type }, -- entity.name.type
    ["@type.builtin"] = { fg = p.keyword },
    ["@type.definition"] = { fg = p.type },
    ["@attribute"] = { fg = p.func },
    ["@attribute.builtin"] = { fg = p.func },
    ["@property"] = { fg = p.text },

    -- Treesitter: functions -------------------------------------------------
    ["@function"] = { fg = p.func }, -- entity.name.function
    ["@function.builtin"] = { fg = p.constant }, -- support.function
    ["@function.call"] = { fg = p.func },
    ["@function.macro"] = { fg = p.func },
    ["@function.method"] = { fg = p.func },
    ["@function.method.call"] = { fg = p.func },
    ["@constructor"] = { fg = p.type },
    ["@operator"] = { fg = p.keyword },

    -- Treesitter: keywords --------------------------------------------------
    ["@keyword"] = { fg = p.keyword },
    ["@keyword.coroutine"] = { fg = p.keyword },
    ["@keyword.function"] = { fg = p.keyword },
    ["@keyword.operator"] = { fg = p.keyword },
    ["@keyword.import"] = { fg = p.keyword },
    ["@keyword.type"] = { fg = p.keyword },
    ["@keyword.modifier"] = { fg = p.keyword },
    ["@keyword.repeat"] = { fg = p.keyword },
    ["@keyword.return"] = { fg = p.keyword },
    ["@keyword.debug"] = { fg = p.keyword },
    ["@keyword.exception"] = { fg = p.keyword },
    ["@keyword.conditional"] = { fg = p.keyword },
    ["@keyword.conditional.ternary"] = { fg = p.keyword },
    ["@keyword.directive"] = { fg = p.keyword },
    ["@keyword.directive.define"] = { fg = p.keyword },

    -- Treesitter: punctuation ----------------------------------------------
    ["@punctuation.delimiter"] = { fg = p.fg },
    ["@punctuation.bracket"] = { fg = p.fg },
    ["@punctuation.special"] = { fg = p.constant },

    -- Treesitter: comments --------------------------------------------------
    ["@comment"] = { fg = p.comment, italic = true },
    ["@comment.documentation"] = { fg = p.comment, italic = true },
    ["@comment.error"] = { fg = p.bg, bg = p.error, bold = true },
    ["@comment.warning"] = { fg = p.bg, bg = p.warn, bold = true },
    ["@comment.note"] = { fg = p.bg, bg = p.info, bold = true },
    ["@comment.todo"] = { fg = p.bg, bg = p.git_change, bold = true },

    -- Treesitter: markup ----------------------------------------------------
    ["@markup"] = { fg = p.fg },
    ["@markup.strong"] = { fg = p.text, bold = true },
    ["@markup.italic"] = { fg = p.text, italic = true },
    ["@markup.strikethrough"] = { fg = p.fg_dim, strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.heading"] = { fg = p.constant, bold = true },
    ["@markup.heading.1"] = { fg = p.constant, bold = true },
    ["@markup.heading.2"] = { fg = p.constant, bold = true },
    ["@markup.heading.3"] = { fg = p.func, bold = true },
    ["@markup.heading.4"] = { fg = p.func, bold = true },
    ["@markup.heading.5"] = { fg = p.type, bold = true },
    ["@markup.heading.6"] = { fg = p.type, bold = true },
    ["@markup.quote"] = { fg = p.fg_dim, italic = true },
    ["@markup.math"] = { fg = p.constant },
    ["@markup.link"] = { fg = p.link },
    ["@markup.link.label"] = { fg = p.link },
    ["@markup.link.url"] = { fg = p.link, underline = true },
    ["@markup.raw"] = { fg = p.string },
    ["@markup.raw.block"] = { fg = p.fg },
    ["@markup.list"] = { fg = p.keyword },
    ["@markup.list.checked"] = { fg = p.ok },
    ["@markup.list.unchecked"] = { fg = p.fg_dim },

    -- Treesitter: diff ------------------------------------------------------
    ["@diff.plus"] = { fg = p.git_add }, -- markup.inserted
    ["@diff.minus"] = { fg = p.deleted }, -- markup.deleted
    ["@diff.delta"] = { fg = p.git_change },

    -- Treesitter: tags ------------------------------------------------------
    ["@tag"] = { fg = p.tag }, -- entity.name.tag
    ["@tag.builtin"] = { fg = p.tag },
    ["@tag.attribute"] = { fg = p.constant }, -- entity.other.attribute-name
    ["@tag.delimiter"] = { fg = p.fg_dim },

    -- Language tweaks -------------------------------------------------------
    -- Object-literal keys keep their own color upstream
    -- (meta.object-literal.key), unlike ordinary members.
    ["@property.json"] = { fg = p.key },
    ["@property.jsonc"] = { fg = p.key },
    ["@property.yaml"] = { fg = p.key },
    ["@property.toml"] = { fg = p.key },
    ["@label.json"] = { fg = p.key },
    ["@string.special.url.html"] = { fg = p.link, underline = true },
    ["@constant.builtin.go"] = { fg = p.constant },
    ["@variable.member.lua"] = { fg = p.text },

    -- Misc ------------------------------------------------------------------
    ["@none"] = {},
    ["@error"] = { fg = p.invalid },
    ["@conceal"] = { fg = p.fg_disabled },
    ["@spell"] = {},
    ["@nospell"] = {},
  }
end
