# ============================================================================
# GARDENER - Kubernetes Cluster Management
# ============================================================================
#
# WHAT IS GARDENER?
# Kubernetes-native system for managing Kubernetes clusters across clouds.
# You have a "garden" cluster that manages "shoot" clusters (your workloads).
#
# TOOLS:
#   gardenctl   - CLI for targeting and managing Gardener resources
#   gardenlogin - kubectl credential plugin for shoot cluster auth
#
# SETUP:
#   1. Configure garden cluster:
#      gardenctl config set-garden mygarden \
#        --kubeconfig ~/.kube/garden-kubeconfig.yaml
#
#   2. Target a shoot cluster:
#      gardenctl target --garden mygarden --project myproject --shoot myshoot
#
#   3. Get kubeconfig for shoot:
#      gardenctl kubeconfig --export > ~/.kube/gardener-prod.yaml
#
#   4. Use with kubie (safe context isolation):
#      kubie ctx gardener-prod
#
# OPENSTACK INTEGRATION:
# If your shoot runs on OpenStack, gardenctl uses your OpenStack credentials
# (from clouds.yaml or OS_* env vars) for infrastructure operations.
#
# ============================================================================

{ pkgs, lib, ... }:

let
  # Map Nix platform to GitHub release naming convention
  platformMap = {
    "x86_64-linux" = "linux_amd64";
    "aarch64-linux" = "linux_arm64";
    "x86_64-darwin" = "darwin_amd64";
    "aarch64-darwin" = "darwin_arm64";
  };

  platform = platformMap.${pkgs.stdenv.hostPlatform.system} or (throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}");

  # Platform-specific hashes (pre-fetched for each architecture)
  gardenctlHashes = {
    "linux_amd64" = "12spbpplbacmvfwkx48km56rdyg4aafl5yam0psmifpc6mw869rn";
    # Add other platforms as needed:
    # "linux_arm64" = "...";
    # "darwin_amd64" = "...";
    # "darwin_arm64" = "...";
  };

  gardenloginHashes = {
    "linux_amd64" = "0pn4wcv149a83bhcp3rpz714w2spghh5xhrg075p3rs8lrisv3dv";
    # Add other platforms as needed:
    # "linux_arm64" = "...";
    # "darwin_amd64" = "...";
    # "darwin_arm64" = "...";
  };

  # gardenctl-v2: Gardener CLI (not in nixpkgs, fetch from GitHub releases)
  gardenctl = pkgs.stdenv.mkDerivation rec {
    pname = "gardenctl-v2";
    version = "2.13.0";

    src = pkgs.fetchurl {
      url = "https://github.com/gardener/gardenctl-v2/releases/download/v${version}/gardenctl_v2_${platform}";
      sha256 = gardenctlHashes.${platform};
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/gardenctl
      chmod +x $out/bin/gardenctl
    '';

    meta = with lib; {
      description = "Gardener command-line interface";
      homepage = "https://github.com/gardener/gardenctl-v2";
      license = licenses.asl20;
      platforms = builtins.attrNames platformMap;
    };
  };

  # gardenlogin: kubectl credential plugin for Gardener authentication
  gardenlogin = pkgs.stdenv.mkDerivation rec {
    pname = "gardenlogin";
    version = "0.8.0";

    src = pkgs.fetchurl {
      url = "https://github.com/gardener/gardenlogin/releases/download/v${version}/gardenlogin_${platform}";
      sha256 = gardenloginHashes.${platform};
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/gardenlogin
      chmod +x $out/bin/gardenlogin
      # kubectl looks for plugins as kubectl-<name>
      ln -s $out/bin/gardenlogin $out/bin/kubectl-gardenlogin
    '';

    meta = with lib; {
      description = "Kubernetes credential plugin for Gardener";
      homepage = "https://github.com/gardener/gardenlogin";
      license = licenses.asl20;
      platforms = builtins.attrNames platformMap;
    };
  };
in
{
  home.packages = [
    gardenctl
    gardenlogin
  ];

  # Shell aliases for quick access
  programs.fish.shellAliases = {
    g8r = "gardenctl";  # Short alias for gardenctl
  };
}
