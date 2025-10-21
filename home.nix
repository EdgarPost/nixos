# Home Manager configuration for user edgar
# Home Manager manages user-specific packages and dotfiles
# Think of this as your personal environment configuration

{ config, pkgs, ... }:

{
  # Home Manager needs to know your username and home directory
  home.username = "edgar";
  home.homeDirectory = "/home/edgar";

  # DO NOT CHANGE THIS! This tracks which version of Home Manager you started with
  home.stateVersion = "24.05";

  # User-specific packages
  # These are only available to this user
  home.packages = with pkgs; [
    # Development tools
    lazygit          # Terminal UI for git
    fzf              # Fuzzy finder
    ripgrep          # Fast search (rg command)
    yq               # YAML processor
    jq               # JSON processor

    # Communication
    slack            # Team communication

    # Terminal utilities
    tmux             # Terminal multiplexer
    eza              # Modern replacement for ls
    bat              # Better cat with syntax highlighting
    fd               # Better find
    bottom           # System monitor

    # Wayland/GUI applications
    alacritty        # Terminal emulator
    fuzzel           # Application launcher
    waybar           # Status bar
    pavucontrol      # Audio control

    # Fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
  ];

  # Program configurations
  # Home Manager can manage program configs declaratively
  programs = {
    # Let Home Manager manage itself
    home-manager.enable = true;

    # Git configuration
    git = {
      enable = true;
      userName = "Edgar Post-Buijs";
      userEmail = "edgar@example.com";  # UPDATE THIS!
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
      };
    };

    # Fish shell configuration
    fish = {
      enable = true;
      # Fish config is in separate file for organization
      interactiveShellInit = builtins.readFile ./config/fish.fish;
    };

    # Starship prompt
    starship = {
      enable = true;
      # Starship config is in separate file
      # We use enableFishIntegration to automatically set it up with fish
      enableFishIntegration = true;
    };

    # Tmux configuration
    tmux = {
      enable = true;
      # Use fish as the default shell in tmux
      shell = "${pkgs.fish}/bin/fish";
      # Enable 24-bit color support
      terminal = "screen-256color";
      # Escape time (lower is better for vim)
      escapeTime = 0;
      # Start window numbering at 1
      baseIndex = 1;
      # Enable mouse support
      mouse = true;
      # Additional tmux config
      extraConfig = builtins.readFile ./config/tmux.conf;
    };

    # Neovim with LazyVim
    neovim = {
      enable = true;
      defaultEditor = true;  # Set as default editor (EDITOR env var)
      viAlias = true;        # Create 'vi' alias
      vimAlias = true;       # Create 'vim' alias

      # Install some essential plugins
      # LazyVim will manage most plugins itself
      plugins = with pkgs.vimPlugins; [
        lazy-nvim        # LazyVim plugin manager
      ];

      # Neovim config will be in ~/.config/nvim
      # We'll create LazyVim setup separately
    };

    # Direnv for automatic environment loading
    # Very useful when working with nix-shell!
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  # Dotfiles and configuration directories
  # This creates files in ~/.config/
  xdg.configFile = {
    # Neovim LazyVim configuration
    "nvim/init.lua".source = ./config/nvim/init.lua;
    "nvim/lua/config/lazy.lua".source = ./config/nvim/lua/config/lazy.lua;
    "nvim/lua/config/options.lua".source = ./config/nvim/lua/config/options.lua;
    "nvim/lua/config/keymaps.lua".source = ./config/nvim/lua/config/keymaps.lua;

    # Starship configuration
    "starship.toml".source = ./config/starship.toml;

    # Niri configuration
    "niri/config.kdl".source = ./config/niri/config.kdl;

    # Waybar configuration
    "waybar/config".source = ./config/waybar/config;
    "waybar/style.css".source = ./config/waybar/style.css;

    # Swaylock configuration
    "swaylock/config".source = ./config/swaylock/config;

    # Alacritty configuration
    "alacritty/alacritty.toml".source = ./config/alacritty.toml;
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    # Tell electron apps to use Wayland
    NIXOS_OZONE_WL = "1";
  };
}
