{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Dependencies (LSPs, formatters managed by Nix, not Mason)
    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server
      nil  # Nix LSP
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted  # HTML, CSS, JSON, ESLint

      # Formatters
      stylua
      nixfmt-rfc-style
      prettierd

      # Tools needed by plugins
      ripgrep
      fd
      gcc  # For treesitter compilation
      tree-sitter
    ];
  };

  # Lua config lives in ~/.config/nvim
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
