-- local helpers = require("helpers")

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
  --   "sainnhe/edge",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     -- Optionally configure and load the colorscheme
  --     -- directly inside the plugin declaration.
  --     vim.g.edge_enable_italic = true
  --     vim.cmd.colorscheme("edge")
  --   end,
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
  --     local theme = appearance == "light" and "github_light" or "github_dark_dimmed"
  --     vim.cmd("colorscheme " .. theme)
  --     -- vim.cmd("colorscheme github_dark_dimmed")
  --   end,
  -- },

  {
    "Mofiqul/dracula.nvim",
    opts = {
      transparent_bg = false,
    },
  },

  -- {
  --   "olimorris/onedarkpro.nvim",
  --   priority = 1000, -- Ensure it loads first
  --   config = function()
  --     require("onedarkpro").setup({
  --       --
  --     })
  --
  --     -- local appearance = helpers.get_macos_appearance()
  --     -- local theme = appearance == "light" and "github_light" or "github_dark_dimmed"
  --     -- vim.cmd("colorscheme " .. theme)
  --     if vim.o.background == "dark" then
  --       vim.cmd("colorscheme onelight")
  --     else
  --       vim.cmd("colorscheme onedark")
  --     end
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
      flavour = "macchiato",
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
