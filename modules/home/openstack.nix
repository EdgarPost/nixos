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
#   1. Create Application Credentials in Leafcloud Horizon:
#      Identity → Application Credentials → Create Application Credential
#
#   2. Create an item in 1Password (Pilosa vault) named "OpenStack-Leafcloud" with fields:
#      - auth_url: https://create.leaf.cloud:5000
#      - application_credential_id: (from step 1)
#      - application_credential_secret: (from step 1)
#      - region_name: europe-nl (optional)
#
#   3. Run: os-login
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
          set -gx OS_REGION_NAME (op read "$op_item/region_name" 2>/dev/null; or echo "europe-nl")

          # Application credential authentication (more secure than password)
          set -gx OS_AUTH_TYPE v3applicationcredential
          set -gx OS_APPLICATION_CREDENTIAL_ID (op read "$op_item/application_credential_id")
          set -gx OS_APPLICATION_CREDENTIAL_SECRET (op read "$op_item/application_credential_secret")

          # OpenStack identity API version
          set -gx OS_IDENTITY_API_VERSION 3
          set -gx OS_INTERFACE public

          echo "OpenStack environment configured (Leafcloud @ $OS_REGION_NAME)"
      end

      function os-logout --description "Clear OpenStack credentials from environment"
          set -e OS_AUTH_URL
          set -e OS_AUTH_TYPE
          set -e OS_APPLICATION_CREDENTIAL_ID
          set -e OS_APPLICATION_CREDENTIAL_SECRET
          set -e OS_REGION_NAME
          set -e OS_IDENTITY_API_VERSION
          set -e OS_INTERFACE
          echo "OpenStack credentials cleared"
      end
    '';
  };
}
