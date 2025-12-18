{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../common
    ./hardware-configuration.nix
    # Framework-specific optimizations from nixos-hardware
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
  ];

  # Hostname
  networking.hostName = "framework";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Framework-specific settings
  # Fingerprint reader
  services.fprintd.enable = true;

  # Power management (better battery life)
  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # Display scaling (12" screen benefits from fractional scaling)
  # Uncomment if needed with Hyprland
  # environment.variables = {
  #   GDK_SCALE = "1.5";
  #   GDK_DPI_SCALE = "0.67";
  # };

  # System state version - adjust to your NixOS version
  system.stateVersion = "25.05";
}
