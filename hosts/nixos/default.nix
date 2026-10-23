{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
  ];

  pwnbox = {
    hostName = "nixos";
    timeZone = "Europe/Berlin";

    desktop = {
      enable = true;
      accessibility = false;
      mainMonitor = "HDMI-A-2";
      leftMonitor = "DP-1";
    };

    vpn.mullvad = false;

    virtualisation = {
      docker = true;
      libvirtd = true;
      wireshark = true;
    };

    packages = {
      hacking = true;
      gaming = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.compressor = "xz";
}
