{ config, ... }:
{
  networking.hostName = config.pwnbox.hostName;

  # CONFIG_PACKET is built as a module (af_packet.ko).  hardening.nix sets
  # security.lockKernelModules, which flips kernel.modules_disabled=1 once the
  # system is up, so af_packet has to be loaded before that or PF_PACKET
  # sockets (NetworkManager DHCP, wpa_supplicant, tcpdump) fail afterwards.
  boot.kernelModules = [ "af_packet" ];

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";

    wifi.scanRandMacAddress = true;
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      # "opportunistic" makes resolved probe every DHCP-provided resolver on
      # port 853.  Home routers (e.g. Fritz!Box) do not speak DoT, so after
      # each link/DHCP change the probe fails and lookups can time out until
      # resolved falls back to plain UDP.  Keep plain DNS here; if you want
      # encrypted DNS, point resolved at real DoT servers and use "yes".
      DNSOverTLS = false;
      DNSSEC = "allow-downgrade";
      LLMNR = false;
      MulticastDNS = false;
      Cache = true;
      # Only consulted when no per-link DNS server is known at all -- this is
      # not failover for an unreachable router DNS server.
      FallbackDNS = [
        "9.9.9.9"
        "149.112.112.112"
      ];
    };
  };
}
