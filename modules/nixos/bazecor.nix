# ============================================================================
# BAZECOR - Dygma Keyboard Configuration
# ============================================================================
#
# Bazecor is the configuration tool for Dygma keyboards (Raise, Defy).
# Requires udev rules for USB/HID access to the keyboard hardware.
#
# ============================================================================

{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.bazecor ];

  # Udev rules for Dygma keyboards (USB + HID access)
  services.udev.packages = [ pkgs.bazecor ];
}
