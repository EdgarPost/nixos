# ============================================================================
# ADGUARD HOME - Network-wide DNS + DHCP
# ============================================================================
#
# Native NixOS service — no container overhead, ideal for always-on Pi.
#
# HOW SETTINGS WORK:
#   `settings` below set the INITIAL AdGuardHome.yaml on first boot.
#   mutableSettings (default true) lets AdGuard modify its config at runtime
#   via the web UI — DHCP leases, filter updates, client edits all persist.
#   On subsequent rebuilds, Nix won't overwrite runtime changes.
#
# WEB UI:
#   http://<host-ip>:8082 (port kept from Synology config)
#
# DHCP:
#   allowDHCP grants CAP_NET_RAW + CAP_NET_BIND_SERVICE for broadcast.
#   Interface name will need updating to match the Pi's actual NIC.
#
# ============================================================================

{ config, pkgs, ... }:

{
  services.adguardhome = {
    enable = true;

    # Allow DHCP server (grants necessary capabilities for broadcast)
    allowDHCP = true;

    # Initial configuration — ported from Synology AdGuardHome.yaml
    # AdGuard can modify this at runtime via the web UI
    settings = {
      http.address = "0.0.0.0:8082";

      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;

        # Quad9 encrypted DNS upstreams
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
          "tls://dns.quad9.net"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "149.112.112.112"
          "2620:fe::fe"
          "2620:fe::9"
        ];

        upstream_mode = "parallel";
        enable_dnssec = true;
        cache_enabled = true;
        cache_size = 4194304;
        ratelimit = 0;
        refuse_any = true;
      };

      dhcp = {
        enabled = true;
        interface_name = "end0"; # RPi 4 ethernet — verify with `ip link`
        local_domain_name = "lan";
        dhcpv4 = {
          gateway_ip = "192.168.2.254";
          subnet_mask = "255.255.255.0";
          range_start = "192.168.2.1";
          range_end = "192.168.2.200";
          lease_duration = 86400;
        };
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        rewrites_enabled = true;

        blocking_mode = "default";
        blocked_services = {
          ids = [ "facebook" ];
        };

        # Local DNS rewrites
        rewrites = [
          { domain = "pbstation"; answer = "192.168.2.10"; }
          { domain = "*.postbuijs.local"; answer = "192.168.2.10"; }
        ];
      };

      # Filter lists
      filters = [
        { enabled = true; url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt"; name = "AdGuard DNS filter"; id = 1; }
        { enabled = true; url = "https://adaway.org/hosts.txt"; name = "AdAway Default Blocklist"; id = 2; }
        { enabled = true; url = "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@main/adblock/pro.txt"; name = "HaGeZi Pro"; id = 3; }
        { enabled = true; url = "https://big.oisd.nl"; name = "OISD Big"; id = 4; }
        { enabled = true; url = "https://gitlab.com/hagezi/mirror/-/raw/main/dns-blocklists/adblock/tif.txt"; name = "HaGeZi TIF"; id = 5; }
      ];

      # Custom user rules
      user_rules = [
        "||viva.nl^"
        "@@||plausible.io^"
        "||fpinit-eu.edge-itunes-apple.com.akadns.net^$client='192.168.2.16'"
        "@@||6272cf2df5b0d01e8bb63ce725b5e5045652076ef6b261f96688f874e207786.us-east-1.prod.service.minerva.devices.a2z.com^$important"
        "||forum.fok.nl^$client='Edgar iPhone'"
        "@@||click.figma.com^$important"
        "@@||prodregistryv2.org^$important"
        "@@||d37gvrvc0wt4s1.cloudfront.net^$important"
        "@@||sdk.split.io^$important"
        "@@||statsig.anthropic.com^$important"
        "@@||www.posthog.com^$important"
        "@@||posthog.com^$important"
      ];

      # Per-client overrides (kids' devices, parental controls, etc.)
      clients.persistent = [
        {
          name = "Edgar iPhone";
          ids = [ "ba:90:93:b8:24:15" ];
          use_global_settings = true;
          use_global_blocked_services = true;
          blocked_services.ids = [ "reddit" "youtube" ];
        }
        {
          name = "Edgar's Macbook Pro 14\"";
          ids = [ "f8:4d:89:68:66:b2" ];
          use_global_settings = true;
          use_global_blocked_services = false;
          filtering_enabled = true;
          safebrowsing_enabled = true;
        }
        {
          name = "Joan iPhone";
          ids = [ "192.168.2.16" ];
          use_global_settings = true;
          use_global_blocked_services = true;
          blocked_services.ids = [ "reddit" ];
        }
        {
          name = "Macbook Pop!_OS";
          ids = [ "192.168.2.8" ];
          use_global_settings = false;
          use_global_blocked_services = false;
          filtering_enabled = true;
          parental_enabled = true;
          safebrowsing_enabled = true;
          safe_search.enabled = true;
        }
        {
          name = "iPad Norah";
          ids = [ "c2:69:9a:15:09:a8" ];
          use_global_settings = false;
          use_global_blocked_services = true;
          filtering_enabled = true;
          parental_enabled = true;
          safebrowsing_enabled = true;
          safe_search.enabled = true;
        }
      ];

      querylog = {
        enabled = true;
        interval = "168h";
        size_memory = 1000;
        file_enabled = true;
      };

      statistics = {
        enabled = true;
        interval = "24h";
      };
    };
  };

  # Open firewall ports
  networking.firewall = {
    allowedTCPPorts = [
      53    # DNS
      8082  # Web UI
    ];
    allowedUDPPorts = [
      53    # DNS
      67    # DHCP server
      68    # DHCP client
    ];
  };
}
