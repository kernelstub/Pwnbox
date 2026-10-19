# Privacy

pwnbox is built to leave as little on disk as possible. Privacy and messaging
apps are installed by default and the system is hardened.

## No logs

- `journald` is **volatile**. Logs live in RAM only (`Storage=volatile`),
  capped at 64 MB, and only warnings and above are kept.
- `/var/log` is a `tmpfs` (64 MB, `nosuid,nodev,noexec`).
- `ForwardToSyslog` / `ForwardToKMsg` / `ForwardToWall` are off and crash
  uploads are disabled.
- Core dumps are disabled (`systemd.coredump.enable = false`,
  `kernel.core_pattern = /dev/null`).
- The boot console is silenced (`quiet loglevel=0`, `consoleLogLevel = 0`).

## No plaintext on disk

- **No swap partition.** `zramSwap` only (`memoryPercent = 50`).
- **RAM-backed `/tmp`** and `/var/tmp` (`boot.tmp.useTmpfs`, `cleanOnBoot`).
- No hibernation (`nohibernate`).

## Hardened kernel & network

- Strict sysctls: `kptr_restrict=2`, `dmesg_restrict=1`,
  `perf_event_paranoid=3`, `yama.ptrace_scope=1`, `kexec_load_disabled=1`,
  `unprivileged_bpf_disabled=2`, `randomize_kstack_offset=on`, `oops=panic`.
- Memory protections: `init_on_alloc=1`, `init_on_free=1`, `slab_nomerge`,
  `page_alloc.shuffle=1`, `vsyscall=none`, `debugfs=off`.
- IOMMU forced and strict; early PCI DMA disabled.
- Network: reverse-path filtering, no source routing/redirects, syncookies,
  RFC 1337, IPv6 privacy addresses and `ip_forward` off.
- Dangerous/legacy filesystems and protocols are block-listed (`dccp`, `sctp`,
  `rds`, `tipc`, `firewire`, `thunderbolt`, `hfs`, `udf`, `can`, …).
- AppArmor, `protectKernelImage` and `forcePageTableIsolation` are on.
- `lockKernelModules` prevents loading modules at runtime.

## Services & accounts

- Firewall on; refused connections are not logged.
- No SSH, Avahi, printing, `fwupd` or geolocation.
- Root login is locked (`hashedPassword = "!"`).
- `sudo-rs`, wheel-only, always asks for a password.
- No autologin.
- Garbage collection runs daily and keeps 7 days.

## Browser

Zen ships hardened by default (`dotfiles/zen/user.js`, applied on every rebuild
and at startup):

- Telemetry, studies, crash reports, search suggestions and sponsored content
  disabled
- Strict tracking protection, first-party isolation, query stripping,
  Global Privacy Control
- No speculative connections, no prefetch/DNS prefetch, trimmed referrers,
  session-scoped disk footprint (cache in memory only)
- Cache, history, form data and downloads cleared on shutdown — **cookies are
  kept**, so logins persist
- Dark colour scheme forced on all sites
- Pywalfox, ClearURLs and the pwnbox styles extension are installed by
  default

Manage these settings in `dotfiles/zen/user.js`; the browser UI changes are
overwritten by it at startup.

## Privacy apps

Signal, SimpleX, Element (Matrix), Dino (XMPP), qTox, Mullvad VPN, Tor Browser
and `tor`/`torsocks` are included. Mullvad's daemon can be disabled with
`pwnbox.vpn.mullvad = false`.

## Filesystem hygiene

- `/etc/nixos` on the installed machine only holds the hardware config and a
  pointer back to this flake.
- Shell history is not persisted (`HISTFILE=/dev/null`).
- `remember-recent-files` is off; old trash and temp files are removed.
- `zramSwap` means secrets in memory are never written to a swap device.
