-- local helpers = require("helpers")

return {
  -- {
  --   "folke/tokyonight.nvim",
  --   opts = {
  --     -- transparent = true,
  --     style = "moon",
  --     -- styles = {
  --     --   sidebars = "transparent",
  --     --   floats = "transparent",
  --     -- },
  --   },
  -- },

  -- {
  --   "sainnhe/edge",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     -- Optionally configure and load the colorscheme
  --     -- directly inside the plugin declaration.
  --     -- vim.g.edge_style = "neon"
  --     vim.g.edge_enable_italic = true
  --     vim.cmd.colorscheme("edge")
  --   end,
  -- },

  -- {
  --   "projekt0n/github-nvim-theme",
  --   name = "github-theme",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("github-theme").setup({
  --       --
  --     })
  --
  --     local appearance = helpers.get_macos_appearance()
  --     local theme = appearance == "light" and "github_light_default" or "github_dark_default"
  --     vim.cmd("colorscheme " .. theme)
  --   end,
  -- },

  -- {
  --   "Mofiqul/dracula.nvim",
  --   opts = {
  --     transparent_bg = false,
  --   },
  -- },

  -- {
  --   "navarasu/onedark.nvim",
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     require("onedark").setup({
  --       style = "dark",
  --     })
  --     require("onedark").load()
  --   end,
  -- },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("catppuccin").setup({
        -- background = {
        --   light = "latte",
        --   dark = "macchiato",
        -- },
        flavour = "mocha",
        -- flavour = "auto",
        -- transparent_background = true,
      })
    end,
  },

  -- {
  --   "Shatur/neovim-ayu",
  --   config = function()
  --     require("ayu").setup({
  --       mirage = true,
  --       terminal = true,
  --       overrides = {},
  --     })
  --   end,
  -- },

  -- {
  --   "olimorris/onedarkpro.nvim",
  --   priority = 1000, -- Ensure it loads first
  -- },

  {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    -- config = function()
    --   -- Keep Neovim on vscode.nvim, but override its palette/highlights to track
    --   -- the current VS Code Dark 2026 theme defined in this dotfiles repo.
    --   local palette = {
    --     bg = "#121314",
    --     surface = "#191A1B",
    --     panel = "#202122",
    --     line = "#242526",
    --     border = "#2A2B2C",
    --     selection = "#276782",
    --     search = "#276782",
    --     search_current = "#3994BC",
    --     fg = "#BBBEBF",
    --     fg_soft = "#BFBFBF",
    --     muted = "#8C8C8C",
    --     subtle = "#555555",
    --     blue = "#3994BC",
    --     blue_light = "#59A4F9",
    --     cyan = "#48A0C7",
    --     green = "#73C991",
    --     yellow = "#E5BA7D",
    --     orange = "#E2C08D",
    --     red = "#F48771",
    --     magenta = "#AD80D7",
    --     white = "#FFFFFF",
    --   }

    --   require("vscode").setup({
    --     style = "dark",
    --     transparent = false,
    --     italic_comments = true,
    --     disable_nvimtree_bg = true,
    --     color_overrides = {
    --       vscBack = palette.bg,
    --       vscFront = palette.fg,
    --       vscPopupBack = palette.panel,
    --       vscPopupFront = palette.fg_soft,
    --       vscLineNumber = palette.muted,
    --       vscSelectionBackground = palette.selection,
    --       vscCursorDarkDark = palette.bg,
    --       vscCursorDark = palette.surface,
    --       vscCursorLight = palette.fg_soft,
    --       vscSplitLight = palette.border,
    --       vscSplitDark = palette.border,
    --       vscUiBlue = palette.blue,
    --       vscAccentBlue = palette.blue,
    --       vscMediumBlue = palette.blue_light,
    --       vscBlue = palette.blue_light,
    --       vscLightBlue = palette.cyan,
    --       vscGreen = palette.green,
    --       vscYellow = palette.yellow,
    --       vscOrange = palette.orange,
    --       vscRed = palette.red,
    --       vscPink = palette.magenta,
    --       vscSearchResult = palette.search,
    --       vscSearchCurrent = palette.search_current,
    --     },
    --     group_overrides = {
    --       Normal = { fg = palette.fg, bg = palette.bg },
    --       NormalNC = { fg = palette.fg, bg = palette.bg },
    --       NormalFloat = { fg = palette.fg_soft, bg = palette.panel },
    --       FloatBorder = { fg = palette.border, bg = palette.panel },
    --       FloatTitle = { fg = palette.blue_light, bg = palette.panel, bold = true },
    --       CursorLine = { bg = palette.line },
    --       CursorLineNr = { fg = palette.fg_soft, bg = palette.line, bold = true },
    --       LineNr = { fg = palette.muted },
    --       SignColumn = { bg = palette.bg },
    --       VertSplit = { fg = palette.border },
    --       WinSeparator = { fg = palette.border },
    --       Visual = { bg = palette.selection },
    --       Search = { fg = palette.fg_soft, bg = palette.search },
    --       IncSearch = { fg = palette.bg, bg = palette.blue_light, bold = true },
    --       CurSearch = { fg = palette.bg, bg = palette.blue_light, bold = true },
    --       MatchParen = { fg = palette.white, bg = palette.blue, bold = true },
    --       Pmenu = { fg = palette.fg_soft, bg = palette.panel },
    --       PmenuSel = { fg = palette.white, bg = palette.blue },
    --       PmenuSbar = { bg = palette.line },
    --       PmenuThumb = { bg = palette.muted },
    --       StatusLine = { fg = palette.fg_soft, bg = palette.surface },
    --       StatusLineNC = { fg = palette.muted, bg = palette.surface },
    --       TabLine = { fg = palette.muted, bg = palette.surface },
    --       TabLineFill = { bg = palette.surface },
    --       TabLineSel = { fg = palette.white, bg = palette.line, bold = true },
    --       Comment = { fg = palette.muted, italic = true },
    --       Constant = { fg = palette.blue_light },
    --       String = { fg = palette.orange },
    --       Character = { fg = palette.orange },
    --       Number = { fg = palette.green },
    --       Boolean = { fg = palette.blue_light },
    --       Identifier = { fg = palette.fg_soft },
    --       Function = { fg = palette.yellow },
    --       Statement = { fg = palette.blue_light },
    --       Conditional = { fg = palette.magenta },
    --       Repeat = { fg = palette.magenta },
    --       Keyword = { fg = palette.blue_light },
    --       Operator = { fg = palette.fg },
    --       Type = { fg = palette.cyan },
    --       Special = { fg = palette.red },
    --       DiagnosticError = { fg = palette.red },
    --       DiagnosticWarn = { fg = palette.yellow },
    --       DiagnosticInfo = { fg = palette.blue_light },
    --       DiagnosticHint = { fg = palette.cyan },
    --     },
    --   })
    -- end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-macchiato",
      -- The active Neovim theme is the vscode.nvim base with Dark 2026 overrides above.
      -- colorscheme = "vscode",
    },
  },
}
