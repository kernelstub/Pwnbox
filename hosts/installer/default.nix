# pwnbox installer ISO
#
# Stock NixOS installer carrying the pwnbox flake source (+ flake.lock) at
# /pwnbox, read-only. Boot it, partition, and:
#
#   cp -r /pwnbox /mnt/root/pwnbox
#   nixos-generate-config --root /mnt
#   cp /mnt/etc/nixos/hardware-configuration.nix /mnt/root/pwnbox/hosts/nixos/
#   nixos-install --flake '/mnt/root/pwnbox#nixos'
#
# On aarch64 pass the system explicitly (mkHost falls back to x86_64-linux):
#   PWNBOX_SYSTEM=aarch64-linux nixos-install --impure --flake '/mnt/root/pwnbox#nixos'
#
# Deliberately does NOT import the pwnbox modules — it is a vehicle for
# pwnbox, not a pwnbox system, so it stays small and conflict-free.
#
# Built as: nix build .#images.<system>.installer
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

  # Embed the flake (source + flake.lock) on the ISO at /pwnbox.
  # `self` works for a local path flake; for a git-URL flake use
  # `self.sourceInfo` instead.
  isoImage.storeContents = [
    {
      object = self;
      symlink = "/pwnbox";
    }
  ];

  isoImage = {
    volumeID = "PWNBOXINST";
  };

  # Output filename: result/iso/pwnbox-installer.iso
  image.baseName = lib.mkForce "pwnbox-installer";

  # Future default (26.11); importing pools at boot risks data loss.
  boot.zfs.forceImportRoot = false;

  environment.systemPackages = with pkgs; [
    tmux
    unzip
  ];
}
