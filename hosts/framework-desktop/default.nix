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
    ../../modules/nixos/sunshine.nix    # Game streaming server (Moonlight)
    ../../modules/nixos/llama.nix       # Local LLM inference (llama.cpp + Vulkan)
    ../../modules/nixos/librechat.nix   # AI chat interface (port 3080)
    ../../modules/nixos/bifrost.nix     # AI gateway proxy (port 4000, replaces litellm)
    ../../modules/nixos/bazecor.nix     # Dygma Defy keyboard configurator
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
    libva-utils  # vainfo to verify VA-API acceleration
    mangohud     # FPS/CPU/GPU monitoring overlay (launch with mangohud %command%)
    protonup-qt  # Install/manage custom Proton versions (GE-Proton for better compat)
    protontricks # Manage Proton prefixes and install Windows dependencies
    vulkan-tools # vulkaninfo to verify Vulkan support
  ];

  # ==========================================================================
  # STEAM - Gaming
  # ==========================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Allow Steam Remote Play (Steam Deck streaming)
    gamescopeSession.enable = true; # Gamescope micro-compositor (Steam Deck-like session)
    # Extra libs injected into Steam's FHS sandbox (needed by EAC and some games)
    extraPackages = with pkgs; [
      pango
      libthai
      harfbuzz
      gnutls
      SDL2
    ];
  };

  # Steam renders at 1x by default, causing pixelation with fractional scaling.
  # Force Steam UI to render at the monitor's scale factor (1.25).
  environment.sessionVariables.STEAM_FORCE_DESKTOPUI_SCALING = "1.25";

  # Limit Wine/Proton CPU topology to 16 cores.
  # EAC crashes on high-core-count CPUs (Ryzen AI Max+ 395 has 32 threads).
  environment.sessionVariables.WINE_CPU_TOPOLOGY = "16:0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15";

  # GameMode: applies CPU/GPU performance optimizations while gaming
  # Games can request this automatically, or launch manually with gamemoderun
  programs.gamemode.enable = true;

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
