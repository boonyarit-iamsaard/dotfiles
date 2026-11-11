local function set_transparent_lazygit_highlights()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local border = vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false })

  normal.bg = "NONE"
  border.bg = "NONE"

  vim.api.nvim_set_hl(0, "SnacksLazygitNormal", normal)
  vim.api.nvim_set_hl(0, "SnacksLazygitBorder", border)
end

return {
  {
    "snacks.nvim",
    opts = {
      indent = { enabled = false },
      styles = {
        lazygit = {
          backdrop = false,
          on_win = set_transparent_lazygit_highlights,
          wo = {
            winhighlight = table.concat({
              "Normal:SnacksLazygitNormal",
              "NormalNC:SnacksLazygitNormal",
              "NormalFloat:SnacksLazygitNormal",
              "FloatBorder:SnacksLazygitBorder",
              "FloatTitle:SnacksLazygitBorder",
              "FloatFooter:SnacksLazygitBorder",
            }, ","),
          },
        },
      },
    },
  },
}
