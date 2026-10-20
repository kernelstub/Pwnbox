{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/iso-image.nix")
  ];

  hardware.enableAllHardware = true;
  nixpkgs.config.allowUnsupportedSystem = true;

  pwnbox = {
    username = "pwnbox";
    fullName = "pwnbox";
    hostName = "pwnbox-live";
    timeZone = "UTC";

    desktop = {
      enable = true;
      resolution = "highres";
    };

    vpn.mullvad = false;
    virtualisation.docker = false;
    virtualisation.libvirtd = false;
    virtualisation.wireshark = false;

    packages = {
      hacking = true;
      gaming = false;
      creative = false;
    };
  };

  users.users.pwnbox.initialPassword = "pwnbox";

  services.displayManager.autoLogin = {
    enable = lib.mkForce true;
    user = "pwnbox";
  };

  boot.kernelParams = lib.mkForce (
    [
      "quiet"
      "loglevel=0"
    ]
    ++ lib.optionals (!config.boot.initrd.systemd.enable) [
      "boot.shell_on_fail"
      "root=LABEL=${config.isoImage.volumeID}"
    ]
  );

  isoImage = {
    volumeID = "PWNBOXLIVE";
    makeEfiBootable = true;
    makeUsbBootable = true;
    squashfsCompression = "zstd -Xcompression-level 19";
  };

  image.baseName = lib.mkForce "pwnbox-live";

  system.stateVersion = "26.05";
}
