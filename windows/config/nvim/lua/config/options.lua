-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- if vim.fn.has("wsl") == 1 then
--   vim.g.clipboard = {
--     name = "WslClipboard",
--     copy = {
--       ["+"] = "clip.exe",
--       ["*"] = "clip.exe",
--     },
--     past = {
--       ["+"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
--       ["*"] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
--     },
--     cache_endbled = 0,
--   }
-- end

-- local path = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0///powershell.exe",
-- local path = "/mnt/c/Users/boony/AppData/Local/Microsoft/WindowsApps/pwsh.exe"
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = { "clip.exe" },
      ["*"] = { "clip.exe" },
    },
    paste = {
      ["+"] = {
        "/mnt/c/Windows/System32/WindowsPowerShell/v1.0///powershell.exe",
        "-c",
        '[Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      },
      ["*"] = {
        "/mnt/c/Windows/System32/WindowsPowerShell/v1.0///powershell.exe",
        "-c",
        '[Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      },
    },
    cache_enabled = false,
  }
end

local opt = vim.opt

opt.relativenumber = false
