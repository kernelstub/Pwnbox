{ pkgs, ... }:
with pkgs;
[
  mfoc
  pcsc-tools
  libnfc
  proxmark3
  opensc
  ccid
  mfcuk
  yubikey-manager
  yubioath-flutter
  yubico-piv-tool
]
