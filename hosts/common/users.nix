# ============================================================================
# USER CONFIGURATION - User Accounts and Authentication
# ============================================================================
#
# DECLARATIVE VS IMPERATIVE USER MANAGEMENT:
# Traditional Linux: useradd, passwd, usermod (imperative, stateful)
# NixOS: Declare users here; system converges to match (declarative)
#
# The `user` variable comes from specialArgs in flake.nix, demonstrating
# how data flows from the top level to individual modules.
#
# ============================================================================

{ config, pkgs, user, ... }:

{
  # Define the main user account
  # ${user.name} = string interpolation (like `${user.name}` in JS template literals)
  users.users.${user.name} = {
    # isNormalUser creates a regular user with:
    #   - Home directory at /home/<name>
    #   - UID >= 1000
    #   - Login shell
    # vs. isSystemUser for service accounts (no home, no login)
    isNormalUser = true;
    description = user.fullName;

    # UNIX GROUPS - Grant permissions via group membership
    # Groups are the Unix way to manage permissions without giving full root
    extraGroups = [
      "wheel"           # Can use sudo (the Unix admin group)
      "networkmanager"  # Can configure WiFi, VPN without sudo
      "video"           # Can control screen brightness (backlight device access)
      "audio"           # Can control audio devices directly
      "pipewire"        # Can access system-wide PipeWire audio
    ];

    # PASSWORD MANAGEMENT:
    # Three approaches in NixOS:
    #   1. initialPassword - Set once, user changes with passwd (shown below)
    #   2. hashedPassword - Store hashed password in config (visible in store!)
    #   3. hashedPasswordFile - Point to a file (use with sops-nix for secrets)
    #
    # Best practice: Use initialPassword for first boot, then passwd
    # The passwd-set password survives rebuilds (stored in /etc/shadow)
    # initialPassword = "changeme";
  };

  # Enable Fish shell system-wide (required for it to be a valid login shell)
  # Without this, setting Fish as default shell would fail
  programs.fish.enable = true;

  # Set Fish as the default shell for all users
  # This adds fish to /etc/shells and sets it in /etc/passwd
  users.defaultUserShell = pkgs.fish;
}
