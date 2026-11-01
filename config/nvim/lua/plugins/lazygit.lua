-- Theme overrides for lazygit opened from Neovim (LazyVim's <leader>gg).
--
-- LazyVim opens lazygit through snacks.nvim, which does NOT use your
-- ~/.config/lazygit/config.yml theme. On every ColorScheme event it writes
-- ~/.cache/nvim/lazygit-theme.yml, derived from the current colorscheme's
-- highlight groups, and appends it to $LG_CONFIG_FILE -- last file wins, so it
-- overrides whatever theme your own config sets.
--
-- Its defaults read groups that do not carry the right colors under Dark 2026:
--
--   activeBorderColor         <- MatchParen.fg   nil      (no accent at all)
--   optionsTextColor          <- Function.fg     #d2a8ff  (purple, not the link blue)
--   cherryPickedCommitBgColor <- Identifier.fg   #c9d1d9  (near-white background)
--
-- or under vscode.nvim (Dark Modern):
--
--   activeBorderColor         <- MatchParen.fg   nil      (bracket match is bg-only)
--   inactiveBorderColor       <- FloatBorder.fg  nil      (border has no fg)
--   optionsTextColor          <- Function.fg     #dcdcaa  (yellow, not the link blue)
--   cherryPickedCommitBgColor <- Identifier.fg   #9cdcfe  (near-white background)
--
-- snacks merges `config` over its derived theme per key, so setting the palette
-- hexes here wins. Every key is spelled out so nothing silently falls back.
--
-- Uncomment the block matching the active colorscheme. Each one mirrors its
-- block in config/lazygit/config.yml, so the float and a shell lazygit look the
-- same; change one and change the other.

return {
  -- Dark 2026 (values from dark-2026.nvim extras/lazygit/dark-2026.yml)
  -- "folke/snacks.nvim",
  -- opts = {
  --   lazygit = {
  --     config = {
  --       gui = {
  --         theme = {
  --           activeBorderColor = { "#3994bc", "bold" }, -- tab.activeBorderTop
  --           inactiveBorderColor = { "#8c8c8c" }, -- descriptionForeground
  --           optionsTextColor = { "#48a0c7" }, -- textLink.foreground
  --           selectedLineBgColor = { "#276782" }, -- editor.selectionBackground, opaque base
  --           inactiveViewSelectedLineBgColor = { "#2c2d2e" }, -- list.inactiveSelectionBackground
  --           cherryPickedCommitBgColor = { "#37373d" },
  --           cherryPickedCommitFgColor = { "#e5ba7d" }, -- gitDecoration.modifiedResourceForeground
  --           markedBaseCommitBgColor = { "#37373d" },
  --           markedBaseCommitFgColor = { "#57a3f8" }, -- charts.blue
  --           unstagedChangesColor = { "#f48771" }, -- gitDecoration.deletedResourceForeground
  --           defaultFgColor = { "#cccccc" }, -- terminal.foreground
  --           searchingActiveBorderColor = { "#e5ba7d" },
  --           -- The key has to carry its own quotes: snacks writes mapping keys to
  --           -- YAML verbatim, and a bare `*:` is an alias anchor, not a string.
  --           authorColors = { ['"*"'] = "#57a3f8" }, -- charts.blue
  --         },
  --       },
  --     },
  --   },
  -- },

  -- Dark Modern (microsoft/vscode theme-defaults/themes/dark_modern.json; keys it
  -- leaves unset are VS Code's registered dark defaults)
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
            authorColors = { ['"*"'] = "#3794ff" }, -- charts.blue
          },
        },
      },
    },
  },
}
