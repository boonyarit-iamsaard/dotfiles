-- Keep Prettier to the file types Biome can't handle (Markdown, YAML, ...).
--
-- LazyVim's prettier and biome extras each append their formatter to
-- `formatters_by_ft`, and conform runs a list *sequentially* -- so in a repo
-- that has both a biome.json and a Prettier config, TS/JSON/CSS buffers get
-- formatted twice and Prettier, running last, wins. The editor then stops
-- agreeing with whatever the project's own `biome check` produces.
--
-- The `lazyvim_prettier_needs_config` guard doesn't help here: a repo-root
-- Prettier config resolves for *every* file in the repo, including the ones
-- Biome owns.

-- https://biomejs.dev/internals/language-support/
local biome_filetypes = {
  astro = true,
  css = true,
  graphql = true,
  javascript = true,
  javascriptreact = true,
  json = true,
  jsonc = true,
  scss = true,
  svelte = true,
  typescript = true,
  typescriptreact = true,
  vue = true,
}

---@param ctx {buf: number, filename: string, dirname: string}
local function biome_owns(ctx)
  if not biome_filetypes[vim.bo[ctx.buf].filetype] then
    return false
  end
  local found = vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.dirname, upward = true })
  return found[1] ~= nil
end

return {
  {
    "stevearc/conform.nvim",
    optional = true,
    ---@param opts conform.setupOpts
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters.prettier = opts.formatters.prettier or {}

      -- Wrap, don't replace: the prettier extra's condition still enforces
      -- `lazyvim_prettier_needs_config` and the has-a-parser check.
      local inherited = opts.formatters.prettier.condition
      opts.formatters.prettier.condition = function(self, ctx)
        if biome_owns(ctx) then
          return false
        end
        return inherited == nil or inherited(self, ctx)
      end
    end,
  },
}
