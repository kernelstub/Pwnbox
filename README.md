<h1 align="center">PWNBOX</h1>

<p align="center">
  <img src="https://github.com/user-attachments/assets/6bc14965-486f-468d-8f70-fba584b46522" alt="PWNBOX desktop" width="860">
</p>


<p align="center">
  A ready-to-go <a href="https://nixos.org">NixOS</a> +
  <a href="https://github.com/nix-community/home-manager">home-manager</a> box for
  <b>hacking, reverse engineering, Active Directory and networking</b>.
  It's reproducible, portable and built for <b>privacy</b>.
</p>

---

## Table of contents

- [Documentation](#documentation)
- [Categories](#categories)
- [Apps](#apps)
- [Themes & customization](#themes--customization)
- [Desktop](#desktop)
- [Keybinds](#keybinds)
- [Privacy](#privacy)
- [Install](#install)
- [ISOs](#isos)
- [IDA Free / Pro](#ida-free--pro)
- [Community](#community)
- [Author](#author)
- [License](#license)

---

## Documentation

The full manual lives in [`docs/`](docs/README.md):

| Document                                   | What it covers                                      |
| ------------------------------------------ | --------------------------------------------------- |
| [Getting started](docs/getting-started.md) | Install, first boot, updates, host config           |
| [ISOs](docs/isos.md)                       | Live/installer ISOs, live credentials, booting      |
| [Desktop](docs/desktop.md)                 | Hyprland, GNOME, Quickshell and the bar             |
| [Keybinds](docs/keybinds.md)               | Every keyboard shortcut                             |
| [Themes](docs/themes.md)                   | Wallpaper themes, custom themes, the `ALT + S` menu |
| [Fonts](docs/fonts.md)                     | System/application fonts and sizes                  |
| [Apps](docs/apps.md)                       | Per-app theming and live updates                    |
| [Browser](docs/browser.md)                 | Zen, site themes and the pwnbox styles extension    |
| [Packages](docs/packages.md)               | Tool categories and optional app sets               |
| [Privacy](docs/privacy.md)                 | Hardening and zero-trace defaults                   |
| [Architecture](docs/architecture.md)       | Repo layout and how a theme switch works            |
| [Troubleshooting](docs/troubleshooting.md) | Common problems and fixes                           |
| [Development](docs/development.md)         | Add themes, packages and bar styles                 |

---

## Categories

26 pentest categories, all on by default. Turn any of them off with
`pwnbox.packages.toolset.<category>.enable = false;`.

| Group                   | Category              | Focus                                     |
| ----------------------- | --------------------- | ----------------------------------------- |
| **Recon & Web**         | `reconnaissance`      | Host/port discovery, DNS, OSINT           |
|                         | `web`                 | Web proxies, injection, content discovery |
| **Exploit & AD**        | `exploitation`        | Exploit frameworks and databases          |
|                         | `active-directory`    | Windows / AD attack & enumeration         |
| **Network & Radio**     | `network`             | Capture, MITM, proxying, pivoting         |
|                         | `wireless`            | Wi-Fi auditing                            |
|                         | `bluetooth`           | Bluetooth / BLE                           |
|                         | `rf-sdr`              | Radio / software-defined radio            |
| **Hardware & Firmware** | `hardware`            | Embedded, flashing, logic                 |
|                         | `firmware`            | Firmware extraction & analysis            |
|                         | `smartcards`          | NFC, RFID, smart cards                    |
| **Reversing & Pwn**     | `reverse-engineering` | Disassembly, decompilation, malware       |
|                         | `binary-exploitation` | Pwn, debugging, ROP                       |
|                         | `fuzzing`             | Fuzzers and mutation tooling              |
| **Forensics & Defense** | `forensics`           | Disk & memory forensics                   |
|                         | `blue-team`           | Detection, monitoring, hardening          |
|                         | `code-analysis`       | SAST, secrets, dependencies               |
| **Cloud & Infra**       | `cloud`               | AWS, Azure, GCP                           |
|                         | `containers`          | Docker, Podman                            |
|                         | `kubernetes`          | Kubernetes tooling                        |
| **Cracking & Crypto**   | `password-cracking`   | Hash & login cracking                     |
|                         | `cryptography`        | Crypto and key tooling                    |
|                         | `wordlists`           | Bundled wordlists                         |
| **Mobile & Comms**      | `mobile`              | Android / iOS                             |
|                         | `voip`                | SIP                                       |
| **Utilities**           | `python`              | OSINT CLI helpers                         |

## Apps

On top of the toolset, the box ships a full daily-driver app set:

| Area                         | Apps                                                                                                                                                                                                              |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Private & encrypted chat** | Signal, SimpleX, Element (Matrix), Dino (XMPP), qTox, AyuGram (Telegram), Equibop (Discord / Equicord)                                                                                                             |
| **Browsers**                 | Zen (default, hardened + themed), Chromium, Tor Browser, Mullvad Browser                                                                                                                                          |
| **Privacy & security**       | KeePassXC, Mullvad VPN, Tor + torsocks                                                                                                                                                                            |
| **Crypto wallets**           | Exodus, Ledger Live (with udev rules for Ledger devices)                                                                                                                                                          |
| **Office & notes**           | LibreOffice, Obsidian, Geary, Zathura                                                                                                                                                                             |
| **AI assistant**             | ChatGPT (official desktop app)                                                                                                                                                                                    |
| **Media & creative**         | Stremio Enhanced, Spotify, VLC, mpv, cmus, qBittorrent, GIMP, Inkscape, Krita, OBS, Audacity, Kdenlive, Blender, spotdl, yt-dlp (also `ytdl`)                                                                     |
| **Terminal & system**        | kitty, ranger, zsh + oh-my-zsh, tmux, btop, fastfetch, fzf, ripgrep, bat, eza, zoxide                                                                                                                             |
| **Development**              | Neovim, Zed, Git, Docker, libvirt / KVM (virt-manager) and language toolchains (C/C++, Rust, Go, Python, JVM, JS/TS, Haskell and many more)                                                                       |
| **Reverse engineering**      | IDA Pro 9.x / IDA Free via an FHS wrapper for a locally installed copy — `ida`, `ida64`, `idat`, `hv` commands and launcher entries, fully themed                                                                  |

Optional sets. Turn them on with `pwnbox.packages.gaming` or
`pwnbox.packages.creative`.

## Themes & customization

- **Wallpaper-driven themes.** The palette is pulled from your wallpaper and
  applied everywhere: bar, terminal, launcher, notifications, editor, GTK apps,
  chat clients, Spotify and more.
- **Wallpaper library.** All wallpapers live in the flake at
  `dotfiles/gnome/wallpapers/` (linked read-only to
  `~/.local/share/pwnbox/wallpapers`). Add an image there and rebuild; the
  picker reads that folder. Custom themes keep their own wallpaper next to
  their `theme.conf`.
- **Custom themes.** Fixed-palette themes live in `dotfiles/themes/<name>/`,
  each with its own `theme.conf` and wallpaper.
- **One menu for everything.** `ALT + S` opens the settings picker for theme,
  wallpaper, bar style, corner radii, fonts, font sizes, blur, transparency,
  window borders, shadows and animations. See [docs/themes.md](docs/themes.md).
- **Live app theming.** Spotify, Discord (Equibop), Telegram (AyuGram),
  Signal, Element and Wire update while they are running, without quitting
  them. Signal, Element and Wire are patched by the flake to load a
  pywal-generated `theme.css` (colours + application font) at runtime. See
  [docs/apps.md](docs/apps.md).
- **Stremio Enhanced.** Replaces plain Stremio with the Enhanced fork
  (plugins + themes). The pwnbox theme recolours it from the active palette
  (apply it once under Settings → Themes), the streaming server is installed
  automatically, and the application font from `ALT + S` is used. See
  [docs/apps.md](docs/apps.md#stremio-enhanced).
- **IDA Free / Pro.** Not in nixpkgs (proprietary), so the flake wraps a
  locally installed copy: an FHS environment with every library IDA needs, a
  flat pywal theme with the same background-lightened borders as Zed, the
  pwnbox fonts, and a pseudocode retagging plugin. See
  [docs/apps.md](docs/apps.md#ida-free--pro).
- **Themed browser.** Zen's UI, DevTools, about: pages and 131 website themes
  all follow the palette and update live via the pwnbox styles extension. See
  [docs/browser.md](docs/browser.md).
- All appearance choices are saved and re-applied on login.

<details>
<summary>131 themed websites</summary>

**Development & docs** — alacritty.org, arch-wiki, bstats, codeberg, crates.io,
crowdin, devdocs, dev.to, docs.deno.com, docs.rs, freedesktop, ghostty.org,
github, gleam.run, go.dev, graphite, hackage, home-manager-options-search,
hoogle, hoppscotch, learn-x-in-y-minutes, mdbook, mdn, neovim.io,
nixos-manual, nixos-search, npm, npmx, pypi, pythonanywhere, react.dev,
regex101, scalar, stack-overflow, web.dev, zen-browser-docs

**AI, search & productivity** — alternativeto, amplenote, anonymous-overflow,
boringproxy, brave-search, chatgpt, claude, deepseek, deepl, ecosia, gmail,
google-drive, google-gemini, google-photos, grabify, have-i-been-pwned,
homepage, indie-wiki-buddy, inoreader, invokeai, keyoxide, lingva, linkedin,
microsoft-word, migadu-webmail, ollama, openmediavault, paste.rs, perplexity,
poe, porkbun, proton, raindrop, rentry.co, searchix, searxng, startpage, stylus,
syncthing, tabnews, tldraw, tuta, vercel, vikunja, whatsapp-web, wikipedia,
wikiwand

**Media, social & streaming** — anilist, bsky, cinny, cobalt, elk, hacker-news,
holodex, hyperpipe, instagram, invidious, lastfm, lemmy, libreddit, listenbrainz,
lobste.rs, mastodon, modrinth, namemc, nitter, phanpy, pinterest,
planet-minecraft, pronouns.cc, pronouns.page, reddit, seventv, shinigami-eyes,
snapchat-web, spotify-web, status.cafe, substack, twitch, twitter, youtube

**Learning, games & fun** — advent-of-code, canvas-lms, chess.com, desmos,
formative, ichi.moe, jisho, keybr.com, lichess, minesweeper, picrew,
pwnbox-scrollbars, quizlet, trinket

</details>

## Desktop

Hyprland is the default session (GNOME is available as a second one). The bar,
notifications and control center are built with Quickshell, and Neovim is
configured VS Code-style with everything provided by Nix (nothing is
downloaded at runtime).

## Keybinds

| Keys                                        | Action                             |
| ------------------------------------------- | ---------------------------------- |
| `ALT + SPACE`                               | App launcher                       |
| `ALT + T` / `D` / `F` / `M`                 | Terminal / Discord / Zen / Music   |
| `ALT + S`                                   | Theme & settings menu              |
| `ALT + {1-9,0}`                             | Switch workspace                   |
| `SUPER + {1-9,0}`                           | Move window to workspace           |
| `CTRL + ALT + ←/→`                          | Previous / next workspace          |
| `SUPER + arrows`                            | Focus window                       |
| `SUPER + SHIFT + arrows`                    | Move window                        |
| `SUPER + CTRL + arrows`                     | Resize window                      |
| `SUPER + T` / `P` / `V`                     | Float / pseudo-tile / toggle split |
| `SUPER + F` / `SUPER + SHIFT + F`           | Fullscreen / real fullscreen       |
| `ALT + Z`                                   | Close window                       |
| `SUPER + L`                                 | Lock screen                        |
| `SUPER + ESCAPE`                            | Power menu                         |
| `SUPER + \``                                | Clipboard history                  |
| `PRINT` / `SUPER + SHIFT + S` / `SUPER + SHIFT + R` | Screenshot: clipboard / region / save |

The full list, including media and hardware keys, is in
[docs/keybinds.md](docs/keybinds.md).

## Privacy

Privacy and messaging apps are installed by default, and the system is hardened
to keep no traces:

- No logs. Volatile journald, `/var/log` on a RAM disk.
- No on-disk swap. zram only, so nothing plaintext touches disk.
- RAM-backed `/tmp` and `/var/tmp`.
- Hardened kernel & network, `sudo-rs`, locked root, firewall on.
- No persisted shell history.
- Hardened Zen: telemetry off, cache/history cleared on exit, cookies kept,
  dark mode forced.
- Signal, SimpleX, Element, Dino, qTox, Tor Browser, Mullvad VPN and
  `tor` / `torsocks` included.

## Install

Requirements: an existing NixOS install, a user with `sudo` access, and
network access for the first fetch.

```bash
# 1. download the archive and extract it
unzip pwnbox.zip     # or: tar -xzf pwnbox.tar.gz

# 2. enter the flake directory
cd pwnbox

# 3. run the installer
./install.sh switch
```

`install.sh` detects your user, hostname, time zone and hardware, creates
`hosts/<host>/` from the `nixos` template, refreshes `hardware-configuration.nix`
and `boot.nix` for the current machine, then activates. The template's
`hardware-configuration.nix` ships placeholder disk UUIDs — the installer
replaces them with the real ones for your device, so there is nothing to edit.
Garbage collection is opt-in with `--gc`.

Commands you will use most:

| Command               | Does                                  |
| --------------------- | ------------------------------------- |
| `./install.sh switch` | Rebuild and activate                  |
| `upd`                 | Rebuild and activate                  |
| `update`              | Update all flake inputs, then rebuild |
| `ALT + S`             | Open the theme / settings menu        |

Add your own packages in `pkgs/custom.nix`.

## ISOs

Bootable images, built from this flake:

```bash
./build-iso.sh              # live + installer for this machine → iso/
./build-iso.sh live         # just the live desktop ISO
./build-iso.sh installer    # just the installer ISO
```

- **Live ISO** — the full pwnbox desktop on a stick. Runs entirely in RAM:
  zero persistence, nothing touches the USB drive, reboot = factory reset.
- **Installer ISO** — a stock NixOS installer carrying this flake at
  `/pwnbox`, ready for `nixos-install --flake`.
- **Architectures** — `x86_64-linux` (BIOS + UEFI) and `aarch64-linux`
  (UEFI only, needs an ARM builder: `--builders 'ssh-ng://root@pi
  aarch64-linux - 8'`).

Live ISO credentials and defaults:

| | |
| --- | --- |
| User / password | `pwnbox` / `pwnbox` (change with `passwd`) |
| Root | locked, sudo via `pwnbox` |
| Time zone | UTC |
| Session | Hyprland (autologin), GNOME as second session |

Full details — booting, Ventoy/`dd`, Secure Boot, NVIDIA and the installer
flow — in [docs/isos.md](docs/isos.md).

## IDA Free / Pro

IDA is proprietary, so it is **not fetched** by the flake. Install it
yourself (any location) — the flake provides everything around it:

- An FHS wrapper (`pwnbox.ida`) with every system library IDA links
  against, so the stock binary runs on NixOS. Installed with
  `pwnbox.packages.hacking`; provides `ida`, `ida64`, `idat` and `hv`.
- The default install location is `~/Software/RE/IDA`; point it
  elsewhere with the `PWNBOX_IDA_HOME` environment variable.
- The raw binary runs directly too — `programs.nix-ld` is configured
  with the same library set.
- Launcher entries, a pywal theme (flat backgrounds, background-lightened
  borders), the pwnbox fonts and a pseudocode retagging plugin — all
  applied automatically on every theme change.

```bash
PWNBOX_IDA_HOME=/opt/ida-9.4 ida          # run from a custom location
```

See [docs/apps.md](docs/apps.md#ida-free--pro) and
[docs/troubleshooting.md](docs/troubleshooting.md#ida-free--pro).

## Community

- [Security policy](SECURITY.md) — what counts as a vulnerability and how to
  report one privately
- [Contributing](CONTRIBUTING.md) — repo layout, style, testing before a PR
- [Code of conduct](CODE_OF_CONDUCT.md)

Issues and pull requests are welcome. Use the issue templates for bug
reports and feature requests.

## Author

Created by **Prepakis Georgios** (aka **kernelstub**).

- X / Twitter: [x.com/kernelstub](https://x.com/kernelstub)
- Email: [kern@skuntir.com](mailto:kern@skuntir.com)

## License

Released into the public domain under the [Unlicense](LICENSE). Do anything
you want with it.
