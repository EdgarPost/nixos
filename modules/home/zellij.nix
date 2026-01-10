# ============================================================================
# ZELLIJ - Terminal Multiplexer
# ============================================================================
#
# WHY ZELLIJ?
#   - Modern alternative to tmux with better defaults
#   - Built-in layout system and floating panes
#   - Session management with named sessions
#   - Discoverable keybindings (status bar hints)
#
# KEY CONCEPTS:
#   Session → Tab → Pane
#   - Session: Named workspace (e.g., per-project)
#   - Tab: Like browser tabs within a session
#   - Pane: Splits within a tab
#
# DEFAULT PREFIX: Ctrl+key (no prefix needed for most actions)
# Ctrl+p: Pane mode | Ctrl+t: Tab mode | Ctrl+n: Resize mode
#
# ============================================================================

{ pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    enableFishIntegration = false;  # Don't auto-start zellij in every shell

  };
}
