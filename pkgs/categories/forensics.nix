{ pkgs, ... }:
with pkgs;
[
  sleuthkit
  ddrescue
  foremost
  testdisk
  extundelete
  ntfs3g
  dislocker

  volatility3
  bulk_extractor
  exiftool
  hivex

  smartmontools
  nvme-cli

  hayabusa
  chainsaw

  dc3dd
  dcfldd
  safecopy
  guymager
  scalpel
  libewf
  afflib
  regripper
  libguestfs
  apfs-fuse
]
