# ============================================================================
# ROON BRIDGE - Audio Endpoint for Roon
# ============================================================================
{ pkgs, hosts, ... }:

{
  # Roon Bridge service
  services.roon-bridge = {
    enable = true;
    openFirewall = true;
  };

  # RAAT uses dynamic high ports for audio streaming (TCP) and clock sync (UDP)
  # Official docs only mention 9100-9200, but RAAT binds random high ports
  # See: https://community.roonlabs.com/t/roon-bridge-network-ports/55839
  #
  # Allow from:
  # - Roon Core (pbstation) on local LAN
  # - Tailscale network (trustedInterface handles this)
  networking.firewall.extraCommands = ''
    iptables -A INPUT -p tcp -s ${hosts.pbstation} --dport 30000:65535 -j ACCEPT
    iptables -A INPUT -p udp -s ${hosts.pbstation} --dport 30000:65535 -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D INPUT -p tcp -s ${hosts.pbstation} --dport 30000:65535 -j ACCEPT || true
    iptables -D INPUT -p udp -s ${hosts.pbstation} --dport 30000:65535 -j ACCEPT || true
  '';

  # PipeWire for desktop audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Add roon-bridge user to audio group
  users.users.roon-bridge.extraGroups = [ "audio" ];

  # ALSA tools for debugging
  environment.systemPackages = [ pkgs.alsa-utils ];
}
