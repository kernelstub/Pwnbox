{ pkgs, ... }:
with pkgs;
[
  ghidra-bin
  radare2
  imhex

  flare-floss
  yara
  binaryninja-free
  rizin
  cutter
  frida-tools
  xxd

  detect-it-easy
  procyon
  bytecode-viewer
  dex2jar
  strace
  ltrace
  python3Packages.capstone
  python3Packages.pefile

  upx
  binsider
]
