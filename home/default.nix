{ config, pkgs, lib, inputs, user, ... }:

{
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

  # Git (basic config, secrets added later)
  programs.git = {
    enable = true;
    # Email will be configured via SOPS later
    settings = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
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
