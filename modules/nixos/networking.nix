{ config, ... }:
{
  networking.hostName = config.pwnbox.hostName;

  # CONFIG_PACKET is built as a module (af_packet.ko) in the NixOS kernel.
  # hardening.nix sets security.lockKernelModules, which flips
  # kernel.modules_disabled=1 once the system is up. Nothing pulls af_packet
  # in before that, so every PF_PACKET socket fails with EAFNOSUPPORT (-97)
  # afterwards: NetworkManager's DHCPv4 client never gets a lease (IPv6-only
  # connectivity) and wpa_supplicant cannot grab the WiFi interface
  # ("l2_packet_init: socket(PF_PACKET): Address family not supported").
  boot.kernelModules = [ "af_packet" ];

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
