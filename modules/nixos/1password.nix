{ config, pkgs, lib, user, ... }:

{
  # 1Password CLI (always available)
  programs._1password.enable = true;

  # 1Password GUI (requires display - enable after Hyprland setup)
  # programs._1password-gui = {
  #   enable = true;
  #   polkitPolicyOwners = [ user.name ];
  # };

  # 1Password SSH Agent (enable after GUI is set up)
  # programs.ssh.extraConfig = ''
  #   Host *
  #     IdentityAgent ~/.1password/agent.sock
  # '';
}
