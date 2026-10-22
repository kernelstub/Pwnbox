{
  config,
  lib,
  pkgs,
  ...
}:
{

  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=64M
    RuntimeKeepFree=16M
    MaxLevelStore=warning
    MaxLevelSyslog=warning
    MaxLevelKMsg=none
    MaxLevelConsole=none
    MaxLevelWall=none
    Audit=no
    ForwardToSyslog=no
    ForwardToKMsg=no
    ForwardToConsole=no
    ForwardToWall=no
  '';
  services.journald.forwardToSyslog = false;
  services.journald.upload.enable = false;

  fileSystems."/var/log" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "size=64M"
      "mode=0755"
      "nosuid"
      "nodev"
      "noexec"
    ];
  };

  boot.tmp.useTmpfs = true;
  boot.tmp.cleanOnBoot = true;

  # /tmp is RAM-backed. Large stale artifacts (VM images, unpacked trees)
  # otherwise keep consuming memory until the next reboot. Age them out
  # during normal operation as well.
  systemd.tmpfiles.rules = [
    "x /tmp/.X11-unix"
    "x /tmp/.ICE-unix"
    "x /tmp/.XIM-unix"
    "x /tmp/.font-unix"
    "e /tmp 1777 root root 2d"
  ];
  systemd.timers.systemd-tmpfiles-clean.timerConfig = {
    OnBootSec = "15min";
    OnUnitActiveSec = "6h";
  };

  fileSystems."/var/tmp" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "size=512M"
      "mode=1777"
      "nosuid"
      "nodev"
    ];
  };

  systemd.coredump.enable = false;
  boot.kernel.sysctl."kernel.core_pattern" = "/dev/null";

  boot.kernelParams = [
    "quiet"
    "loglevel=0"
    "rd.udev.log_level=0"
    "systemd.show_status=false"

    "init_on_alloc=1"
    "init_on_free=1"
    "page_alloc.shuffle=1"
    "slab_nomerge"
    "vsyscall=none"
    "debugfs=off"

    "nohibernate"

    "iommu=force"
    "iommu.strict=1"
    "amd_iommu=on"
    "efi=disable_early_pci_dma"

    "random.trust_cpu=off"
    "randomize_kstack_offset=on"

    "oops=panic"
    "panic=10"
  ];
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.perf_event_paranoid" = 3;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.unprivileged_bpf_disabled" = 2;
    "kernel.sysrq" = 0;
    "kernel.kexec_load_disabled" = 1;
    "kernel.randomize_va_space" = 2;
    "net.core.bpf_jit_harden" = 2;
    "net.core.bpf_jit_kallsyms" = 0;
    "dev.tty.ldisc_autoload" = 0;

    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.suid_dumpable" = 0;
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
    "vm.mmap_min_addr" = 65536;
    "vm.unprivileged_userfaultfd" = 0;

    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.log_martians" = 0;
    "net.ipv4.conf.default.log_martians" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.ip_forward" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.forwarding" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 2;
  };

  boot.blacklistedKernelModules = [
    "dccp"
    "sctp"
    "rds"
    "tipc"
    "firewire_core"
    "firewire_ohci"
    "thunderbolt"
    "cramfs"
    "freevxfs"
    "jffs2"
    "hfs"
    "hfsplus"
    "udf"
    "vivid"
    "atm"
    "appletalk"
    "decnet"
    "ipx"
    "p8022"
    "psnap"
    "ax25"
    "x25"
    "rose"
    "netrom"
    "n_hdlc"
    "can"
    "can_raw"
    "floppy"
    "pcspkr"
    "snd_pcsp"
  ];

  boot.loader.grub.configurationLimit = 5;

  security.protectKernelImage = true;
  security.forcePageTableIsolation = true;

  security.lockKernelModules = true;

  security.apparmor.enable = true;

  services.avahi.enable = false;
  services.printing.enable = false;
  services.fwupd.enable = false;
  services.geoclue2.enable = false;
  services.openssh.enable = false;

  networking.firewall.enable = true;
  networking.firewall.logRefusedConnections = false;

  services.displayManager.autoLogin.enable = false;

  users.users.root.hashedPassword = "!";

  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = true;
  };

}
