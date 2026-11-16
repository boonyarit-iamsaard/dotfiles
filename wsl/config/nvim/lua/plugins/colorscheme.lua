return {
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
        flavour = "macchiato",
        -- flavour = "auto",
        -- transparent_background = true,
      })
    end,
  },

  {
    -- Published from this config; shared/themes/vscode/dark-2026.jsonc is the
    -- VS Code theme it started from. Upstream: github.com/boonyarit-iamsaard/dark-2026.nvim
    "boonyarit-iamsaard/dark-2026.nvim",
    lazy = false,
    priority = 1000,
    -- `setup()` has to run before the colorscheme is applied, so options go in
    -- `config` rather than an `opts` table LazyVim would merge in later.
    config = function()
      require("dark-2026").setup({
        transparent = true,
        on_highlights = function(hl)
          hl.SnacksNormal.bg = "NONE"
          hl.SnacksNormalNC.bg = "NONE"
        end,
      })
    end,
  },

  {
    -- vscode.nvim mixes Dark+ and Dark Modern; these pull its surfaces onto
    -- Dark Modern. Hexes from microsoft/vscode theme-defaults/themes/dark_modern.json,
    -- each commented with the VS Code key it came from.
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("vscode").setup({
        -- transparent = true,
        color_overrides = {
          vscFront = "#cccccc", -- editor.foreground
          vscLineNumber = "#6e7681", -- editorLineNumber.foreground
          vscLeftDark = "#181818", -- sideBar.background
          vscTabOutside = "#181818", -- editorGroupHeader.tabsBackground
          vscSplitDark = "#333333", -- editorGroup.border (#ffffff17 over editor.background)
          vscSearchCurrent = "#9e6a03", -- editor.findMatchBackground
        },
        group_overrides = {
          -- vscode.nvim leaves CurSearch unset, so it falls back to Neovim's default.
          CurSearch = { link = "IncSearch" },
        },
      })
    end,
  },

  -- Keep at most one import, matching the active colorscheme below (none for catppuccin).
  -- { import = "themes.dark-2026" },
  -- { import = "themes.default-dark-modern" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-macchiato",
      -- colorscheme = "dark-2026",
      -- colorscheme = "vscode",
    },
  },
}
