{ pkgs, ... }:
with pkgs;
[
  lynis
  aide
  osquery
  fail2ban
  crowdsec

  suricata
  zeek

  sysdig
  tracee
  tetragon
  bcc
  bpftrace

  openscap

  clamav
  audit

  snort

  prometheus
  prometheus-node-exporter
]
