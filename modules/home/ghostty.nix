{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      # Font
      font-family = "JetBrains Mono";
      font-size = 13;

      # Window
      window-padding-x = 8;
      window-padding-y = 8;

      # Shell integration
      shell-integration = "fish";

      # Disable because we're on Wayland
      gtk-single-instance = true;
    };
  };

  # Ensure font is available
  home.packages = with pkgs; [
    jetbrains-mono
  ];
}
