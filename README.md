
<p align="center">
  <img width="1672" height="941" alt="image" src="https://github.com/user-attachments/assets/046e063f-0d41-43b0-81e4-beefd37a2c09" />
</p>




<p align="center">
  A ready-to-go <a href="https://nixos.org">NixOS</a> +
  <a href="https://github.com/nix-community/home-manager">home-manager</a> box for
  <b>hacking, reverse engineering, Active Directory and networking</b>.
  It's reproducible, portable and built for <b>privacy</b>.
</p>

---

## What you get

One flake, a complete workstation:

| Area | What you get |
| --- | --- |
| **Offensive tooling** | 26 toggleable categories, from recon and Active Directory to reversing, pwn, forensics, cloud and more. |
| **Daily-driver apps** | Encrypted chat, browsers, office, media, wallets, containers and VMs, plus Neovim, Zed and IDA Free / Pro. |
| **Theming** | One palette from a pywal wallpaper or fixed theme, applied across the desktop, terminals, editors, chat apps, browser and IDA. |
| **Privacy** | Volatile logs, zram-only swap, RAM-backed `/tmp`, a hardened kernel and network, locked root, firewall on and a hardened Tor Browser. |
| **Desktop** | Hyprland with a Quickshell bar, notifications and control center, or GNOME as a second session. |
| **Reproducibility** | Every package, font and theme comes from the flake; nothing is downloaded at runtime. |

## Quick start

Requirements: an existing NixOS install, a user with `sudo` access, and network
access for the first fetch.

```bash
unzip pwnbox.zip     # or: tar -xzf pwnbox.tar.gz
cd pwnbox
./scripts/install.sh switch
```

The installer detects your user, hostname, time zone and hardware, creates
`hosts/<host>/`, refreshes `hardware-configuration.nix` / `boot.nix`, then
builds and activates. Garbage collection is opt-in with `--gc`.

- Full walkthrough: [Getting started](docs/setup/getting-started.md)
- Bootable images: [ISOs](docs/setup/isos.md)
- Most-used commands: `./scripts/install.sh switch` (rebuild),
  `update` (update inputs + rebuild), `ALT + S` (theme / settings menu)

## Documentation

The full manual lives in [`docs/`](docs/README.md):

| Document | What it covers |
| --- | --- |
| [Getting started](docs/setup/getting-started.md) | Install, first boot, updates, host config |
| [ISOs](docs/setup/isos.md) | Live/installer ISOs, live credentials, booting |
| [Desktop](docs/usage/desktop.md) | Hyprland, GNOME, Quickshell and the bar |
| [Keybinds](docs/usage/keybinds.md) | Every keyboard shortcut |
| [Themes](docs/usage/themes.md) | Wallpaper themes, custom and community themes, the `ALT + S` menu |
| [Fonts](docs/usage/fonts.md) | System/application fonts and sizes |
| [Apps](docs/usage/apps.md) | Per-app theming and live updates |
| [Browser](docs/usage/browser.md) | Zen, site themes and the pwnbox styles extension |
| [Packages](docs/reference/packages.md) | Tool categories and optional app sets |
| [Privacy](docs/usage/privacy.md) | Hardening and zero-trace defaults |
| [Architecture](docs/development/architecture.md) | Repo layout and how a theme switch works |
| [Troubleshooting](docs/reference/troubleshooting.md) | Common problems and fixes |
| [Development](docs/development/workflow.md) | Add themes, packages and bar styles |

## Community themes

Extra fixed-palette themes are collected in
[kernelstub/Pwnbox-Themes](https://github.com/kernelstub/Pwnbox-Themes). Copy a
theme folder into `dotfiles/themes/`, `git add` it, rebuild with
`./scripts/install.sh switch`, then select it from `ALT + S → Custom`. See
[Themes](docs/usage/themes.md#community-themes) for details.

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
