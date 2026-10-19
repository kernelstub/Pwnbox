{ pkgs, ... }:
with pkgs;
[
  python3Packages.shodan
  python3Packages.python-nmap

  python3Packages.scapy
  python3Packages.paramiko
]
