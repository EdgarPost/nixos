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
#   1. In Gardener dashboard:
#      - Account page → Download garden kubeconfig
#      - Select shoot → Download shoot kubeconfig
#
#   2. Create 1Password item (Pilosa/Gardener-Leafcloud) with fields:
#      - garden_identity: leafcloud-production
#      - garden_kubeconfig: (paste garden kubeconfig YAML)
#      - shoot_kubeconfig: (paste shoot kubeconfig YAML)
#
#   3. Run: gardener-login
#      First run opens browser for OIDC authentication
#
#   4. Use with kubie: kubie ctx garden-dgrmt8xvux--och-prod-external
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
    pkgs.kubelogin-oidc  # For OIDC authentication (kubectl oidc-login)
  ];

  programs.fish = {
    # Shell aliases for quick access
    shellAliases.g8r = "gardenctl";

    # Fish functions for Gardener login via 1Password
    interactiveShellInit = ''
      function gardener-login --description "Setup Gardener access from 1Password"
          # 1Password item reference
          set -l op_item "op://Pilosa/Gardener-Leafcloud"

          # Ensure directories exist
          mkdir -p $HOME/.kube
          chmod 700 $HOME/.kube
          mkdir -p $HOME/.garden

          echo "Loading Gardener config from 1Password..."

          # Read config values from 1Password
          set -l garden_identity (op read "$op_item/garden_identity")
          or begin; echo "Failed to read garden_identity"; return 1; end

          # Save garden kubeconfig (needed by gardenlogin for auth)
          set -l garden_kubeconfig_path "$HOME/.kube/garden-$garden_identity.yaml"
          op read "$op_item/garden_kubeconfig" > $garden_kubeconfig_path
          or begin; echo "Failed to read garden_kubeconfig"; return 1; end
          chmod 600 $garden_kubeconfig_path

          # Create gardenctl/gardenlogin config pointing to garden kubeconfig
          echo "gardens:
  - identity: $garden_identity
    kubeconfig: $garden_kubeconfig_path" > $HOME/.garden/gardenctl-v2.yaml

          # Save shoot kubeconfig
          set -l shoot_kubeconfig_path "$HOME/.kube/gardener-shoot.yaml"
          op read "$op_item/shoot_kubeconfig" > $shoot_kubeconfig_path
          or begin; echo "Failed to read shoot_kubeconfig"; return 1; end
          chmod 600 $shoot_kubeconfig_path

          echo ""
          echo "Gardener configured! First login opens browser for OIDC auth."
          echo "Use with kubie:"
          echo "  kubie ctx garden-dgrmt8xvux--och-prod-external"
      end

      function gardener-logout --description "Clear Gardener kubeconfigs"
          rm -f $HOME/.kube/garden-*.yaml
          rm -f $HOME/.kube/gardener-*.yaml
          echo "Gardener kubeconfigs removed"
      end
    '';
  };
}
