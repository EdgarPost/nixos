# ============================================================================
# TAILSCALE - Mesh VPN
# ============================================================================
#
# WHAT IS TAILSCALE?
# A zero-config mesh VPN built on WireGuard. Creates a private network
# across all your devices, regardless of location or NAT.
#
# FEATURES:
#   - Connect to home machines from anywhere
#   - Access Roon server remotely
#   - SSH to any machine via Tailscale IP
#   - MagicDNS: access machines by hostname (edgar-framework-laptop.tailnet-name.ts.net)
#
# POST-INSTALL:
#   sudo tailscale up    # Authenticate via browser
#   tailscale status     # See connected devices
#
# ============================================================================

{ pkgs, user, ... }:

{
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--operator=${user.name}" ];
  };

  # Trust Tailscale interface for unrestricted traffic between devices
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ 41641 ];  # Tailscale coordination port
  };

  # CLI tool for status/control
  environment.systemPackages = [ pkgs.tailscale ];
}
