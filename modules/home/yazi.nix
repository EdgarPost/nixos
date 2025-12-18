{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
    };

    keymap = {
      manager.prepend_keymap = [
        # Open in $EDITOR
        { on = [ "e" ]; run = ''shell "$EDITOR $@" --block''; desc = "Edit in editor"; }
        # Quick navigation
        { on = [ "g" "h" ]; run = "cd ~"; desc = "Go home"; }
        { on = [ "g" "c" ]; run = "cd ~/.config"; desc = "Go to config"; }
        { on = [ "g" "d" ]; run = "cd ~/Downloads"; desc = "Go to downloads"; }
      ];
    };
  };

  # Catppuccin theming
  catppuccin.yazi.enable = true;
}
