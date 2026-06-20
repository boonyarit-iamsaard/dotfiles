-- local helpers = require("helpers")

return {
  -- {
  --   "folke/tokyonight.nvim",
  --   opts = {
  --     -- transparent = true,
  --     style = "moon",
  --     -- styles = {
  --     --   sidebars = "transparent",
  --     --   floats = "transparent",
  --     -- },
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
  --   "Mofiqul/dracula.nvim",
  --   opts = {
  --     transparent_bg = false,
  --   },
  -- },

  -- {
  --   "navarasu/onedark.nvim",
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     require("onedark").setup({
  --       style = "dark",
  --     })
  --     require("onedark").load()
  --   end,
  -- },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require("catppuccin").setup({
        -- background = {
        --   light = "latte",
        --   dark = "macchiato",
        -- },
        flavour = "mocha",
        -- flavour = "auto",
        -- transparent_background = true,
      })
    end,
  },

  {
    "Mofiqul/vscode.nvim",
    priority = 1000,
    -- config = function()
    --   require("vscode").setup({
    --     transparent = true,
    --   })
    -- end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "catppuccin-mocha",
      colorscheme = "vscode",
    },
  },
}
