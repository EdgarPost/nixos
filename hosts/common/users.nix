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
    ];

    # SSH public key for remote access between machines (from 1Password "Nixos SSH Key")
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuHwyv8T62zhlWarSHBMeIf8/kwAAAKhMfYAnbSyIQVXEXqs2QANCygBkVhm5QgoViDi1HIZCuYWv0Drhgo/J/SaEKn19xuo1YYq6Z/BmJkNUKMvjVTSrA3UhDd0/lJoIR3jXkbfzY4eiuA9jnBInYWPKxBiaxNS9H953Rz++GDkG4DVPBnOzMN5e5kjAudxBqjmcCmR/P+QYvmRuAbd5+dLQlim/NeC9Xu4lUR1M6FdO3E9/gMoxjVjhr7F9jvYGIcScx5vYeEBkFgXpH4QIMU6iHQL79q0zV4kMWS85ledv3CHxuNkBR1fvzctiWm9Gu3xBNXv141j9JUD1TSeNf"
    ];
  };

  # Enable Fish shell system-wide (required for it to be a valid login shell)
  # Without this, setting Fish as default shell would fail
  programs.fish.enable = true;

  # Set Fish as the default shell for all users
  # This adds fish to /etc/shells and sets it in /etc/passwd
  users.defaultUserShell = pkgs.fish;
}
