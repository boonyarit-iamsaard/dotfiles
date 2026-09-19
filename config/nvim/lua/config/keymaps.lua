-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Sort lines (visual mode), à la the VS Code sort-lines extension.
-- `:sort` covers most of it; the rest go through a comparator helper.
local function transform_lines(fn)
  return function()
    -- leave visual mode so the '< '> marks are set
    vim.cmd("normal! \27")
    local first = vim.fn.line("'<")
    local last = vim.fn.line("'>")
    local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
    fn(lines)
    vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
  end
end

local map = vim.keymap.set

map("x", "<leader>S", "", { desc = "+sort" })
map("x", "<leader>Sa", ":sort<CR>", { desc = "Ascending", silent = true })
map("x", "<leader>Sd", ":sort!<CR>", { desc = "Descending", silent = true })
map("x", "<leader>Si", ":sort i<CR>", { desc = "Ascending (case insensitive)", silent = true })
map("x", "<leader>SI", ":sort! i<CR>", { desc = "Descending (case insensitive)", silent = true })
map("x", "<leader>Su", ":sort u<CR>", { desc = "Unique", silent = true })
map("x", "<leader>SU", ":sort! u<CR>", { desc = "Unique (descending)", silent = true })
map("x", "<leader>Sn", ":sort n<CR>", { desc = "Natural / numeric", silent = true })
map("x", "<leader>Sr", transform_lines(function(lines)
  for i = 1, math.floor(#lines / 2) do
    lines[i], lines[#lines - i + 1] = lines[#lines - i + 1], lines[i]
  end
end), { desc = "Reverse" })
map("x", "<leader>Sl", transform_lines(function(lines)
  table.sort(lines, function(a, b)
    if #a == #b then
      return a < b
    end
    return #a < #b
  end)
end), { desc = "Line length" })
map("x", "<leader>SL", transform_lines(function(lines)
  table.sort(lines, function(a, b)
    if #a == #b then
      return a > b
    end
    return #a > #b
  end)
end), { desc = "Line length (descending)" })
map("x", "<leader>Ss", transform_lines(function(lines)
  for i = #lines, 2, -1 do
    local j = math.random(i)
    lines[i], lines[j] = lines[j], lines[i]
  end
end), { desc = "Shuffle" })
