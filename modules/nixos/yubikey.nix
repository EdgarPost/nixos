# ============================================================================
# YUBIKEY - Hardware Security Key Support
# ============================================================================
#
# WHAT THIS DOES
#   Makes YubiKeys usable by the normal user (no sudo), and installs the
#   tooling to inspect/manage the key.
#
# WHY UDEV RULES?
#   USB security keys are root-owned by default. `yubikey-personalization`
#   ships the upstream udev rules that tag YubiKey USB devices, so udev's
#   uaccess builtin grants the locally logged-in user access.
#   Without them every `ykman` call needs sudo.
#
# SCOPE
#   Only base support. No PAM login, no SSH keys, no PIV/OpenPGP yet —
#   those land as separate phases so a broken config can't lock you out.
#
# VERIFY
#   Plug in a key and run:  ykman info
#   List passkey/SSH credentials:  ykman fido credentials list
#
# ============================================================================

{ pkgs, ... }:

{
  # Upstream udev rules (70-yubikey.rules) -> unprivileged device access
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Smart card (CCID) daemon. Not needed for FIDO2/SSH/passkeys (those use
  # USB-HID), but the key exposes PIV/OpenPGP too -- this silences ykman's
  # "PC/SC not available" warning and is required for PIV tooling later.
  services.pcscd.enable = true;

  environment.systemPackages = with pkgs; [
    yubikey-manager # ykman: info, PIN, FIDO2/OATH/PIV management
    libfido2 # fido2-token -L: list FIDO devices/credentials (diagnostic)
  ];
}
