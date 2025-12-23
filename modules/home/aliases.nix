# ============================================================================
# SHARED SHELL ALIASES - Common shortcuts for desktop and server
# ============================================================================
#
# WHY A SEPARATE MODULE?
# These aliases are used in both desktop (home/default.nix) and server
# (home/server.nix) configurations. Extracting them avoids duplication
# and ensures consistency across environments.
#
# MODULE-SPECIFIC ALIASES:
# Some modules define their own aliases (e.g., openstack.nix has `os`).
# Those stay in their modules to keep related config together.
#
# ============================================================================

{ ... }:

{
  programs.fish.shellAliases = {
    # eza (ls replacement)
    ll = "eza -la";
    la = "eza -a";

    # git shortcuts
    lg = "lazygit";
    g = "git";
    gs = "git status";
    gc = "git commit";
    gp = "git push";
  };
}
