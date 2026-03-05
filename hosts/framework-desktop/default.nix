# ============================================================================
# FRAMEWORK DESKTOP CONFIGURATION - Host-Specific Settings
# ============================================================================
#
# Framework Desktop (AMD Ryzen AI Max+ 395 / Radeon 8060S / 128GB LPDDR5x)
# Primary workstation connected to Dell U4025QW ultrawide at 5120x2160@120Hz.
# Used for heavier workloads (LLMs, development) and gaming (Steam).
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
    # Includes: AMD CPU/GPU config, SSD support, framework-tool, fwupd
    # Requires kernel 6.14+, recommends 6.15+
    inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series

    # Framework-specific services
    ../../modules/nixos/roon-bridge.nix # Roon audio endpoint
    ../../modules/nixos/bluetooth.nix   # Bluetooth audio with high-quality codecs
  ];

  # Syncthing - full PARA sync on this machine
  services.syncthing.paraFolders = true;

  # Machine identity on the network
  networking.hostName = "edgar-framework-desktop";

  # ==========================================================================
  # BOOTLOADER
  # ==========================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  # ==========================================================================
  # AMD GPU - Hardware Video Acceleration
  # ==========================================================================
  # The nixos-hardware module handles: amdgpu driver, graphics enable, 32-bit support
  # Add VA-API packages for hardware video decode (YouTube, video calls, etc.)
  hardware.graphics.extraPackages = with pkgs; [
    libvdpau-va-gl # VDPAU via VA-API for AMD
  ];

  environment.systemPackages = with pkgs; [
    libva-utils # vainfo to verify VA-API acceleration
  ];

  # ==========================================================================
  # STEAM - Gaming
  # ==========================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Allow Steam Remote Play (Steam Deck streaming)
  };

  # ==========================================================================
  # FIRMWARE UPDATES
  # ==========================================================================
  # Framework actively supports Linux firmware updates
  # Check/update with: fwupdmgr refresh && fwupdmgr update
  services.fwupd.enable = true;

  # ==========================================================================
  # STATE VERSION
  # ==========================================================================
  system.stateVersion = "25.05";
}
