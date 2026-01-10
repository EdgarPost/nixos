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
    ../../modules/nixos/bluetooth.nix   # Bluetooth audio with high-quality codecs
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
  boot.loader.systemd-boot.configurationLimit = 5;  # Only show 5 generations in boot menu
  boot.loader.efi.canTouchEfiVariables = true;      # Allow UEFI variable writes

  # ==========================================================================
  # FRAMEWORK-SPECIFIC HARDWARE
  # ==========================================================================

  # Fingerprint reader (Framework uses Goodix sensor)
  # After enabling, enroll fingerprint with: fprintd-enroll
  services.fprintd.enable = true;

  # Enable fingerprint authentication for screen unlock and 1Password (not sudo/terminal)
  security.pam.services.sudo.fprintAuth = false;  # Explicitly disable for terminal
  security.pam.services.hyprlock.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;

  # Power management for better battery life
  # power-profiles-daemon: GUI-controllable profiles (power-saver, balanced, performance)
  # powerManagement: kernel-level power saving features
  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;

  # ==========================================================================
  # INTEL OPTIMIZATIONS
  # ==========================================================================

  # Thermald: Proactive thermal management for Intel CPUs
  # Prevents overheating before hardware throttling kicks in
  # Uses DPTF adaptive tables for intelligent fan control
  services.thermald.enable = true;

  # fw-fanctrl: Custom fan curves for quieter operation
  # Default strategy keeps fans off until 65°C, then ramps gradually
  # Revert to default: systemctl stop fw-fanctrl
  hardware.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "lazy";
      strategies = {
        lazy = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 30;
          speedCurve = [
            { temp = 0; speed = 0; }
            { temp = 65; speed = 0; }
            { temp = 70; speed = 25; }
            { temp = 75; speed = 50; }
            { temp = 80; speed = 75; }
            { temp = 85; speed = 100; }
          ];
        };
      };
    };
  };

  # Intel graphics (VAAPI hardware video acceleration)
  # Required for efficient video playback/encoding
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API driver for Broadwell+ (iHD)
      vpl-gpu-rt         # Intel oneVPL GPU runtime for Quick Sync Video
    ];
  };

  # Tell applications to use Intel's iHD driver for VA-API
  environment.variables.LIBVA_DRIVER_NAME = "iHD";

  # ==========================================================================
  # WEBCAM (Logitech C920)
  # ==========================================================================
  # v4l2 utilities for webcam control and testing
  # Test with: v4l2-ctl --list-devices
  # View feed: mpv av://v4l2:/dev/video0
  environment.systemPackages = with pkgs; [
    v4l-utils # v4l2-ctl for webcam control
  ];

  # LOGIND - The systemd login manager
  # Controls what happens on lid close, power button, etc.
  # On battery: suspend. On AC power: let Hyprland handle it (disables internal display)
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";              # Suspend when lid closed (battery)
    HandleLidSwitchExternalPower = "ignore";  # Let Hyprland handle (disables eDP-1)
    HandleLidSwitchDocked = "ignore";         # Keep running if docked
    HandlePowerKey = "ignore";                # Let Hyprland show confirmation menu
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
