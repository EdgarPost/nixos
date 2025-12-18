{ config, pkgs, lib, ... }:

{
  imports = [
    ./users.nix
    ../../modules/nixos/1password.nix
    ../../modules/nixos/hyprland.nix
    ../../modules/nixos/greetd.nix
  ];

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      warn-dirty = false;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Timezone and locale
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # Networking
  networking.networkmanager.enable = true;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    tree
    ripgrep
    fd
  ];

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Security
  security.sudo.wheelNeedsPassword = true;
}
