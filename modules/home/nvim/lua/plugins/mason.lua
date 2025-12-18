-- Disable Mason (we use Nix for LSPs/formatters)
return {
  { "williamboman/mason.nvim", enabled = false },
  { "williamboman/mason-lspconfig.nvim", enabled = false },
}
