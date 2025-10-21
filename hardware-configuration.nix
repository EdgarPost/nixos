# This file defines hardware-specific configuration for the Framework laptop
# IMPORTANT: This is a TEMPLATE. When you actually install NixOS, the installer
# will generate a hardware-configuration.nix based on your actual hardware.
# You should then merge these Framework-specific settings with the generated file.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Framework laptops use Intel CPUs - enable microcode updates
  # This provides security and stability fixes from Intel
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Boot configuration
  boot = {
    # Use the systemd-boot EFI bootloader (modern and simple)
    loader = {
      systemd-boot.enable = true;
      # Allow editing boot options before booting
      efi.canTouchEfiVariables = true;
    };

    # Load kernel modules for Framework hardware
    initrd = {
      availableKernelModules = [
        "xhci_pci"      # USB 3.0 support
        "thunderbolt"   # Thunderbolt/USB4 support
        "nvme"          # NVMe SSD support
        "usb_storage"   # USB storage
        "sd_mod"        # SD card reader
      ];
      kernelModules = [ ];
    };

    kernelModules = [ "kvm-intel" ];  # Enable KVM virtualization
    extraModulePackages = [ ];

    # Kernel parameters for Framework laptop
    kernelParams = [
      # Improve power management
      "mem_sleep_default=deep"
    ];
  };

  # Filesystem configuration for 2TB drive
  # IMPORTANT: These are example UUIDs. When installing, you'll need to:
  # 1. Partition your disk as described
  # 2. Format the partitions
  # 3. Run 'nixos-generate-config' which will detect the real UUIDs
  # 4. Replace these UUIDs with your actual ones
  #
  # Recommended partitioning scheme:
  # - 512MB EFI partition (/boot)
  # - 1GB swap partition (for hibernation/suspend)
  # - 300GB root partition (/)
  # - Remaining ~1.7TB for /home
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-ROOT-UUID";
    fsType = "ext4";
    options = [ "noatime" ];  # Improve SSD performance
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-BOOT-UUID";
    fsType = "vfat";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-HOME-UUID";
    fsType = "ext4";
    options = [ "noatime" ];  # Improve SSD performance
  };

  swapDevices = [{
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-SWAP-UUID";
  }];

  # Framework-specific hardware support
  hardware = {
    # Enable firmware with potentially unfree licenses (needed for WiFi, etc.)
    enableRedistributableFirmware = true;

    # OpenGL/Graphics support
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    # Bluetooth support
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Power management for laptop
  powerManagement = {
    enable = true;
    # Enable powertop for power optimization
    powertop.enable = true;
  };

  # TLP for better battery life
  services.tlp = {
    enable = true;
    settings = {
      # Framework-optimized settings
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # Keep battery between 20-80% for longevity
      START_CHARGE_THRESH_BAT0 = 20;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # Enable fwupd for firmware updates (important for Framework laptops!)
  services.fwupd.enable = true;

  # Networking
  networking.useDHCP = lib.mkDefault true;
  # You'll set the hostname during installation or in configuration.nix
}
