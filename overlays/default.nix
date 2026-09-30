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

  # --------------------------------------------------------------------------
  # herdr - fix link failure against ld.bfd
  # --------------------------------------------------------------------------
  # herdr vendors libghostty-vt, which Zig builds as a static library. Zig's
  # default config bundles its own compiler-rt and ubsan runtime objects into
  # that archive; their CFI overlaps the Rust objects, so the final link dies
  # with:
  #
  #   ld.bfd: .eh_frame_hdr refers to overlapping FDEs
  #   ld.bfd: final link failed: bad value
  #
  # Backport of nixpkgs commit 277383a83357 ("herdr: fix build for linux"),
  # which disables the bundled runtime archives. Drop this override once our
  # locked nixpkgs contains that fix.
  #
  # See https://github.com/NixOS/nixpkgs/commit/277383a83357
  herdr = prev.herdr.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + prev.lib.optionalString prev.stdenv.hostPlatform.isLinux ''
        substituteInPlace vendor/libghostty-vt/src/build/GhosttyLibVt.zig \
          --replace-fail 'lib.bundle_compiler_rt = true;' 'lib.bundle_compiler_rt = false;' \
          --replace-fail 'lib.bundle_ubsan_rt = true;' 'lib.bundle_ubsan_rt = false;'
      '';
  });
}