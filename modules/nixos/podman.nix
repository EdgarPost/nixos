# ============================================================================
# PODMAN - Rootless Container Runtime
# ============================================================================
#
# WHY PODMAN OVER DOCKER?
#   - Rootless: Containers run as your user, not root (more secure)
#   - Daemonless: No background service eating resources
#   - Docker CLI compatible: `podman` is a drop-in replacement for `docker`
#   - Pods: Native support for multi-container pods (like k8s)
#   - Systemd integration: Containers can be managed as user services
#
# USAGE:
#   podman run -it ubuntu bash           # Run container
#   podman build -t myapp .              # Build image
#   podman compose up                    # Docker Compose compatible
#   podman ps                            # List running containers
#
# DOCKER COMPATIBILITY:
#   The `docker` alias points to podman, so existing scripts work.
#   Docker Compose works via podman-compose or podman compose.
#
# ============================================================================

{ config, pkgs, user, ... }:

{
  # Enable Podman with Docker compatibility
  virtualisation.podman = {
    enable = true;

    # Create `docker` alias pointing to podman
    # Allows running `docker` commands that actually use podman
    dockerCompat = true;

    # Default OCI runtime (crun is faster than runc, written in C)
    defaultNetwork.settings.dns_enabled = true;
  };

  # Add user to podman-related groups for rootless operation
  users.users.${user.name}.extraGroups = [ "podman" ];

  # Container tools
  environment.systemPackages = with pkgs; [
    podman-compose  # Docker Compose alternative for podman
    buildah         # Build OCI images (more flexible than Dockerfile)
    skopeo          # Inspect/copy container images between registries
  ];
}
