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
      lazygit = {
        config = {
          gui = {
            theme = {
              activeBorderColor = { "#3994bc", "bold" }, -- tab.activeBorderTop
              inactiveBorderColor = { "#8c8c8c" }, -- descriptionForeground
              optionsTextColor = { "#48a0c7" }, -- textLink.foreground
              selectedLineBgColor = { "#276782" }, -- editor.selectionBackground, opaque base
              inactiveViewSelectedLineBgColor = { "#2c2d2e" }, -- list.inactiveSelectionBackground
              cherryPickedCommitBgColor = { "#37373d" }, -- tab.selectedBackground
              cherryPickedCommitFgColor = { "#e5ba7d" }, -- gitDecoration.modifiedResourceForeground
              markedBaseCommitBgColor = { "#37373d" }, -- tab.selectedBackground
              markedBaseCommitFgColor = { "#57a3f8" }, -- charts.blue
              unstagedChangesColor = { "#f48771" }, -- gitDecoration.deletedResourceForeground
              defaultFgColor = { "#cccccc" }, -- terminal.foreground
              searchingActiveBorderColor = { "#e5ba7d" }, -- gitDecoration.modifiedResourceForeground
            },
            authorColors = { ['"*"'] = "#57a3f8" }, -- charts.blue
          },
        },
      },
    },
  },
}
