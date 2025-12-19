# ============================================================================
# COMMON HOST CONFIGURATION - Shared Across All Machines
# ============================================================================
#
# WHAT IS A NIXOS MODULE?
# A module is a function that takes arguments and returns configuration.
# The function signature below is the standard NixOS module pattern:
#
#   { config, pkgs, lib, ... }:
#
# Available arguments (provided automatically by NixOS):
#   config - The full merged configuration (read other module's settings)
#   pkgs   - The nixpkgs package set (all 100k+ packages)
#   lib    - Utility functions (lists, strings, attrsets, conditionals)
#   ...    - Catches additional args (like our custom `inputs`, `user`)
#
# MODULE MERGING:
# NixOS merges all modules recursively. If two modules set the same option:
#   - Lists are concatenated
#   - Attrsets are merged (nested)
#   - Scalars conflict (error) unless one uses lib.mkForce or lib.mkDefault
#
# ============================================================================

{ config, pkgs, lib, ... }:

{
  # IMPORTS - Include other modules
  # Paths are relative to this file. Each import adds its config to the merge.
  imports = [
    ./users.nix                        # User account definitions
    ../../modules/nixos/1password.nix  # Password manager
    ../../modules/nixos/hyprland.nix   # Desktop compositor
    ../../modules/nixos/greetd.nix     # Login manager
    ../../modules/nixos/podman.nix     # Container runtime
  ];

  # ==========================================================================
  # NIX DAEMON SETTINGS
  # ==========================================================================
  # The Nix daemon handles all package operations. These settings affect
  # how packages are built, stored, and garbage collected.

  nix = {
    settings = {
      # Enable modern Nix features (required for flakes)
      # "nix-command" = new CLI syntax (nix build vs nix-build)
      # "flakes" = the flake system we're using
      experimental-features = [ "nix-command" "flakes" ];

      # Deduplicate store paths via hard links (saves disk space)
      # /nix/store contains all packages; many share identical files
      auto-optimise-store = true;

      # Don't warn when building with uncommitted changes
      # Useful during development, disable for production purity
      warn-dirty = false;
    };

    # GARBAGE COLLECTION - Reclaim disk space
    # The Nix store never deletes packages unless told to, allowing
    # rollback to any previous generation. GC removes unreferenced packages.
    gc = {
      automatic = true;
      dates = "weekly";                    # systemd calendar format
      options = "--delete-older-than 7d";  # Keep 7 days of generations
    };
  };

  # Allow proprietary packages (drivers, some apps)
  # NixOS is FOSS by default; this enables packages with non-free licenses
  nixpkgs.config.allowUnfree = true;

  # ==========================================================================
  # SYSTEM SETTINGS
  # ==========================================================================

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # NetworkManager: The standard Linux network configuration tool
  # Provides nmcli, nmtui, and integrates with desktop applets
  networking.networkmanager.enable = true;

  # ==========================================================================
  # SYSTEM PACKAGES
  # ==========================================================================
  # Packages installed system-wide (available to all users).
  # Unlike traditional distros, these don't pollute the global namespace:
  #   - Installed in /nix/store/<hash>-<name>/
  #   - Symlinked into /run/current-system/sw/bin/
  #   - Can't conflict with user packages or each other
  #
  # SYNTAX: `with pkgs;` brings all package names into scope
  # Without it: [ pkgs.git pkgs.vim pkgs.curl ... ]
  # With it:    [ git vim curl ... ]

  environment.systemPackages = with pkgs; [
    git       # Version control (also needed for flake operations)
    vim       # Fallback editor (neovim is user-level)
    curl      # HTTP client
    wget      # File downloader
    htop      # Process viewer
    tree      # Directory tree
    ripgrep   # Fast grep (rg)
    fd        # Fast find
  ];

  # ==========================================================================
  # SERVICES
  # ==========================================================================
  # NixOS manages system services declaratively. Instead of:
  #   systemctl enable sshd && systemctl start sshd
  # You declare intent; NixOS handles the rest (and removes on disable).

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;  # SSH keys only (more secure)
      PermitRootLogin = "no";          # Force normal user + sudo
    };
  };

  # ==========================================================================
  # SECURITY
  # ==========================================================================

  # Require password for sudo (wheel group can sudo, but must authenticate)
  security.sudo.wheelNeedsPassword = true;
}
