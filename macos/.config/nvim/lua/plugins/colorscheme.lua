return {
  -- Uncomment the matching theme import when selecting a different colorscheme.
  -- { import = "themes.dark-2026" },
  -- { import = "themes.default-dark-modern" },
  {
    "boonyarit-iamsaard/dark-2026.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("dark-2026").setup({})
    end,
  },

  {
    -- vscode.nvim mixes Dark+ and Dark Modern; these pull its surfaces onto
    -- Dark Modern. Hexes from microsoft/vscode theme-defaults/themes/dark_modern.json,
    -- each commented with the VS Code key it came from.
    "Mofiqul/vscode.nvim",
    priority = 1000,
    config = function()
      require("vscode").setup({
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

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("catppuccin").setup({
        flavour = "macchiato", -- latte, frappe, macchiato, mocha
        transparent_background = true, -- let Ghostty's background-opacity/blur show through
        float = {
          transparent = true, -- also make floating windows (pickers, hover, etc.) transparent
          solid = false,
        },
      })
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-macchiato",
      -- colorscheme = "catppuccin-mocha",
      -- colorscheme = "dark-2026",
      -- colorscheme = "vscode",
    },
  },
}
