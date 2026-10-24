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

  isoImage.storeContents = [ self ];
  isoImage.contents = [
    {
      source = self;
      target = "/pwnbox";
    }
  ];

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
