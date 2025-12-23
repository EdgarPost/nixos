# ============================================================================
# GHOSTTY - GPU-Accelerated Terminal Emulator
# ============================================================================
#
# WHY GHOSTTY?
#   - GPU-accelerated rendering (smooth scrolling, low latency)
#   - Native Wayland support
#   - Custom shaders (the cursor smear effect!)
#   - Cross-platform (Linux, macOS)
#   - Modern defaults (true color, ligatures, etc.)
#
# TMUX INTEGRATION:
# This config automatically starts tmux for the first window, but opens
# a plain shell for additional windows. This gives you:
#   - Always-running tmux session ("main")
#   - Quick one-off terminals when needed
#
# ============================================================================

{ pkgs, font, ... }:

{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;  # Shell integration (title, current dir, etc.)

    settings = {
      # =======================================================================
      # APPEARANCE
      # =======================================================================
      font-family = font.family;
      font-size = font.size - 1;  # Slightly smaller than global default
      window-padding-x = 8;            # Pixels of padding inside window
      window-padding-y = 8;
      background-opacity = 0.9;        # Subtle transparency (blurred by Hyprland)

      # =======================================================================
      # BEHAVIOR
      # =======================================================================
      term = "xterm-256color";         # Compatibility for SSH to systems without ghostty terminfo
      shell-integration = "fish";      # Enable Fish-specific features
      gtk-single-instance = true;      # Reuse running instance (faster new windows)
      copy-on-select = "clipboard";    # Auto-copy selections to clipboard

      # =======================================================================
      # KEYBINDINGS
      # =======================================================================
      # CTRL+V for paste (standard, works with Hyprland clipboard history)
      # CTRL+SHIFT+V is captured by Hyprland for clipboard history picker
      keybind = "ctrl+v=paste:clipboard";

      # =======================================================================
      # CURSOR - Custom shader for macOS-like cursor smear effect
      # =======================================================================
      cursor-style = "block";
      cursor-style-blink = false;
      custom-shader = "~/.config/ghostty/shaders/cursor-smear.glsl";
      custom-shader-animation = true;  # Enable shader animations

      # =======================================================================
      # SMART TMUX INTEGRATION
      # =======================================================================
      # On first terminal: Create or attach to tmux session "main"
      # On subsequent terminals: Open plain fish shell
      #
      # Logic: If "main" session exists AND has clients attached, open fish
      #        Otherwise, create/attach to "main" session
      # This way you always have tmux, but can open quick terminals too
      command = "fish -c 'if tmux has-session -t main 2>/dev/null && test (tmux list-clients -t main | count) -gt 0; fish; else; tmux new-session -A -s main; end'";
    };
  };

  # ==========================================================================
  # CUSTOM SHADER
  # ==========================================================================
  # The cursor smear shader creates a trailing effect when the cursor moves
  # Symlink the GLSL shader to Ghostty's config directory
  xdg.configFile."ghostty/shaders/cursor-smear.glsl".source = ./ghostty/cursor-smear.glsl;
}
