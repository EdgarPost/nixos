# ============================================================================
# AZURE - Azure CLI with Azure DevOps Extension
# ============================================================================
#
# WHAT IS AZURE CLI?
# Official CLI for Microsoft Azure:
#   - Manage VMs, storage, networks, AKS, App Services, and more
#   - Scriptable infrastructure commands (`az group create`, `az vm list`, ...)
#
# WHAT IS THE AZURE DEVOPS EXTENSION?
# Adds `az devops` commands for Azure DevOps / Azure Repos:
#   - `az repos clone`            # Clone Azure DevOps repositories
#   - `az repos pr create`        # Create pull requests
#   - `az pipelines run`          # Trigger CI/CD pipelines
#
# WHY `withExtensions`?
# `az extension add` writes to ~/.azure at runtime, which breaks Nix's
# immutability. `azure-cli.withExtensions` bakes the extension into the
# derivation so it is always available and reproducible.
#
# AUTHENTICATION:
#   az login          # Browser/device-code login (interactive)
#
# USAGE:
#   az login                        # Log in via browser
#   az account show                 # Verify login + show active subscription
#   az devops configure --defaults organization=https://dev.azure.com/ORG project=PROJECT
#   az repos list                   # List repositories
#   az pipelines list               # List pipelines
#
# ============================================================================

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Azure CLI with the Azure DevOps extension baked in (reproducible/immutable)
    (azure-cli.withExtensions [ azure-cli.extensions.azure-devops ])
  ];
}