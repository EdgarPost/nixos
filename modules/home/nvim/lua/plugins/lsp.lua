-- LSP configuration for Nix-installed servers
return {
  {
    "neovim/nvim-lspconfig",
    -- Load on VimEnter too so LSP starts without opening a file
    event = { "LazyFile", "VimEnter" },
    opts = {
      servers = {
        -- Servers installed via Nix (in nvim.nix)
        lua_ls = {},
        nil_ls = {},  -- Nix LSP
        vtsls = {},
        html = {},
        cssls = {},
        jsonls = {},
      },
    },
  },
}
