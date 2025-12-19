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
#   1. Add these fields to your 1Password item (Pilosa/Gardener-Leafcloud):
#      - garden_kubeconfig: (paste full kubeconfig YAML from Gardener dashboard)
#      - garden_name: leafcloud (or your garden name)
#      - project_name: your-project
#      - shoot_name: your-shoot-cluster
#
#   2. Run: gardener-login
#      This pulls kubeconfig from 1Password and configures gardenctl
#
#   3. Use with kubie: kubie ctx gardener-prod
#
# OPENSTACK INTEGRATION:
# Run os-login first - gardenctl uses OS_* env vars for infrastructure ops.
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
      function gardener-login --description "Setup Gardener access from 1Password"
          # 1Password item reference
          set -l op_item "op://Pilosa/Gardener-Leafcloud"

          echo "Loading Gardener config from 1Password..."

          # Ensure ~/.kube exists
          mkdir -p $HOME/.kube

          # Read garden config from 1Password
          set -l garden_name (op read "$op_item/garden_name")
          set -l project_name (op read "$op_item/project_name")
          set -l shoot_name (op read "$op_item/shoot_name")

          # Write garden kubeconfig to file
          set -l kubeconfig_path "$HOME/.kube/garden-$garden_name.yaml"
          op read "$op_item/garden_kubeconfig" > $kubeconfig_path
          chmod 600 $kubeconfig_path

          # Configure gardenctl with this garden
          gardenctl config set-garden $garden_name --kubeconfig $kubeconfig_path

          # Set up gardenctl session ID (required for gardenctl v2)
          set -gx GCTL_SESSION_ID (cat /proc/sys/kernel/random/uuid)

          # Target the shoot cluster
          echo "Targeting shoot: $garden_name/$project_name/$shoot_name"
          gardenctl target --garden $garden_name --project $project_name --shoot $shoot_name

          # Export shoot kubeconfig for kubectl/kubie
          set -l shoot_kubeconfig "$HOME/.kube/gardener-$shoot_name.yaml"
          gardenctl kubeconfig --export > $shoot_kubeconfig
          chmod 600 $shoot_kubeconfig

          echo ""
          echo "Gardener configured! Use with kubie:"
          echo "  kubie ctx gardener-$shoot_name"
      end

      function gardener-logout --description "Clear Gardener kubeconfigs"
          rm -f $HOME/.kube/garden-*.yaml
          rm -f $HOME/.kube/gardener-*.yaml
          echo "Gardener kubeconfigs removed"
      end
    '';
  };
}
