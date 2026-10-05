# ============================================================================
# OVERLAYS - Package customizations applied on top of nixpkgs
# ============================================================================
#
# An overlay is a function `final: prev: { ... }` that extends or overrides
# packages from nixpkgs. `prev` is the unmodified package set, `final` is the
# set with all overlays applied.
#
# Overlays here are wired into the config in flake.nix via `nixpkgs.overlays`.

final: prev: {
  # --------------------------------------------------------------------------
  # kubie - fix "Missing end to balance this function definition" on fish 4.9+
  # --------------------------------------------------------------------------
  # kubie injects a fish script (`fish -ilC ...`) whose prompt contains
  # unquoted `[`, `]` and `|` characters. fish >= 4.9 parses the unquoted
  # `\e[31m` as a glob bracket expression and rejects it, so the whole script
  # fails to parse. This backports the upstream fix (kubie-org/kubie PR #434)
  # which escapes only those three characters, keeping the `(...)` command
  # substitutions and `\e` escapes live.
  #
  # See https://github.com/kubie-org/kubie/pull/434 and
  #     https://github.com/kubie-org/kubie/issues/428
  #
  # Drop this override once kubie ships a release containing the fix.
  kubie = prev.kubie.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ./kubie-fish-escape.patch ];
  });
}