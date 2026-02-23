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
    # Desktop: 1password GUI, hyprland, greetd, podman, PipeWire, desktop groups
    ../common/desktop.nix

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

  # Disable PCIe Active State Power Management (fixes Thunderbolt disconnects)
  boot.kernelParams = [ "pcie_aspm=off" ];

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

  # Disable fingerprint authentication everywhere (password-only)
  security.pam.services.sudo.fprintAuth = false;
  security.pam.services.hyprlock.fprintAuth = false;
  security.pam.services.polkit-1.fprintAuth = false;

  # Load i915 early for faster GPU init and better power management
  boot.initrd.kernelModules = [ "i915" ];

  # Power management
  # auto-cpufreq: automatically switches to performance on AC, powersave on battery
  # fw-fanctrl (below) handles thermal management via custom fan curves
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    charger = {
      governor = "performance";
      turbo = "auto";
    };
    battery = {
      governor = "powersave";
      turbo = "never";
    };
  };
  powerManagement.enable = true;

  # Thunderbolt device authorization (required for USB-C dock/monitor hotplug)
  services.hardware.bolt.enable = true;

  # Disable Thunderbolt power management to prevent USB-C dock/monitor disconnections
  # Set built-in webcam defaults (reduce saturation/sharpness, disable backlight comp)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="video4linux", ATTR{name}=="Laptop Webcam Module (2nd Gen):", RUN+="${pkgs.v4l-utils}/bin/v4l2-ctl -d $devnode --set-ctrl=saturation=51,sharpness=2,backlight_compensation=0,power_line_frequency=2"
  '';

  # ==========================================================================
  # INTEL OPTIMIZATIONS
  # ==========================================================================

  # fw-fanctrl: Custom fan curves for quieter operation
  # "smooth" strategy: constant low fan noise, gradual ramp (no sudden spikes)
  # Benchmarked after repaste: full stress peaks at 84°C, steady state 82°C
  # Revert to default: systemctl stop fw-fanctrl
  hardware.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "smooth";
      strategies = {
        smooth = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 45; # Longer averaging = smoother response
          speedCurve = [
            { temp = 0;  speed = 15; }   # Silent baseline
            { temp = 55; speed = 15; }   # Stay silent up to 55°C
            { temp = 65; speed = 20; }   # Light use
            { temp = 70; speed = 25; }   # Moderate use
            { temp = 75; speed = 35; }   # Ramping up
            { temp = 78; speed = 40; }   # Approaching load zone
            { temp = 80; speed = 50; }   # Full load zone
            { temp = 82; speed = 55; }   # Steady state under stress
            { temp = 84; speed = 60; }   # Observed peak under stress
            { temp = 87; speed = 75; }   # Above normal, ramp up
            { temp = 90; speed = 90; }   # Safety ramp
            { temp = 95; speed = 100; }  # Full blast
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
  # WEBCAM
  # ==========================================================================
  environment.systemPackages = with pkgs; [
    v4l-utils # v4l2-ctl for webcam control
    intel-gpu-tools # intel_gpu_top for GPU monitoring
    libva-utils # vainfo to verify VA-API acceleration
  ];

  # LOGIND - The systemd login manager
  # Controls what happens on lid close, power button, etc.
  # Always ignore lid close - Hyprland handles display switching, suspend manually
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";               # Never suspend on lid close
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
