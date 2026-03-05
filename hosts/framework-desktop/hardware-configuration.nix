# ============================================================================
# PLACEHOLDER - Replace with actual hardware configuration!
# ============================================================================
#
# This file must be replaced with the output of:
#   nixos-generate-config --show-hardware-config
#
# During installation:
#   1. Boot NixOS USB installer
#   2. Partition the 2TB SSD:
#      - ~512MB EFI partition (FAT32)
#      - Remaining: LUKS-encrypted partition with ext4 root
#   3. Mount partitions at /mnt
#   4. Run: nixos-generate-config --root /mnt
#   5. Copy /mnt/etc/nixos/hardware-configuration.nix here
#   6. Build: sudo nixos-rebuild switch --flake .#framework-desktop
#
# Expected structure (for reference):
#   - LUKS encryption device
#   - ext4 root filesystem
#   - FAT32 /boot (EFI)
#   - AMD kernel modules (kvm-amd, amdgpu)
#   - NVMe, USB storage kernel modules
#
# ============================================================================

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # PLACEHOLDER: Replace these with actual UUIDs from nixos-generate-config
  # boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/REPLACE-ME";
  # fileSystems."/" = { device = "/dev/disk/by-uuid/REPLACE-ME"; fsType = "ext4"; };
  # fileSystems."/boot" = { device = "/dev/disk/by-uuid/REPLACE-ME"; fsType = "vfat"; options = [ "fmask=0077" "dmask=0077" ]; };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
