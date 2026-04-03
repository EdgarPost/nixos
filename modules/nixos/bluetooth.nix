# ============================================================================
# BLUETOOTH AUDIO CONFIGURATION
# ============================================================================
#
# Enables Bluetooth with high-quality audio codec support for wireless
# headphones, speakers, and other Bluetooth audio devices.
#
# Codecs enabled:
# - SBC-XQ: High-quality SBC variant
# - mSBC: Wideband speech codec for headset mic
# - Hardware volume: Sync volume with device
#
# ============================================================================

{ config, pkgs, ... }:

{
  # Enable Bluetooth hardware support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true; # Better codec negotiation
        Privacy = "device";
        JustWorksRepairing = "always";
        Class = "0x000100";
        FastConnectable = true;
      };
    };
  };

  # Xbox One wireless controller support
  hardware.xpadneo.enable = true;

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
    extraModprobeConfig = ''
      options bluetooth disable_ertm=Y
    '';
  };

  # Blueman: GTK Bluetooth manager (tray icon, pairing GUI)
  services.blueman.enable = true;

  # WirePlumber Bluetooth audio configuration
  # Enables high-quality codecs and proper headset profile support
  environment.etc."wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
    bluez_monitor.properties = {
      ["bluez5.enable-sbc-xq"] = true,
      ["bluez5.enable-msbc"] = true,
      ["bluez5.enable-hw-volume"] = true,
      ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
    }
  '';
}
