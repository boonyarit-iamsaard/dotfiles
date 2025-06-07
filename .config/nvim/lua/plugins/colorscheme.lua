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

  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({
        --
      })

      -- local appearance = helpers.get_macos_appearance()
      -- local theme = appearance == "light" and "github_light_default" or "github_dark_default"
      -- vim.cmd("colorscheme " .. theme)
    end,
  },

  {
    "Mofiqul/dracula.nvim",
    opts = {
      transparent_bg = true,
    },
  },

  -- {
  --   "oxfist/night-owl.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("night-owl").setup({
  --       bold = true,
  --       italics = true,
  --       underline = true,
  --       undercurl = true,
  --       transparent_background = true,
  --     })
  --     -- vim.cmd.colorscheme("night-owl")
  --   end,
  -- },

  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      require("rose-pine").setup({
        variant = "main",
        styles = {
          transparency = true,
        },
      })
      -- vim.cmd("colorscheme rose-pine")
    end,
  },

  -- {
  --   "rebelot/kanagawa.nvim",
  --   config = function()
  --     require("kanagawa").setup({
  --       compile = false,
  --       undercurl = true,
  --       commentStyle = { italic = true },
  --       functionStyle = {},
  --       keywordStyle = { italic = true },
  --       statementStyle = { bold = true },
  --       typeStyle = {},
  --       transparent = true,
  --       dimInactive = false,
  --       terminalColors = true,
  --       colors = {
  --         palette = {},
  --         theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
  --       },
  --       overrides = function(_)
  --         return {}
  --       end,
  --       theme = "wave",
  --       background = {
  --         dark = "wave",
  --         light = "lotus",
  --       },
  --     })
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
      --   dark = "macchiato",
      -- },
      -- flavour = "auto",
      -- flavour = "macchiato",
      transparent_background = true,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
