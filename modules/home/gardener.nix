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
# SETUP (1Password - portable across machines):
#   1. In Gardener dashboard: select your shoot → Download Kubeconfig
#   2. Create 1Password item (Pilosa/Gardener-Leafcloud) with fields:
#      - shoot_kubeconfig: (paste the downloaded kubeconfig YAML)
#      - shoot_name: och-prod (or your shoot name)
#
#   3. Run: gardener-login
#      This pulls kubeconfig from 1Password to ~/.kube/
#
#   4. Use with kubie: kubie ctx <shoot_name>
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

  programs.fish = {
    # Shell aliases for quick access
    shellAliases.g8r = "gardenctl";

    # Fish functions for Gardener login via 1Password
    interactiveShellInit = ''
      function gardener-login --description "Setup Gardener shoot access from 1Password"
          # 1Password item reference
          set -l op_item "op://Pilosa/Gardener-Leafcloud"

          # Ensure ~/.kube exists with correct permissions
          mkdir -p $HOME/.kube
          chmod 700 $HOME/.kube

          echo "Loading Gardener kubeconfig from 1Password..."

          # Read shoot name and kubeconfig from 1Password
          set -l shoot_name (op read "$op_item/shoot_name")
          or begin; echo "Failed to read shoot_name"; return 1; end

          # Write shoot kubeconfig to file
          set -l kubeconfig_path "$HOME/.kube/gardener-$shoot_name.yaml"
          op read "$op_item/shoot_kubeconfig" > $kubeconfig_path
          or begin; echo "Failed to read shoot_kubeconfig"; return 1; end
          chmod 600 $kubeconfig_path

          echo ""
          echo "Gardener kubeconfig installed! Use with kubie:"
          echo "  kubie ctx $shoot_name"
      end

      function gardener-logout --description "Clear Gardener kubeconfigs"
          rm -f $HOME/.kube/garden-*.yaml
          rm -f $HOME/.kube/gardener-*.yaml
          echo "Gardener kubeconfigs removed"
      end
    '';
  };
}
