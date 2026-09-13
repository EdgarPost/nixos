# ============================================================================
# PRINTING - CUPS + Network Printer Discovery
# ============================================================================
#
# Canon network printer (driverless via IPP Everywhere / AirPrint).
#
# Why network printers "don't show up" out of the box on NixOS:
#   - CUPS (the print service) is not enabled by default.
#   - Network printers are discovered over mDNS/DNS-SD (Bonjour), which
#     requires Avahi to be running in *browsing* mode, not just publishing.
#   - cups-browsed turns those DNS-SD broadcasts into permanent CUPS queues,
#     so the printer appears in the GTK print dialog automatically.
#
# Driverless means no vendor driver is needed: the printer advertises itself
# as an IPP Everywhere / AirPrint device and CUPS talks to it directly.
# If a specific Canon model ever needs closed drivers, add e.g.:
#   services.printing.drivers = [ pkgs.cnijfilter2 ];
#
# ============================================================================

{ ... }:

{
  services.printing = {
    enable = true; # CUPS print spooler (web UI at http://localhost:631)
    browsed.enable = true; # cups-browsed: auto-discover network printers
  };

  # Avahi (mDNS/DNS-SD) — required for browsing Bonjour/AirPrint printers on
  # the local network. The desktop host also enables Avahi via roon-bridge.nix
  # for *publishing*; this adds the discovery side (harmless to merge).
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Resolve *.local hostnames (also used by printer UIs)
    openFirewall = true; # Let mDNS (UDP 5353) through the firewall
  };
}