{ pkgs, lib, ... }:
with pkgs;
[
  file
  coreutils
  ssdeep
  python3Packages.tlsh
  exiftool
  detect-it-easy

  binutils
  llvmPackages.llvm
  radare2
  xxd
  util-linux
  p7zip
  upx

  ghidra-bin
  pwnbox.ida
  binaryninja-free
  rizin
  cutter
  imhex
  binsider
  procyon
  bytecode-viewer
  dex2jar

  flare-floss
  yara
  yara-x
  binwalk
  (unblob.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      sed -i \
        -e 's|def frombuf(cls, buf, encoding, errors):  # noqa: C901|def frombuf(cls, buf, encoding, errors):\n        """Parse GNU headers without treating the prefix field as a pathname."""\n        return cls._frombuf(buf, encoding, errors)\n\n    @classmethod\n    def _frombuf(cls, buf, encoding, errors, *, dircheck=True):  # noqa: C901|' \
        -e 's|if obj.type == tarfile.AREGTYPE and obj.name.endswith("/"):|if dircheck and obj.type == tarfile.AREGTYPE and obj.name.endswith("/"):|' \
        python/unblob/handlers/archive/_safe_tarfile.py
    '';
  }))

  gdb
  lldb
  rr
  strace
  ltrace
  bpftrace
  perf
  frida-tools
  objection

  python3
  nodejs
  jdk21
  dotnet-sdk
  ilspycmd
  mono
  go
  rustc
  cargo
  lua5_4
  luajit
  wabt

  jadx
  apktool
  (lib.head androidenv.androidPkgs.build-tools)
  androidenv.androidPkgs.cmdline-tools-package
  libimobiledevice
  libplist
  ipsw
  rcodesign

  qemu
  unicorn
  (python3Packages.qiling.overrideAttrs (old: {
    meta = old.meta // {
      broken = false;
    };
  }))

  openocd
  flashrom
  sigrok-cli
  pulseview
  chipsec
  uefitool
  swtpm
  jefferson
  squashfsTools
  ubi_reader
  dtc
  ubootTools
  abootimg

  hackrf
  rtl-sdr
  gnuradio
  can-utils
  mbpoll
  net-snmp
  pcsc-tools
  opensc

  tcpdump
  wireshark-cli
  wireshark
  mitmproxy

  suricata
  zeek
  osquery
  chainsaw
  hayabusa
  sigma-cli

  docker
  podman
  buildah
  skopeo
  crane
  umoci
  dive
  trivy
  syft
  grype
  cosign
  kubectl
  kubernetes-helm
  regctl

  z3
  boolector
  cvc5
  aflplusplus
  honggfuzz
  syzkaller
  renode
  bpftools
  volatility3

  kaitai-struct-compiler
  protobuf
  flatbuffers

  python3Packages.capstone
  python3Packages.pefile
]
