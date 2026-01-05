# ============================================================================
# BLUETOOTH AUDIO CONFIGURATION
# ============================================================================
#
# Enables Bluetooth with high-quality audio codec support for:
# - Sennheiser HD 600 wireless (via BT700 USB adapter)
# - Other Bluetooth audio devices
#
# Codecs enabled:
# - SBC-XQ: High-quality SBC variant
# - mSBC: Wideband speech codec for headset mic
# - Hardware volume: Sync volume with device
#
# ============================================================================

{ pkgs, ... }:

{
  # Enable Bluetooth hardware support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true; # Better codec negotiation
      };
    };
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
