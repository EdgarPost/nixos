# ============================================================================
# OPENSTACK - Cloud CLI Tools with 1Password Integration
# ============================================================================
#
# WHAT IS OPENSTACK CLIENT?
# CLI for interacting with OpenStack clouds:
#   - Authentication (tokens, application credentials)
#   - Project/tenant management
#   - VM, network, storage operations
#
# AUTHENTICATION WITH 1PASSWORD:
# Credentials are stored securely in 1Password and injected at runtime.
#
# SETUP:
#   1. Create an item in 1Password (Pilosa vault) named "OpenStack-Leafcloud" with fields:
#      - auth_url: https://create.leaf.cloud:5000
#      - username: your-leafcloud-email
#      - password: your-leafcloud-password
#      - project_name: och_org_XXXX
#      - project_id: your-project-uuid
#      - user_domain_name: Default (optional)
#      - region_name: europe-nl (optional)
#
#   2. Run: os-login
#      This authenticates with 1Password and sets OS_* environment variables
#
# USAGE:
#   os-login                  # Authenticate (sets env vars for current shell)
#   os token issue            # Verify authentication works
#   os server list            # List VMs
#   os project list           # List projects
#
# ============================================================================

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    openstackclient  # Full OpenStack CLI (`openstack` command)
    _1password-cli   # 1Password CLI (`op` command) for secure credential injection
  ];

  programs.fish = {
    # Shell alias for quick access
    shellAliases.os = "openstack";

    # Fish function to load OpenStack credentials from 1Password
    # Modify the op:// paths to match your 1Password vault and item
    interactiveShellInit = ''
      function os-login --description "Load OpenStack credentials from 1Password"
          # 1Password item reference for Leafcloud
          # Format: op://Vault/Item/field
          set -l op_item "op://Pilosa/OpenStack-Leafcloud"

          echo "Loading OpenStack credentials from 1Password..."

          # Read credentials from 1Password (will prompt for auth if needed)
          set -gx OS_AUTH_URL (op read "$op_item/auth_url")
          set -gx OS_USERNAME (op read "$op_item/username")
          set -gx OS_PASSWORD (op read "$op_item/password")
          set -gx OS_PROJECT_NAME (op read "$op_item/project_name")
          set -gx OS_PROJECT_ID (op read "$op_item/project_id")
          set -gx OS_USER_DOMAIN_NAME (op read "$op_item/user_domain_name" 2>/dev/null; or echo "Default")
          set -gx OS_REGION_NAME (op read "$op_item/region_name" 2>/dev/null; or echo "europe-nl")

          # OpenStack identity API version
          set -gx OS_IDENTITY_API_VERSION 3
          set -gx OS_INTERFACE public

          echo "OpenStack environment configured for $OS_PROJECT_NAME @ $OS_REGION_NAME"
      end

      function os-logout --description "Clear OpenStack credentials from environment"
          set -e OS_AUTH_URL
          set -e OS_USERNAME
          set -e OS_PASSWORD
          set -e OS_PROJECT_NAME
          set -e OS_PROJECT_ID
          set -e OS_USER_DOMAIN_NAME
          set -e OS_REGION_NAME
          set -e OS_IDENTITY_API_VERSION
          set -e OS_INTERFACE
          echo "OpenStack credentials cleared"
      end
    '';
  };
}
