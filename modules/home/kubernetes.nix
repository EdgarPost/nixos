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
    k9s         # Terminal UI for clusters (uses KUBECONFIG, so kubie-scoped)
  ];

  # Kubie configuration (generated as proper YAML)
  # NOTE: kubie reads ~/.kube/kubie.yaml (not ~/.config/kubie.yaml), so this
  # must live in home.file.".kube", not xdg.configFile.
  home.file.".kube/kubie.yaml".source = yamlFormat.generate "kubie.yaml" {
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
        "~/.kube/gardener-*.yaml" # Gardener clusters (when added)
        "~/.kube/config"          # Default location (if any)
      ];
      # Exclude patterns (optional)
      exclude = [ ];
    };
  };

  # An empty kubeconfig used as the default KUBECONFIG outside kubie shells.
  # With KUBECONFIG unset, kubectl/k9s/etc. would fall back to ~/.kube/config
  # and reach whatever cluster it points at; pointing at this empty config
  # instead ensures no cluster is reachable until you enter one via kubie.
  home.file.".kube/empty-config.yaml".text = ''
    apiVersion: v1
    kind: Config
    clusters: []
    contexts: []
    users: []
  '';

  # Fish shell integration for kubie
  programs.fish.interactiveShellInit = ''
    # No Kubernetes access outside kubie shells: point KUBECONFIG at an empty
    # config so kubectl/k9s/etc. find no clusters. Inside a kubie shell
    # (KUBIE_ACTIVE is set), leave kubie's env-provided config in place so the
    # first prompt already shows the context; kubie_preexec re-asserts it per
    # command after that.
    if not set -q KUBIE_ACTIVE
      set -gx KUBECONFIG ~/.kube/empty-config.yaml
    end
  '';
}
