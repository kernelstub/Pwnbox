{ pkgs, ... }:
with pkgs;
[
  openssl
  gnutls
  age
  sops
  gnupg
  veracrypt
  cryptsetup
  keepassxc
  step-cli

  minisign
  signify
  certbot
  cryptomator

  pass
  bitwarden-cli
  sequoia-sq
]
