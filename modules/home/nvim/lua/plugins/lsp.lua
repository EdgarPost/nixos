-- LSP configuration for Nix-installed servers
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Servers installed via Nix (in nvim.nix)
        lua_ls = {},
        nil_ls = {},  -- Nix LSP
        ts_ls = {},
        html = {},
        cssls = {},
        jsonls = {},
      },
    },
  },
}
