-- Disable Mason (we use Nix for LSPs/formatters)
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
}
