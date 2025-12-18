{ config, pkgs, lib, user, ... }:

{
  # 1Password CLI + GUI
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ user.name ];
  };

  # 1Password SSH Agent (configure in 1Password: Settings → Developer → SSH Agent)
  programs.ssh.extraConfig = ''
    Host *
      IdentityAgent ~/.1password/agent.sock
  '';
}
