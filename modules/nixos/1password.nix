# ============================================================================
# 1PASSWORD - Password Manager and SSH Agent
# ============================================================================
#
# WHY 1PASSWORD FOR SECRETS?
# NixOS configs are stored in /nix/store which is world-readable.
# Putting secrets (API keys, passwords) directly in config = security risk.
#
# Options for secrets management:
#   1. 1Password - Secrets in external vault, retrieved at runtime
#   2. sops-nix - Encrypt secrets in git, decrypt during activation
#   3. agenix - Like sops-nix but uses age instead of GPG/sops
#
# 1Password is chosen here because:
#   - Already have paid subscription
#   - Works across devices (phone, other computers)
#   - SSH agent integration replaces SSH key files
#
# ============================================================================

{ config, pkgs, lib, user, ... }:

{
  # 1Password CLI: Command-line access to vault
  # Usage: op item get "SSH Key" --fields private_key
  programs._1password.enable = true;

  # 1Password GUI application
  programs._1password-gui = {
    enable = true;
    # polkitPolicyOwners: Users allowed to unlock 1Password via fingerprint/password
    # Required for browser integration and system auth dialogs
    polkitPolicyOwners = [ user.name ];
  };

  # ==========================================================================
  # SSH AGENT INTEGRATION
  # ==========================================================================
  # 1Password can act as an SSH agent, storing SSH keys in the vault.
  # Benefits:
  #   - No ~/.ssh/id_* files to protect
  #   - Keys unlocked with biometric/1Password master password
  #   - Same keys available on all machines with 1Password
  #
  # Setup: 1Password → Settings → Developer → SSH Agent → Enable
  # Then: Add SSH keys to 1Password as "SSH Key" items
  #
  # This config tells SSH to use 1Password's agent socket instead of ssh-agent
  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';
}
