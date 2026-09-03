# ============================================================================
# ROON BRIDGE - Audio Endpoint for Roon
# ============================================================================
{ pkgs, ... }:

{
  # Roon Bridge service (roon-bridge 2.60.1501 from nixpkgs since 2026-08)
  services.roon-bridge = {
    enable = true;
    openFirewall = true;
  };

  # RAAT uses dynamic high ports for audio streaming (TCP) and clock sync (UDP)
  # Official docs only mention 9100-9200, but RAAT binds random high ports
  # See: https://community.roonlabs.com/t/roon-bridge-network-ports/55839
  #
  # Roon Core (pbstation) is reached over Tailscale (MagicDNS), and the
  # tailscale0 interface is trusted by the firewall (see tailscale.nix), so no
  # explicit source-IP rules are needed here.

  # Avahi (mDNS/DNS-SD) for Roon Core to auto-discover this bridge on the network
  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
  };

  # Add roon-bridge user to audio group
  users.users.roon-bridge.extraGroups = [ "audio" ];

  # ALSA tools for debugging
  environment.systemPackages = [ pkgs.alsa-utils ];
}
