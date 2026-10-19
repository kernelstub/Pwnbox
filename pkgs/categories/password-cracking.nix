{ pkgs, ... }:
with pkgs;
[
  hashcat
  hashcat-utils
  john
  hydra
  crunch
  cewl
  maskprocessor
  hashid
  hcxtools
  hcxdumptool

  medusa
  ncrack
  ophcrack
  crowbar
  brutespray

  rsmangler
]
