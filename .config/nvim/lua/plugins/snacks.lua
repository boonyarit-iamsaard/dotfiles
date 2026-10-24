local function set_transparent_lazygit_highlights()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local border = vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false })

  normal.bg = "NONE"
  border.bg = "NONE"

  vim.api.nvim_set_hl(0, "SnacksLazygitNormal", normal)
  vim.api.nvim_set_hl(0, "SnacksLazygitBorder", border)
end

return {
  {
    "snacks.nvim",
    opts = {
      indent = { enabled = false },
      styles = {
        lazygit = {
          backdrop = false,
          on_win = set_transparent_lazygit_highlights,
          wo = {
            winhighlight = table.concat({
              "Normal:SnacksLazygitNormal",
              "NormalNC:SnacksLazygitNormal",
              "NormalFloat:SnacksLazygitNormal",
              "FloatBorder:SnacksLazygitBorder",
              "FloatTitle:SnacksLazygitBorder",
              "FloatFooter:SnacksLazygitBorder",
            }, ","),
          },
        },
      },
      -- snacks writes lazygit's theme from the colorscheme's highlight groups, not
      -- ~/Library/Application Support/lazygit/config.yml. Each block below mirrors
      -- its block there, so the float and a shell lazygit look the same; change
      -- one and change the other. Uncomment the one matching the colorscheme.

      -- Dark Modern (microsoft/vscode theme-defaults/themes/dark_modern.json; keys it
      -- leaves unset are VS Code's registered dark defaults)
      lazygit = {
        config = {
          gui = {
            theme = {
              activeBorderColor = { "#0078d4", "bold" }, -- tab.activeBorderTop
              inactiveBorderColor = { "#9d9d9d" }, -- descriptionForeground
              optionsTextColor = { "#4daafc" }, -- textLink.foreground
              selectedLineBgColor = { "#264f78" }, -- editor.selectionBackground
              inactiveViewSelectedLineBgColor = { "#37373d" }, -- list.inactiveSelectionBackground
              cherryPickedCommitBgColor = { "#37373d" }, -- tab.selectedBackground
              cherryPickedCommitFgColor = { "#e2c08d" }, -- gitDecoration.modifiedResourceForeground
              markedBaseCommitBgColor = { "#37373d" }, -- tab.selectedBackground
              markedBaseCommitFgColor = { "#3794ff" }, -- charts.blue
              unstagedChangesColor = { "#c74e39" }, -- gitDecoration.deletedResourceForeground
              defaultFgColor = { "#cccccc" }, -- terminal.foreground
              searchingActiveBorderColor = { "#e2c08d" }, -- gitDecoration.modifiedResourceForeground
            },
            -- The key has to carry its own quotes: snacks writes mapping keys to
            -- YAML verbatim, and a bare `*:` is an alias anchor, not a string.
            authorColors = { ['"*"'] = "#3794ff" }, -- charts.blue
          },
        },
      },

      -- Dark 2026
      -- lazygit = {
      --   config = {
      --     gui = {
      --       theme = {
      --         activeBorderColor = { "#3994bc", "bold" }, -- tab.activeBorderTop
      --         inactiveBorderColor = { "#8c8c8c" }, -- descriptionForeground
      --         optionsTextColor = { "#48a0c7" }, -- textLink.foreground
      --         selectedLineBgColor = { "#276782" }, -- editor.selectionBackground, opaque base
      --         inactiveViewSelectedLineBgColor = { "#2c2d2e" }, -- list.inactiveSelectionBackground
      --         cherryPickedCommitBgColor = { "#37373d" }, -- tab.selectedBackground
      --         cherryPickedCommitFgColor = { "#e5ba7d" }, -- gitDecoration.modifiedResourceForeground
      --         markedBaseCommitBgColor = { "#37373d" }, -- tab.selectedBackground
      --         markedBaseCommitFgColor = { "#57a3f8" }, -- charts.blue
      --         unstagedChangesColor = { "#f48771" }, -- gitDecoration.deletedResourceForeground
      --         defaultFgColor = { "#cccccc" }, -- terminal.foreground
      --         searchingActiveBorderColor = { "#e5ba7d" }, -- gitDecoration.modifiedResourceForeground
      --       },
      --       authorColors = { ['"*"'] = "#57a3f8" }, -- charts.blue
      --     },
      --   },
      -- },
    },
  },
}
