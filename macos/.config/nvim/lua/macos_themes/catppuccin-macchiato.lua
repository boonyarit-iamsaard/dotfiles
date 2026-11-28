-- Catppuccin Macchiato for lazygit opened from Neovim (LazyVim's <leader>gg).
--
-- snacks.nvim writes its lazygit theme from the colorscheme's highlight groups
-- and appends it to $LG_CONFIG_FILE, so it overrides the shell's theme. These
-- hexes are the ones in shared/themes/lazygit/catppuccin-macchiato.yml; change
-- one and change the other. macOS-only, so it stays out of shared/themes/nvim.

return {
  "folke/snacks.nvim",
  opts = {
    lazygit = {
      config = {
        gui = {
          theme = {
            activeBorderColor = { "#c6a0f6", "bold" },
            inactiveBorderColor = { "#a5adcb" },
            searchingActiveBorderColor = { "#eed49f" },
            optionsTextColor = { "#8aadf4" },
            selectedLineBgColor = { "#363a4f" },
            inactiveViewSelectedLineBgColor = { "#6e738d" },
            cherryPickedCommitFgColor = { "#c6a0f6" },
            cherryPickedCommitBgColor = { "#494d64" },
            markedBaseCommitFgColor = { "#8aadf4" },
            markedBaseCommitBgColor = { "#eed49f" },
            unstagedChangesColor = { "#ed8796" },
            defaultFgColor = { "#cad3f5" },
            -- Quoted key: a bare `*:` is a YAML alias, not a string.
            authorColors = { ['"*"'] = "#b7bdf8" },
          },
        },
      },
    },
  },
}
