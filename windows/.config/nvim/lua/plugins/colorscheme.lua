local helpers = require("helpers")

return {
  -- {
  --   "folke/tokyonight.nvim",
  --   opts = {
  --     transparent = true,
  --     -- style = "storm",
  --     styles = {
  --       sidebars = "transparent",
  --       floats = "transparent",
  --     },
  --   },
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

  {
    "Mofiqul/dracula.nvim",
    opts = {
      transparent_bg = true,
    },
  },

  -- {
  --   "catppuccin/nvim",
  --   name = "catppuccin",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     -- background = {
  --     --   light = "latte",
  --     --   dark = "macchiato",
  --     -- },
  --     -- flavour = "auto",
  --     -- flavour = "macchiato",
  --     transparent_background = true,
  --   },
  -- },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
