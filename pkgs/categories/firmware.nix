{ pkgs, ... }:
with pkgs;
[
  binwalk
  squashfsTools
  dtc
  uefitool
  ifdtool
  cbfstool
  sasquatch
  me_cleaner
  ubootTools
  python3Packages.uefi-firmware-parser
]
