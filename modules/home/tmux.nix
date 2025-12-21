# ============================================================================
# TMUX - Terminal Multiplexer
# ============================================================================
#
# WHY TMUX?
# Tmux lets you:
#   - Split terminal into panes (side-by-side editing + testing)
#   - Create multiple windows (like browser tabs)
#   - Detach/reattach sessions (survive SSH disconnects)
#   - Share sessions between terminals
#
# KEY CONCEPTS:
#   Session → Window → Pane
#   - Session: A collection of windows (like a workspace)
#   - Window: A tab within a session
#   - Pane: A split within a window
#
# DEFAULT PREFIX: Ctrl+b (then press command key)
# After prefix: | = split horizontal, - = split vertical, hjkl = navigate
#
# ============================================================================

{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";   # Use Fish as tmux shell
    terminal = "tmux-256color";         # Enable 256 color support
    baseIndex = 1;                      # Start window numbering at 1 (not 0)
    escapeTime = 0;                     # No delay after pressing Escape (for vim)
    historyLimit = 50000;               # Scrollback buffer size
    mouse = true;                       # Enable mouse (scroll, click to select pane)
    keyMode = "vi";                     # Vi-style copy mode (v to select, y to yank)

    extraConfig = ''
      # =======================================================================
      # CLIPBOARD - Copy to system clipboard via OSC 52
      # =======================================================================
      # Ghostty handles OSC 52 and puts text in Wayland clipboard
      set -g set-clipboard on
      # When mouse-selecting text, auto-copy to clipboard and stay in copy mode
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel

      # =======================================================================
      # STATUS BAR
      # =======================================================================
      # Transparent status bar - shows windows only, no session name
      set -g status-style "bg=default"
      set -g status-left ""
      set -g status-right ""

      # =======================================================================
      # PANE SPLITTING
      # =======================================================================
      # More intuitive split keys (| is horizontal, - is vertical)
      # -c "#{pane_current_path}" keeps the same working directory
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # =======================================================================
      # PANE NAVIGATION (with prefix)
      # =======================================================================
      # Vim-style navigation: prefix + hjkl
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # =======================================================================
      # VIM-TMUX NAVIGATOR
      # =======================================================================
      # The magic: Ctrl+hjkl works seamlessly between vim and tmux!
      # When in vim: sends the key to vim for window navigation
      # When in tmux: switches tmux panes
      # Requires vim-tmux-navigator plugin in neovim (see nvim config)
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind-key -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
    '';
  };
}
