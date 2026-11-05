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
  # tailscale0 is trusted (see tailscale.nix), but pbstation is on the same LAN
  # and Roon uses that path: its control channel lands on tcp/9200 (opened by
  # openFirewall) from 192.168.2.10, while the per-device RAAT ports it then
  # needs (dynamic, e.g. tcp/39399) were refused - which hangs "enable device"
  # in the Roon client. Allow the Core's LAN IP to the dynamic range.
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p tcp -s 192.168.2.10 --dport 30000:65535 -j ACCEPT
    iptables -A INPUT -p udp -s 192.168.2.10 --dport 30000:65535 -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D INPUT -p tcp -s 192.168.2.10 --dport 30000:65535 -j ACCEPT || true
    iptables -D INPUT -p udp -s 192.168.2.10 --dport 30000:65535 -j ACCEPT || true
  '';

  # Avahi (mDNS/DNS-SD) for Roon Core to auto-discover this bridge on the network
  # `publish.*` is obsolete since 26.11; the freeform settings map 1:1 to
  # avahi-daemon.conf's [publish] section.
  services.avahi = {
    enable = true;
    settings.publish = {
      disable-publishing = false;
      disable-user-service-publishing = false;
      publish-addresses = true;
    };
  };

  # Add roon-bridge user to audio group
  users.users.roon-bridge.extraGroups = [ "audio" ];

  # ALSA tools for debugging
  environment.systemPackages = [ pkgs.alsa-utils ];
}
