# ============================================================================
# RASPBERRY PI 4B - AdGuard Home (DNS + DHCP Appliance)
# ============================================================================
#
# Headless network appliance running AdGuard Home for DNS + DHCP.
# Draws ~3W, runs 24/7 — much better fit than Synology for always-on
# network infrastructure.
#
# FIRST BOOT:
#   1. Flash NixOS aarch64 SD image
#   2. Boot, run nixos-generate-config to get real hardware-configuration.nix
#   3. nixos-rebuild switch --flake .#pi-adguard
#
# ADGUARD SETUP:
#   Visit http://<pi-ip>:8082 for AdGuard Home web UI.
#
# ============================================================================

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Shared base: SSH, fail2ban, Tailscale, users, Nix settings
    ../common

    # Hardware config (regenerate on actual hardware)
    ./hardware-configuration.nix

    # RPi 4 hardware optimizations from nixos-hardware
    inputs.nixos-hardware.nixosModules.raspberry-pi-4

    # AdGuard Home (DNS + DHCP)
    ../../modules/nixos/adguard.nix
  ];
  # NOTE: Does NOT import ../common/desktop.nix — this is a headless server

  networking.hostName = "pi-adguard";

  # Syncthing not needed on a network appliance
  services.syncthing.enable = lib.mkForce false;

  # ==========================================================================
  # BOOTLOADER
  # ==========================================================================
  # RPi 4 uses U-Boot/extlinux, not systemd-boot (no UEFI)
  boot.loader.generic-extlinux-compatible.enable = true;

  # ==========================================================================
  # STATE VERSION
  # ==========================================================================
  system.stateVersion = "25.05";
}
