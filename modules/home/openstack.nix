# ============================================================================
# OPENSTACK - Cloud CLI Tools
# ============================================================================
#
# WHAT IS OPENSTACK CLIENT?
# CLI for interacting with OpenStack clouds:
#   - Authentication (tokens, application credentials)
#   - Project/tenant management
#   - VM, network, storage operations
#
# AUTHENTICATION:
# OpenStack uses clouds.yaml or environment variables for auth.
#
# Option 1: clouds.yaml (recommended)
#   Place in ~/.config/openstack/clouds.yaml:
#   ```yaml
#   clouds:
#     mycloud:
#       auth:
#         auth_url: https://keystone.example.com:5000/v3
#         username: myuser
#         password: mypassword  # Or use application credentials
#         project_name: myproject
#         user_domain_name: Default
#         project_domain_name: Default
#   ```
#   Then: openstack --os-cloud mycloud server list
#
# Option 2: Environment variables (openrc)
#   source ~/openrc.sh  # Sets OS_* variables
#   openstack server list
#
# USAGE:
#   openstack --os-cloud <name> token issue    # Get auth token
#   openstack server list                       # List VMs
#   openstack project list                      # List projects
#
# ============================================================================

{ pkgs, ... }:

let
  yamlFormat = pkgs.formats.yaml { };
in
{
  home.packages = with pkgs; [
    openstackclient  # Full OpenStack CLI (`openstack` command)
  ];

  # Shell alias for quick access
  programs.fish.shellAliases.os = "openstack";

  # Create clouds.yaml directory structure
  # User should add their actual credentials to this file
  xdg.configFile."openstack/.keep".text = ''
    # Place your clouds.yaml in this directory
    # See module comments for format
  '';
}
