# ============================================================================
# CACHIX - Noctalia Prebuilt Binary Cache
# ============================================================================
#
# Noctalia publishes prebuilt binaries on a project-controlled Cachix.
# Adding the cache avoids compiling the C++23 shell from source on every
# machine and every rebuild.
#
# Trust model: you trust the Noctalia maintainers' signed binaries. The
# public key is pinned here; update if the project rotates it.
#
# Docs: https://docs.noctalia.dev/v5/getting-started/nixos/#pre-built-binaries
#
# ============================================================================

{ ... }:

{
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };
}
