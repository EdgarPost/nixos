# ============================================================================
# BITWARDEN / VAULTWARDEN - SSH Agent
# ============================================================================
#
# WHY BITWARDEN?
#   Vaultwarden (self-hosted, Synology NAS behind an SSL reverse proxy) holds
#   the vault. Bitwarden's clients are the front end. The desktop app is the
#   only client that exposes an SSH agent.
#
#   Vaultwarden reports every account as premium and implements no billing, so
#   TOTP, attachments, emergency access and unlimited org members are free.
#   What it does NOT implement: the Provider/MSP portal, service accounts, and
#   cloud-only client features (the desktop app's direct 1Password importer).
#   Anything needing a secret non-interactively therefore cannot use the vault
#   and belongs in sops-nix/agenix instead.
#
# SECRET INJECTION
#   The `op read op://Vault/Item/field` calls that used to live in shell init
#   are not replaceable one-for-one: `bw` wants an interactive unlock. For
#   interactive shells `rbw` (same API, pinentry-backed, caches the session) is
#   the intended replacement once its base_url is configured; machine-owned
#   secrets go to sops-nix/agenix. Until that is wired up, `_1password-cli`
#   remains in the per-user packages.
#
# SSH AGENT
#   The desktop app exposes ~/.bitwarden-ssh-agent.sock once Settings -> SSH
#   agent is enabled, and it must be running for ssh to reach it (see the
#   Hyprland startup entry in modules/home/hyprland.nix).
#   Key support: Ed25519 and RSA import, Ed25519-only generation.
#   Vault item type: SSH key, supported by Vaultwarden since 2024.12.
#   Biometric/system unlock on Linux goes through the polkit action shipped by
#   the bitwarden-desktop package (allow_active=auth_self); no rule needed.
#
# ============================================================================

{ ... }:

{
  # System-wide ssh client config. The per-user copy is in home/default.nix;
  # both point at the same socket, and ssh prefers the per-user one.
  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent ~/.bitwarden-ssh-agent.sock
  '';
}
