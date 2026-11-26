-- Catppuccin Mocha for lazygit opened from Neovim (LazyVim's <leader>gg).
--
-- snacks.nvim writes its lazygit theme from the colorscheme's highlight groups
-- and appends it to $LG_CONFIG_FILE, so it overrides the shell's Mocha theme.
-- These hexes are the ones in shared/themes/lazygit/catppuccin-mocha.yml; change
-- one and change the other.

return {
  "folke/snacks.nvim",
  opts = {
    lazygit = {
      config = {
        gui = {
          theme = {
            activeBorderColor = { "#cba6f7", "bold" },
            inactiveBorderColor = { "#a6adc8" },
            searchingActiveBorderColor = { "#f9e2af" },
            optionsTextColor = { "#89b4fa" },
            selectedLineBgColor = { "#313244" },
            inactiveViewSelectedLineBgColor = { "#6c7086" },
            cherryPickedCommitFgColor = { "#cba6f7" },
            cherryPickedCommitBgColor = { "#45475a" },
            markedBaseCommitFgColor = { "#89b4fa" },
            markedBaseCommitBgColor = { "#f9e2af" },
            unstagedChangesColor = { "#f38ba8" },
            defaultFgColor = { "#cdd6f4" },
            -- Quoted key: a bare `*:` is a YAML alias, not a string.
            authorColors = { ['"*"'] = "#b4befe" },
          },
        },
      },
    },
  },
}
