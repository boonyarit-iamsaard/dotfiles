-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- local helpers = require("helpers")

-- Set initial background based on macOS appearance
-- vim.o.background = helpers.get_macos_appearance()

-- Add command to manually toggle background
-- vim.api.nvim_create_user_command("ToggleBackground", function()
--   vim.o.background = vim.o.background == "dark" and "light" or "dark"
-- end, {})

-- Optional: Check for appearance changes periodically
-- vim.api.nvim_create_autocmd("VimEnter", {
--   callback = function()
--     vim.fn.timer_start(5000, function()
--       vim.o.background = helpers.get_macos_appearance()
--     end, { ["repeat"] = -1 })
--   end,
-- })
