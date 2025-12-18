{ config, pkgs, user, ... }:

{
  # 1Password GUI and CLI
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ user.name ];
  };

  # 1Password SSH Agent
  # This lets 1Password manage your SSH keys
  # Keys are stored in 1Password, never on disk
  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';
}
