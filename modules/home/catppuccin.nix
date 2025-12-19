{ pkgs, ... }:

{
  # Global catppuccin settings
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "blue";
  };

  # Bat (needed for catppuccin theming)
  programs.bat.enable = true;

  # Per-program theming (inherits flavor from catppuccin.flavor)
  catppuccin.bat.enable = true;
  catppuccin.fish.enable = true;
  catppuccin.starship.enable = true;
  catppuccin.tmux.enable = true;
  catppuccin.ghostty.enable = true;
  catppuccin.waybar.enable = true;
  catppuccin.yazi.enable = true;
  catppuccin.hyprland.enable = true;
  catppuccin.mako.enable = true;  # Notifications

  # Qt theming
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
  catppuccin.kvantum.enable = true;
}
