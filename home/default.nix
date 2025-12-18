{ config, pkgs, lib, inputs, user, ... }:

{
  imports = [
    ../modules/home/hyprland.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = user.name;
  home.homeDirectory = "/home/${user.name}";

  # Packages installed to the user profile
  home.packages = with pkgs; [
    # CLI tools
    bat           # Better cat
    eza           # Better ls
    fzf           # Fuzzy finder
    jq            # JSON processor
    yq            # YAML processor
    lazygit       # Git TUI

    # Development
    nodejs_22     # For Claude Code, etc.
  ];

  # Git
  programs.git = {
    enable = true;
    userName = user.fullName;
    userEmail = user.email;
    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = false;  # Enable after SSH key setup
    };
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      gpg.format = "ssh";
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

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # State version
  home.stateVersion = "24.11";
}
