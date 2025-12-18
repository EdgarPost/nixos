{ config, pkgs, user, ... }:

{
  # Main user
  users.users.${user.name} = {
    isNormalUser = true;
    description = user.fullName;
    extraGroups = [
      "wheel"           # sudo
      "networkmanager"  # network config
      "video"           # screen brightness, etc.
      "audio"           # audio control
    ];
    # Password is managed via passwd command, not in config
    # For fresh install, set initialPassword temporarily
    # initialPassword = "changeme";
  };

  # Shell
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
}
