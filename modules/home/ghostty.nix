{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      font-family = "JetBrains Mono";
      font-size = 13;
      window-padding-x = 8;
      window-padding-y = 8;
      shell-integration = "fish";
      gtk-single-instance = true;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;
      custom-shader = "~/.config/ghostty/shaders/cursor-smear.glsl";
      custom-shader-animation = true;

      # First window: attach/create tmux "main", subsequent windows: plain shell
      command = "fish -c 'if tmux has-session -t main 2>/dev/null && test (tmux list-clients -t main | count) -gt 0; fish; else; tmux new-session -A -s main; end'";
    };
  };

  # Cursor smear shader
  xdg.configFile."ghostty/shaders/cursor-smear.glsl".source = ./ghostty/cursor-smear.glsl;

  # Ensure font is available
  home.packages = with pkgs; [
    jetbrains-mono
  ];
}
