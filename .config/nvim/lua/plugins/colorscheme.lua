local helpers = require("helpers")

return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      -- style = "storm",
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },

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
  --     -- vim.cmd("colorscheme github_dark_default")
  --   end,
  -- },

  {
    "Mofiqul/dracula.nvim",
    opts = {
      transparent_bg = false,
    },
  },

  -- {
  --   "rose-pine/neovim",
  --   name = "rose-pine",
  --   config = function()
  --     require("rose-pine").setup({
  --       variant = "auto",
  --       styles = {
  --         -- transparency = true,
  --       },
  --     })
  --
  --     vim.cmd("colorscheme rose-pine")
  --   end,
  -- },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      -- background = {
      --   light = "latte",
      --   dark = "mocha",
      -- },
      -- flavour = "auto",
      flavour = "mocha",
      -- transparent_background = true,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
