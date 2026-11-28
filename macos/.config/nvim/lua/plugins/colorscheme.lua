-- The active theme comes from lua/active_theme.lua, which macos/scripts/set-theme
-- writes outside the checkout; this file names no theme.
local ok, theme = pcall(require, "active_theme")
if not ok then
  -- Only a missing fragment falls back; a broken one should fail loudly.
  if not tostring(theme):find("module 'active_theme' not found", 1, true) then
    error(theme)
  end
  theme = {}
  vim.schedule(function()
    vim.notify("No active theme: run ~/dotfiles/macos/scripts/set-theme", vim.log.levels.WARN)
  end)
end

return {
  theme.import and { import = theme.import } or {},
  {
    "boonyarit-iamsaard/dark-2026.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("dark-2026").setup({ transparent = true }) -- let Ghostty's background-opacity show through
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
        flavour = theme.flavour,
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
      colorscheme = theme.colorscheme,
    },
  },
}
