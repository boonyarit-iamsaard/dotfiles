return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.inlay_hints.enabled = false
      opts.servers["*"].capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        opts.servers["*"].capabilities or {}
      )
      opts.setup.gopls = function() end
    end,
  },
}
