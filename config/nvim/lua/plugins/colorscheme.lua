-- local helpers = require("helpers")

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

  -- {
  --   "rose-pine/neovim",
  --   name = "rose-pine",
  -- },

  -- {
  --   "Mofiqul/dracula.nvim",
  --   opts = {
  --     transparent_bg = false,
  --   },
  -- },

  -- {
  --   "oxfist/night-owl.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("night-owl").setup()
  --     vim.cmd.colorscheme("night-owl")
  --   end,
  -- },

  -- {
  --   "sainnhe/gruvbox-material",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     -- Optionally configure and load the colorscheme
  --     -- directly inside the plugin declaration.
  --     vim.g.gruvbox_material_enable_italic = true
  --     vim.g.gruvbox_material_background = "hard"
  --     -- vim.g.gruvbox_material_ui_contrast = "high"
  --     vim.cmd.colorscheme("gruvbox-material")
  --   end,
  -- },

  {
    "Mofiqul/vscode.nvim",
  },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      -- Fix LazyVim's bufferline integration
      local bufferline_integration = require("catppuccin.groups.integrations.bufferline")
      if not bufferline_integration.get then
        bufferline_integration.get = bufferline_integration.get_theme
      end

      ---@diagnostic disable-next-line: missing-fields
      require("catppuccin").setup({
        -- background = {
        --   light = "latte",
        --   dark = "macchiato",
        -- },
        -- flavour = "auto",
        -- flavour = "macchiato",
        -- transparent_background = true,
      })
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vscode",
    },
  },
}
