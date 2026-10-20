# pwnbox documentation

pwnbox is a portable, hardened NixOS + home-manager configuration for hacking,
reverse engineering, Active Directory and networking. It ships a Hyprland
desktop (with GNOME as a second session) driven by Quickshell, and a
wallpaper-driven theming system that reaches every app.

This folder is the full manual. Start with [Getting started](getting-started.md)
and jump to whatever you need.

| Document | What it covers |
| --- | --- |
| [Getting started](getting-started.md) | Install, first boot, updates, host config |
| [ISOs](isos.md) | Building live/installer ISOs, live credentials, booting |
| [Desktop](desktop.md) | Hyprland, GNOME, Quickshell, sessions |
| [Keybinds](keybinds.md) | Every keyboard shortcut |
| [Themes](themes.md) | Wallpaper themes, custom themes, the `ALT + S` menu |
| [Fonts](fonts.md) | System/application fonts and sizes |
| [Apps](apps.md) | Per-app theming and live updates (Spotify, Discord, Telegram, Stremio Enhanced, IDA Free/Pro) |
| [Browser](browser.md) | Zen, site themes and the pwnbox styles extension |
| [Packages](packages.md) | Tool categories and optional app sets |
| [Privacy](privacy.md) | Hardening and zero-trace defaults |
| [Architecture](architecture.md) | Repo layout and how a theme switch works |
| [Troubleshooting](troubleshooting.md) | Common problems and fixes |
| [Development](development.md) | Add themes, packages and bar styles |
| [Security policy](../SECURITY.md) | Reporting vulnerabilities privately |
| [Contributing](../CONTRIBUTING.md) | Repo layout, style, testing before a PR |

## At a glance

- **One settings menu.** `ALT + S` changes theme, wallpaper, bar style,
  corner radii, fonts, font sizes, blur, transparency and animations.
- **Everything follows the wallpaper.** Colours are extracted with pywal and
  applied to the bar, terminal, launcher, notifications, editor, GTK apps,
  chat clients, Stremio, IDA and the browser (131 site themes).
- **Live app theming.** Spotify, Discord (Equibop), Telegram (AyuGram) and
  Signal update while they are running, without quitting them.
- **Reproducible.** Nothing is downloaded at runtime; every tool, theme and
  font comes from the flake.

## Conventions used here

- Paths starting with `~` are relative to the primary user's home.
- `ALT + S` opens the theme/settings menu unless stated otherwise.
- Commands are shown for the default setup; replace the host name if you
  installed under a different one.
