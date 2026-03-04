# ============================================================================
# ZATHURA - Lightweight PDF Viewer
# ============================================================================
#
# WHY ZATHURA?
# Minimal, keyboard-driven PDF viewer with vim-like keybindings:
#   - Fast startup, low resource usage
#   - Vim-like navigation (j/k, gg/G, /, etc.)
#   - Recoloring support (dark mode via catppuccin)
#   - Automatic reload on file change
#
# NAVIGATION:
#   j/k         - Scroll down/up
#   h/l         - Scroll left/right
#   gg/G        - Go to first/last page
#   /           - Search
#   +/-         - Zoom in/out
#   a           - Fit page (auto zoom)
#   s           - Fit width
#   r           - Rotate
#   q           - Quit
#
# ============================================================================

{ pkgs, ... }:

{
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard"; # Yank to system clipboard
    };
  };

  # Set as default PDF viewer
  xdg.mimeApps.defaultApplications = {
    "application/pdf" = "org.pwmt.zathura.desktop";
  };
}
