# ============================================================================
# K3S - Lightweight Kubernetes for Local Development
# ============================================================================
#
# WHAT IS K3S?
# Lightweight Kubernetes distribution:
#   - Single binary (~100MB vs ~1GB for full k8s)
#   - Embedded containerd, flannel, CoreDNS
#   - Perfect for local dev, edge, IoT
#   - Fully conformant Kubernetes
#
# ARCHITECTURE:
#   k3s (orchestrator) → containerd (container runtime) → your pods
#   Podman remains separate for ad-hoc containers
#
# KUBECONFIG:
#   K3s writes config to /etc/rancher/k3s/k3s.yaml (root-owned)
#   We copy it to ~/.kube/k3s.yaml with correct permissions
#   Use with: kubie ctx k3s-local
#
# USAGE:
#   systemctl status k3s           # Check service
#   kubie ctx k3s-local            # Enter isolated k3s shell
#   kubectl get nodes              # Verify cluster
#   k9s                            # Terminal UI
#
# ============================================================================

{ config, pkgs, lib, user, ... }:

{
  # Enable k3s as a single-node cluster (server mode)
  services.k3s = {
    enable = true;
    role = "server";

    # Disable components we don't need for local dev
    # traefik: We'll use port-forward or ingress-nginx if needed
    # servicelb: Load balancer not needed locally
    extraFlags = toString [
      "--disable=traefik"
      "--disable=servicelb"
    ];
  };

  # Kubernetes CLI tools
  environment.systemPackages = with pkgs; [
    kubectl          # Kubernetes CLI
    kubernetes-helm  # Helm package manager
    k9s              # Terminal UI for Kubernetes
  ];

  # Create user-accessible kubeconfig on system activation
  # K3s config is root-owned; this copies it with user permissions
  system.activationScripts.k3s-kubeconfig = lib.stringAfter [ "users" ] ''
    if [ -f /etc/rancher/k3s/k3s.yaml ]; then
      mkdir -p /home/${user.name}/.kube
      # Copy and rename context from "default" to "k3s-local"
      ${pkgs.gnused}/bin/sed 's/: default/: k3s-local/g' /etc/rancher/k3s/k3s.yaml \
        > /home/${user.name}/.kube/k3s.yaml
      chown ${user.name}:users /home/${user.name}/.kube/k3s.yaml
      chmod 600 /home/${user.name}/.kube/k3s.yaml
    fi
  '';
}
