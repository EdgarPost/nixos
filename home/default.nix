{ config, pkgs, lib, inputs, user, ... }:

{
  imports = [
    ../modules/home/hyprland.nix
    ../modules/home/ghostty.nix
    ../modules/home/atuin.nix
    ../modules/home/tmux.nix
    ../modules/home/catppuccin.nix
    ../modules/home/waybar.nix
    ../modules/home/yazi.nix
    ../modules/home/nvim.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = user.name;
  home.homeDirectory = "/home/${user.name}";

  # Packages installed to the user profile
  home.packages = with pkgs; [
    # CLI tools
    eza           # Better ls
    fzf           # Fuzzy finder
    jq            # JSON processor
    yq            # YAML processor
    lazygit       # Git TUI

    # Development
    nodejs_22
    claude-code   # AI coding assistant

    # Browser - Zen supports both x86_64 and aarch64
    inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
  ] ++ lib.optionals (stdenv.hostPlatform.system == "x86_64-linux") [
    # x86_64-only apps (no aarch64 Linux builds available)
    slack
  ];

  # Git
  programs.git = {
    enable = true;
    settings = {
      user.name = user.fullName;
      user.email = user.email;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      gpg.format = "ssh";
      user.signingKey = "~/.ssh/id_ed25519.pub";
      commit.gpgSign = false;  # Enable after SSH key setup
    };
  };

  # Fish shell
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting  # Disable greeting
    '';
    shellAliases = {
      ll = "eza -la";
      la = "eza -a";
      cat = "bat";
      n = "nvim";
      lg = "lazygit";
      g = "git";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  # Cursor theme (macOS-style)
  home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor;
    size = 24;
    gtk.enable = true;
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # State version
  home.stateVersion = "24.11";
}
