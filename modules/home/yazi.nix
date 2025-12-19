# ============================================================================
# YAZI - Terminal File Manager
# ============================================================================
#
# WHY YAZI?
# A modern TUI file manager written in Rust:
#   - Fast (async I/O, instant startup)
#   - Image preview in terminal (with supported terminals)
#   - Vim-like keybindings
#   - Highly customizable
#
# NAVIGATION:
#   h/l         - Navigate up/into directories
#   j/k         - Move cursor up/down
#   gg/G        - Go to top/bottom
#   <Enter>     - Open file/directory
#   <Space>     - Toggle selection
#   q           - Quit
#
# CUSTOM KEYBINDINGS (defined below):
#   e           - Edit file in $EDITOR
#   gh          - Go to home directory
#   gc          - Go to ~/.config
#   gd          - Go to ~/Downloads
#
# ============================================================================

{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;  # `y` shell function to cd on exit

    settings = {
      manager = {
        show_hidden = true;      # Show dotfiles by default
        sort_by = "natural";     # Natural sort (file1, file2, file10)
        sort_dir_first = true;   # Directories before files
      };
    };

    # CUSTOM KEYBINDINGS
    # prepend_keymap: Add before defaults (takes priority)
    # Syntax: on = key sequence, run = action, desc = description
    keymap = {
      manager.prepend_keymap = [
        # Quick edit: press 'e' to open file in editor
        { on = [ "e" ]; run = ''shell "$EDITOR $@" --block''; desc = "Edit in editor"; }

        # Go-to shortcuts (like vim marks, but for directories)
        { on = [ "g" "h" ]; run = "cd ~"; desc = "Go home"; }
        { on = [ "g" "c" ]; run = "cd ~/.config"; desc = "Go to config"; }
        { on = [ "g" "d" ]; run = "cd ~/Downloads"; desc = "Go to downloads"; }
      ];
    };
  };

  # Theme is set in catppuccin.nix (catppuccin.yazi.enable = true)
  # Duplicated here for clarity - the module handles deduplication
  catppuccin.yazi.enable = true;
}
