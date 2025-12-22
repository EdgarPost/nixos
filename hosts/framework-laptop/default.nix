# ============================================================================
# FRAMEWORK LAPTOP CONFIGURATION - Host-Specific Settings
# ============================================================================
#
# HOST-SPECIFIC VS COMMON CONFIGURATION:
# This file contains settings specific to this machine. The pattern is:
#   1. Import common config (shared across all hosts)
#   2. Import hardware-configuration.nix (auto-generated, describes hardware)
#   3. Add host-specific settings (hostname, bootloader, device features)
#
# This separation allows the same dotfiles to work on multiple machines
# (laptop, desktop, VM) with different hardware configurations.
#
# ============================================================================

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Shared configuration across all hosts
    ../common

    # AUTO-GENERATED FILE - Do not edit manually!
    # Created by `nixos-generate-config` during installation
    # Contains: filesystem mounts, kernel modules for detected hardware
    # Regenerate with: nixos-generate-config --show-hardware-config
    ./hardware-configuration.nix

    # NIXOS-HARDWARE MODULE
    # Community-maintained hardware-specific optimizations
    # Includes: power management, firmware quirks, driver settings
    # The `inputs` variable comes from specialArgs (defined in flake.nix)
    # Browse available: github.com/NixOS/nixos-hardware
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel

    # Framework-specific services
    ../../modules/nixos/roon-bridge.nix # Roon audio endpoint
  ];

  # Syncthing - full PARA sync on this machine
  services.syncthing.paraFolders = true;

  # Machine identity on the network
  networking.hostName = "edgar-framework-laptop";

  # ==========================================================================
  # BOOTLOADER
  # ==========================================================================
  # NixOS supports multiple bootloaders. systemd-boot is the modern UEFI
  # bootloader that integrates well with NixOS generations (rollback!).
  # Alternative: GRUB for legacy BIOS or dual-boot scenarios

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;  # Allow UEFI variable writes

  # ==========================================================================
  # FRAMEWORK-SPECIFIC HARDWARE
  # ==========================================================================

  # Fingerprint reader (Framework uses Goodix sensor)
  # After enabling, enroll fingerprint with: fprintd-enroll
  services.fprintd.enable = true;

  # Power management for better battery life
  # power-profiles-daemon: GUI-controllable profiles (power-saver, balanced, performance)
  # powerManagement: kernel-level power saving features
  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;

  # LOGIND - The systemd login manager
  # Controls what happens on lid close, power button, etc.
  # "Docked" means external display connected (lid close doesn't suspend)
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";              # Suspend when lid closed (battery)
    HandleLidSwitchExternalPower = "suspend"; # Also suspend on AC power
    HandleLidSwitchDocked = "ignore";         # Keep running if external monitor
  };

  # FIRMWARE UPDATES via fwupd
  # Framework actively supports Linux firmware updates
  # Check/update with: fwupdmgr refresh && fwupdmgr update
  services.fwupd.enable = true;

  # ==========================================================================
  # DISPLAY SCALING (optional)
  # ==========================================================================
  # The 12" 2256x1504 screen (3:2 ratio) has ~200 DPI
  # Wayland/Hyprland handles this per-monitor; these are GTK fallbacks
  # environment.variables = {
  #   GDK_SCALE = "1.5";       # Integer scaling factor
  #   GDK_DPI_SCALE = "0.67";  # Counter-scale text (1/1.5)
  # };

  # ==========================================================================
  # STATE VERSION - Important for Upgrades
  # ==========================================================================
  # This does NOT set your NixOS version - that comes from nixpkgs input.
  # Instead, it tells NixOS which defaults to use for stateful things.
  #
  # NEVER change this after installation unless you read the release notes
  # and manually handle any migrations. It's like a database schema version.
  #
  # Example: stateVersion "23.11" might default to ext4, while "24.05"
  # might default to btrfs. Changing it won't convert your filesystem!
  #
  # Check current NixOS version: nixos-version
  system.stateVersion = "25.05";
}
