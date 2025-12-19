# ============================================================================
# KUBERNETES TOOLS - kubie + Starship Integration
# ============================================================================
#
# KUBIE - SAFE CONTEXT MANAGEMENT
# Kubie isolates Kubernetes contexts to individual shell sessions:
#   - Each shell is locked to one context (can't accidentally switch)
#   - Exit the shell = no active context (safe default)
#   - Visual indicator in prompt shows current context
#
# WORKFLOW:
#   kubie ctx k3s-local     # Opens new shell locked to k3s
#   kubectl get pods        # Works in this shell
#   exit                    # Back to normal shell, no k8s context
#
#   kubie ctx prod          # Opens new shell locked to prod
#   # ... do prod work ...
#   exit                    # Back to safety
#
# WHY NOT JUST KUBECTL CONFIG USE-CONTEXT?
#   - Easy to forget which context you're in
#   - One wrong terminal = deploy to prod
#   - kubie makes each shell explicit and isolated
#
# ============================================================================

{ pkgs, ... }:

let
  # Use pkgs.formats.yaml for proper YAML generation from Nix attrsets
  yamlFormat = pkgs.formats.yaml { };
in
{
  home.packages = with pkgs; [
    kubie       # Context isolation (one context per shell)
    kubectx     # Quick context/namespace switching (kubens for namespaces)
  ];

  # Kubie configuration (generated as proper YAML)
  xdg.configFile."kubie.yaml".source = yamlFormat.generate "kubie.yaml" {
    # Shell to spawn for kubie sessions
    shell = "fish";

    # Prompt settings - we use starship, so disable kubie's prompt
    prompt = {
      disable = true;  # Starship handles the k8s context display
    };

    # Behavior settings
    configs = {
      # Kubeconfig files to search for contexts
      include = [
        "~/.kube/k3s.yaml"        # Local k3s cluster
        "~/.kube/gardener-*.yaml" # Gardener clusters (when added)
        "~/.kube/config"          # Default location (if any)
      ];
      # Exclude patterns (optional)
      exclude = [ ];
    };
  };

  # Fish shell integration for kubie
  programs.fish.interactiveShellInit = ''
    # Ensure KUBECONFIG is not set globally
    # This prevents accidental cluster access outside kubie sessions
    # When you run `kubie ctx`, it sets KUBECONFIG for that shell only
    set -e KUBECONFIG
  '';
}
