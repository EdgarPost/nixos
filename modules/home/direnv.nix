# ============================================================================
# DIRENV - Automatic Per-Directory Environment Variables
# ============================================================================
#
# WHAT IS DIRENV?
# Direnv loads and unloads environment variables when you cd into a directory
# containing a .envrc file. Combined with nix-direnv, it provides seamless
# per-project Nix development shells.
#
# USAGE:
#   1. Create a .envrc in your project: echo "use flake" > .envrc
#   2. Allow it: direnv allow
#   3. cd in/out and the environment loads/unloads automatically
#
# NIX-DIRENV:
#   Extends direnv with `use flake` and `use nix` support.
#   Caches Nix environments so re-entering a directory is instant.
#
# ============================================================================

{ ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # Cache Nix environments for instant shell loads

    # Reduce log noise when entering directories
    config.global.hide_env_diff = true;
  };
}
