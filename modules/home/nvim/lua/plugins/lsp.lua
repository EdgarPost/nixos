-- LSP configuration for Nix-installed servers
return {
  {
    "neovim/nvim-lspconfig",
    -- Load on VimEnter too so LSP starts without opening a file
    event = { "LazyFile", "VimEnter" },
    opts = {
      inlay_hints = { enabled = false },
      servers = {
        -- Servers installed via Nix (in nvim.nix)
        lua_ls = {},
        nil_ls = {},  -- Nix LSP
        html = {},
        cssls = {},
        jsonls = {},
      },
    },
  },
}
