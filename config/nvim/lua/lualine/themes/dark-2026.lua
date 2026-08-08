-- lualine theme for Dark 2026.
--
-- lualine's `theme = "auto"` looks for lualine.themes.<vim.g.colors_name>
-- before falling back to deriving one from highlight groups, so putting this
-- here is enough — LazyVim's lualine spec needs no change.
--
-- Mirrors VS Code's status bar: a flat #191a1b strip with muted text, and the
-- accent reserved for the mode indicator.

local p = require("dark-2026.palette")

local function mode(color)
  return { fg = p.on_accent, bg = color, gui = "bold" }
end

return {
  normal = {
    a = mode(p.accent_dim), -- statusBarItem.remoteBackground family
    b = { fg = p.fg_ui, bg = p.bg_line },
    c = { fg = p.fg_dim, bg = p.bg_panel },
  },
  insert = {
    a = mode(p.git_add),
    b = { fg = p.fg_ui, bg = p.bg_line },
    c = { fg = p.fg_dim, bg = p.bg_panel },
  },
  visual = {
    a = mode(p.purple),
    b = { fg = p.fg_ui, bg = p.bg_line },
    c = { fg = p.fg_dim, bg = p.bg_panel },
  },
  replace = {
    a = mode(p.error),
    b = { fg = p.fg_ui, bg = p.bg_line },
    c = { fg = p.fg_dim, bg = p.bg_panel },
  },
  command = {
    a = mode(p.git_change),
    b = { fg = p.fg_ui, bg = p.bg_line },
    c = { fg = p.fg_dim, bg = p.bg_panel },
  },
  terminal = {
    a = mode(p.link),
    b = { fg = p.fg_ui, bg = p.bg_line },
    c = { fg = p.fg_dim, bg = p.bg_panel },
  },
  inactive = {
    a = { fg = p.fg_disabled, bg = p.bg_panel },
    b = { fg = p.fg_disabled, bg = p.bg_panel },
    c = { fg = p.fg_disabled, bg = p.bg_panel },
  },
}
