# ============================================================================
# NEOVIM - Text Editor Configuration
# ============================================================================
#
# NIX-MANAGED DEPENDENCIES vs MASON:
# Traditional Neovim setups use Mason.nvim to install LSPs and formatters
# at runtime. This config uses Nix instead because:
#   1. Reproducible - same versions everywhere
#   2. No runtime downloads - works offline
#   3. Version-locked in flake.lock
#   4. Nix-native tools (nil for Nix LSP) work better
#
# The actual Lua config lives in ./nvim/ and is symlinked to ~/.config/nvim
# This file just handles:
#   - Installing neovim
#   - Making external tools (LSPs, formatters) available on PATH
#   - Symlinking the Lua config
#
# ============================================================================

{ pkgs, ... }:

{
  # Shell alias for quick access
  programs.fish.shellAliases.n = "nvim";

  programs.neovim = {
    enable = true;
    defaultEditor = true;  # Set $EDITOR to nvim
    viAlias = true;        # `vi` command runs nvim
    vimAlias = true;       # `vim` command runs nvim

    # EXTERNAL DEPENDENCIES
    # These are added to neovim's PATH, not system PATH
    # Neovim plugins can find them, but they don't pollute your shell
    extraPackages = with pkgs; [
      # =====================================================================
      # LSP SERVERS - Language intelligence (autocomplete, go-to-definition)
      # =====================================================================
      lua-language-server                     # Lua (for neovim config)
      nil                                      # Nix (NixOS-native, better than rnix)
      nodePackages.typescript-language-server  # TypeScript/JavaScript
      nodePackages.vscode-langservers-extracted # HTML, CSS, JSON, ESLint (from VS Code)

      # =====================================================================
      # FORMATTERS - Code formatting on save
      # =====================================================================
      stylua           # Lua formatter
      nixfmt-rfc-style # Nix formatter (follows RFC style guide)
      prettierd        # JS/TS/HTML/CSS formatter (daemon mode = fast)

      # =====================================================================
      # PLUGIN DEPENDENCIES - Tools needed by Neovim plugins
      # =====================================================================
      ripgrep     # telescope.nvim live grep
      fd          # telescope.nvim file finder
      gcc         # treesitter needs a C compiler for parser compilation
      tree-sitter # treesitter CLI for :TSInstall
    ];
  };

  # ==========================================================================
  # LUA CONFIGURATION
  # ==========================================================================
  # Symlink ./nvim/ directory to ~/.config/nvim/
  #
  # xdg.configFile is Home Manager's way to manage ~/.config/ files
  # recursive = true: symlink contents, not the directory itself
  # This allows nvim to write to subdirs (like lazy-lock.json)
  xdg.configFile."nvim" = {
    source = ./nvim;       # Relative to this .nix file
    recursive = true;
  };
}
