{ pkgs, ... }:
with pkgs;
[
  wireshark
  tcpdump
  termshark
  tcpreplay

  bettercap
  testssl
  proxychains-ng

  chisel
  ligolo-ng
  sshuttle
  socat
  netcat

  iftop
  iperf3
  lftp

  ettercap
  dsniff
  yersinia
  hping
  arping
  netdiscover
  tcpflow
  sshpass
  openvpn
  wireguard-tools
  sslscan
  sslsplit

  tailscale
  mosh
  sshfs-fuse

  nethogs
  tcptrack
  bmon
  nload
  iptraf-ng
  bandwhich
  speedtest-cli

  ipcalc
  sipcalc
  grpcurl
  dnsperf
  netperf
  ssldump
]
