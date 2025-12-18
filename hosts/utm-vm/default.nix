{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../common
    ./hardware-configuration.nix
  ];

  # Hostname
  networking.hostName = "utm-vm";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VM-specific settings
  services.spice-vdagentd.enable = true;  # Clipboard sharing with host
  services.qemuGuest.enable = true;       # QEMU guest agent

  # Console font (larger for VM)
  console.font = "Lat2-Terminus16";

  # System state version - don't change after install
  system.stateVersion = "24.11";
}
