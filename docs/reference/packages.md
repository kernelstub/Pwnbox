# Packages

The box ships a full daily-driver app set plus 26 pentest categories. Almost
everything is toggleable from `hosts/<host>/default.nix`.

## Tooling categories

All categories are enabled by default. Disable any with
`pwnbox.packages.toolset.<category>.enable = false;`.

| Group | Category | Focus |
| --- | --- | --- |
| **Recon & Web** | `reconnaissance` | Host/port discovery, DNS, OSINT |
| | `web` | Web proxies, injection, content discovery |
| **Exploit & AD** | `exploitation` | Exploit frameworks and databases |
| | `active-directory` | Windows / AD attack & enumeration |
| **Network & Radio** | `network` | Capture, MITM, proxying, pivoting |
| | `wireless` | Wi-Fi auditing |
| | `bluetooth` | Bluetooth / BLE |
| | `rf-sdr` | Radio / software-defined radio |
| **Hardware & Firmware** | `hardware` | Embedded, flashing, logic |
| | `firmware` | Firmware extraction & analysis |
| | `smartcards` | NFC, RFID, smart cards |
| **Reversing & Pwn** | `reverse-engineering` | Disassembly, decompilation, malware |
| | `binary-exploitation` | Pwn, debugging, ROP |
| | `fuzzing` | Fuzzers and mutation tooling |
| **Forensics & Defense** | `forensics` | Disk & memory forensics |
| | `blue-team` | Detection, monitoring, hardening |
| | `code-analysis` | SAST, secrets, dependencies |
| **Cloud & Infra** | `cloud` | AWS, Azure, GCP |
| | `containers` | Docker, Podman |
| | `kubernetes` | Kubernetes tooling |
| **Cracking & Crypto** | `password-cracking` | Hash & login cracking |
| | `cryptography` | Crypto and key tooling |
| | `wordlists` | Bundled wordlists |
| **Mobile & Comms** | `mobile` | Android / iOS |
| | `voip` | SIP |
| **Utilities** | `python` | OSINT CLI helpers |

## Optional sets

| Option | Adds |
| --- | --- |
| `pwnbox.packages.gaming` | Gaming and entertainment apps |
| `pwnbox.packages.creative` | Creative, media and office apps |
| `pwnbox.packages.hacking` | The full pentest toolset |

## IDA Free / Pro

IDA is proprietary, so the flake never fetches it — instead it wraps a
locally installed copy. With `pwnbox.packages.hacking` (on by default with
the toolset), `pkgs/security/ida-fhs.nix` installs:

- an **FHS environment** with every library the stock IDA binary links
  against (Qt/X11/xcb, fontconfig, freetype, glib, GTK, libglvnd, wayland,
  dbus, zlib, …), so IDA runs on NixOS unmodified;
- the `ida`, `ida64`, `idat` and `hv` commands plus launcher entries.

The wrapper expects IDA in `~/Software/RE/IDA`; set
`PWNBOX_IDA_HOME` to use another directory (or export it in
`modules/home/shell.nix`).

```bash
ida                     # default location
PWNBOX_IDA_HOME=/opt/ida ida
```

Theming and fonts are covered in [Apps](../usage/apps.md#ida-free--pro).

## Daily-driver apps

| Area | Apps |
| --- | --- |
| **Private & encrypted chat** | Signal, SimpleX, Element (Matrix), Dino (XMPP), qTox, AyuGram (Telegram), Equibop (Discord / Equicord), GoofCord (Discord / Vencord) |
| **Browsers** | Zen (default, themed), Chromium, Tor Browser (hardened), Mullvad Browser |
| **Privacy & security** | KeePassXC, Mullvad VPN, Tor + torsocks |
| **Crypto wallets** | Exodus, Ledger Live (with udev rules for Ledger devices) |
| **Office & notes** | LibreOffice, Obsidian, Geary, Zathura, Papers (Document Viewer), Loupe (Image Viewer) |
| **AI assistant** | ChatGPT (official desktop app) |
| **Media & creative** | Stremio Enhanced, Spotify, VLC, mpv, cmus, qBittorrent, GIMP, Inkscape, Krita, OBS, Audacity, Kdenlive, Blender, spotdl, yt-dlp (also `ytdl`) |
| **Terminal & system** | kitty, ranger, zsh + oh-my-zsh, tmux, btop, fastfetch, fzf, ripgrep, bat, eza, zoxide, lazygit |
| **Development** | Neovim, Zed, Git, Docker / Podman, libvirt / KVM (virt-manager) and language toolchains (C/C++, Rust, Go, Python, JVM, JS/TS, Haskell, …) |
| **Reverse engineering** | IDA Pro 9.x / IDA Free via an FHS wrapper for a locally installed copy — `ida`, `ida64`, `idat`, `hv` commands and launcher entries, fully themed |

## Stremio Enhanced

[Stremio Enhanced](https://github.com/REVENGE977/stremio-enhanced) replaces
plain Stremio (`pwnbox.stremio-enhanced` in `pkgs/custom.nix`). The package in
`pkgs/apps/media/stremio-enhanced.nix`:

- wraps the upstream AppImage (x86_64 / aarch64) in an FHS environment;
- bundles the pwnbox fonts into the sandbox so the application font renders;
- fetches the Stremio streaming server (`server.js` from `dl.strem.io`,
  pinned by `serverVersion`) at build time and seeds it to
  `~/.config/stremio-enhanced/streamingserver/` on activation.

Theming is covered in [Apps](../usage/apps.md#stremio-enhanced).

## Ledger Live

Ledger Live comes straight from nixpkgs. `hardware.ledger.enable = true`
installs `ledger-udev-rules` so hardware wallets are reachable without root.

## Exodus

nixpkgs' `exodus` package uses `requireFile` (a manual download). The overlay
in `pkgs/apps/wallets/exodus.nix` replaces it with a `fetchurl` of the same pinned vendor
archive from `downloads.exodus.com`, so normal builds work without manual
store imports. Update the hash when bumping the version.

## Adding your own packages

Put extra packages in `pkgs/custom.nix`; they are picked up automatically:

```nix
{ pkgs, ... }:
with pkgs;
[
  ripgrep-all
  ffuf
]
```

Then rebuild with `./scripts/install.sh switch`.
