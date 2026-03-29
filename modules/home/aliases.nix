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
  programs.fish.functions = {
    # Build NixOS config, show package diff, then switch after confirmation
    nrs = ''
      set flake $argv[1]
      if test -z "$flake"
        echo "Usage: nrs <flake-ref>  (e.g. nrs .#framework-desktop)"
        return 1
      end

      echo "Building $flake..."
      nixos-rebuild build --flake $flake; or return 1

      echo ""
      nvd diff /run/current-system result

      echo ""
      read -P "Switch to this configuration? [y/N] " confirm
      if test "$confirm" = y -o "$confirm" = Y
        sudo nixos-rebuild switch --flake $flake
      else
        echo "Aborted."
      end
    '';
  };

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
