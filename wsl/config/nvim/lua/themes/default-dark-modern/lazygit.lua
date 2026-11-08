-- Default Dark Modern for lazygit opened from Neovim (LazyVim's <leader>gg).
--
-- snacks.nvim derives a lazygit theme from the colorscheme's highlight groups
-- and appends it after $LG_CONFIG_FILE, so it overrides the shell theme. Under
-- vscode.nvim its defaults read groups that carry the wrong colors:
--
--   activeBorderColor         <- MatchParen.fg   nil      (bracket match is bg-only)
--   inactiveBorderColor       <- FloatBorder.fg  nil      (border has no fg)
--   optionsTextColor          <- Function.fg     #dcdcaa  (yellow, not the link blue)
--   cherryPickedCommitBgColor <- Identifier.fg   #9cdcfe  (near-white background)
--
-- snacks merges `config` over its derived theme per key, so the palette hexes
-- here win. Values mirror config/lazygit/themes/default-dark-modern.yml; change
-- one and change the other.

return {
  "folke/snacks.nvim",
  opts = {
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
  },
}
