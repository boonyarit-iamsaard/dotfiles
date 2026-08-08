-- Dark 2026 — a Neovim port of the VS Code theme in dark-2026.jsonc.
--
-- Usage:  :colorscheme dark-2026
--         require("dark-2026").setup({ transparent = true })

local M = {}

---@class Dark2026Config
---@field transparent boolean Skip backgrounds on the editor and panel surfaces.
---@field italic_comments boolean
---@field on_highlights fun(hl: table, p: table)|nil Last-word override hook.
local defaults = {
  transparent = false,
  italic_comments = true,
  on_highlights = nil,
}

M.config = vim.deepcopy(defaults)

---@param opts Dark2026Config|nil
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

--- Build the full highlight table without applying it.
---@return table<string, vim.api.keyset.highlight>, table palette
function M.highlights()
  local p = require("dark-2026.palette")
  local cfg = M.config

  local hl = {}
  for _, mod in ipairs({ "editor", "syntax", "lsp", "plugins" }) do
    for group, spec in pairs(require("dark-2026.groups." .. mod)(p)) do
      hl[group] = spec
    end
  end

  if not cfg.italic_comments then
    for _, group in ipairs({ "Comment", "@comment", "@comment.documentation", "SpecialComment" }) do
      hl[group] = vim.tbl_extend("force", hl[group] or {}, { italic = false })
    end
  end

  if cfg.transparent then
    -- Only the groups that paint a full-window surface; floats and popups keep
    -- their backgrounds so they stay legible over whatever is behind them.
    for _, group in ipairs({
      "Normal",
      "NormalNC",
      "SignColumn",
      "FoldColumn",
      "EndOfBuffer",
      "NeoTreeNormal",
      "NeoTreeNormalNC",
      "NeoTreeEndOfBuffer",
      "TroubleNormal",
      "TroubleNormalNC",
    }) do
      if hl[group] then
        hl[group].bg = "NONE"
      end
    end
  end

  if cfg.on_highlights then
    cfg.on_highlights(hl, p)
  end

  return hl, p
end

function M.load()
  if vim.g.colors_name then
    vim.cmd.hi("clear")
  end
  -- Filetypes without a Treesitter parser still fall back to the legacy syntax
  -- engine, whose groups need resetting alongside the highlight table.
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true
  vim.g.colors_name = "dark-2026"
  vim.o.background = "dark"

  local hl, p = M.highlights()
  local set = vim.api.nvim_set_hl
  for group, spec in pairs(hl) do
    set(0, group, spec)
  end

  -- :terminal palette. dark-2026.jsonc leaves terminal.ansi* commented out, so
  -- these are VS Code's fallback defaults — the same 16 values the Windows
  -- Terminal scheme uses.
  local a = p.ansi
  local slots = {
    a.black,
    a.red,
    a.green,
    a.yellow,
    a.blue,
    a.magenta,
    a.cyan,
    a.white,
    a.bright_black,
    a.bright_red,
    a.bright_green,
    a.bright_yellow,
    a.bright_blue,
    a.bright_magenta,
    a.bright_cyan,
    a.bright_white,
  }
  for i, color in ipairs(slots) do
    vim.g["terminal_color_" .. (i - 1)] = color
  end
end

return M
