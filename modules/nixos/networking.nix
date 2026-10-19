{ config, ... }:
{
  networking.hostName = config.pwnbox.hostName;

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";

    wifi.scanRandMacAddress = true;
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSOverTLS = "opportunistic";
      DNSSEC = "allow-downgrade";
      LLMNR = false;
      MulticastDNS = false;
      Cache = true;
      FallbackDNS = [
        "9.9.9.9"
        "149.112.112.112"
      ];
    };
  };
}
