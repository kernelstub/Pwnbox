{
  inputs,
  lib,
  self,
  pkgs,
  ...
}:
{
  imports = [
    (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # The flake lives in the squashfs store; /pwnbox points at it in the live system.
  isoImage.storeContents = [ self ];
  systemd.tmpfiles.rules = [ "L+ /pwnbox - - - - ${self}" ];

  isoImage = {
    volumeID = "PWNBOXINST";
  };

  image.baseName = lib.mkForce "pwnbox-installer";

  boot.zfs.forceImportRoot = false;

  environment.systemPackages = with pkgs; [
    tmux
    unzip
  ];
}
