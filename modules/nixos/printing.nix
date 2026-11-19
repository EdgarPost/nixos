# ============================================================================
# PRINTING - CUPS + a permanent queue for the Canon TS5300
# ============================================================================
#
# The printer is an IPP Everywhere / Mopria device (see its mDNS TXT record),
# so no vendor driver is needed: CUPS' built-in "everywhere" driver rasterizes
# PDFs to Apple Raster (URF V1.4), which is exactly what it advertises.
#
# Why the queue is declared here instead of being discovered:
#
#   * cups-browsed publishes an *implicitclass* queue and deletes the member
#     printer behind it when the daemon stops. What is left is an empty class,
#     disabled with "Printer disappeared or cups-browsed shutdown" - and CUPS
#     silently fails jobs sent to an empty class (see the doc of
#     nixos/modules/hardware/printers.nix). That is what happened here: a 27k
#     PDF sat in "pending" on Canon_TS5300_series for good, printer untouched.
#   * cups-browsed's own dnssd:// URI for this printer carries Canon's all-zero
#     UUID (...?uuid=00000000-0000-1000-8000-00188b0d3688), which cupsd's mDNS
#     resolver rejects with "Couldn't resolve mDNS URI". Drop the UUID and it
#     resolves - but then cupsd rewrites the queue to
#     "ipp://6D997C000000.local:631/ipp/print", a name glibc cannot resolve
#     here: systemd-resolved answers mDNS for it with only an unusable
#     link-local IPv6 address, so lookups end in EAI_AGAIN.
#
#   Hence the explicit IPv4 address. It has to stay put, so give the printer a
#   DHCP reservation (or a static address in its own web UI). Moves = update
#   deviceUri below.
#
# lpadmin runs from cups.service's ExecStartPost, so the queue is recreated on
# every boot and rebuild. It queries the printer for its attributes, so if the
# printer is off when cups starts, that ExecStartPost fails and cups.service is
# marked failed - cupsd itself keeps running, `systemctl restart cups` fixes it.
#
# ============================================================================

{ ... }:

{
  services.printing = {
    enable = true; # CUPS print spooler (web UI at http://localhost:631)
    # Keep forced off: with avahi enabled it defaults to on, and the ephemeral
    # queue it creates would fight the static one below.
    browsed.enable = false;
  };

  hardware.printers = {
    ensureDefaultPrinter = "Canon_TS5300_series";
    ensurePrinters = [
      {
        name = "Canon_TS5300_series";
        description = "Canon PIXMA TS5300 series (IPP Everywhere)";
        deviceUri = "ipp://192.168.2.233:631/ipp/print";
        model = "everywhere"; # `lpinfo -m` calls it "everywhere IPP Everywhere"
      }
    ];
  };

  # Avahi (mDNS/DNS-SD). Not needed by the queue above, but the printer is also
  # a scanner and the Roon bridge on this host publishes over mDNS; the desktop
  # host enables Avahi in roon-bridge.nix anyway.
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Resolve *.local hostnames (also used by printer UIs)
    openFirewall = true; # Let mDNS (UDP 5353) through the firewall
  };
}
