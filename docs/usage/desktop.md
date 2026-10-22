# Desktop

pwnbox ships two Wayland sessions: **Hyprland** (the default) and **GNOME**.

## Sessions

| Session | Notes |
| --- | --- |
| Hyprland | Default; Quickshell bar, notifications and control center |
| GNOME | Second session; Colloid-Dark-Grey theme and curated extensions |

At login, LY shows the clock and the session picker.

## Editors

Neovim is configured VS Code-style — LSP, completion, Telescope, Treesitter,
gitsigns, neo-tree, which-key and more — with every plugin supplied by Nix.
Zed is the GUI editor and follows the same palette, fonts and border styling.

## Hyprland

Window management is configured in `dotfiles/config/hypr/hyprland.conf`:

- `general`. Gaps, borders (border colour is generated from the theme).
- `decoration`. Rounding, opacity, shadow and blur (all driven by `ALT + S`).
- `animations`. Toggled from the settings menu.
- `monitor = , <resolution>, auto, auto`. From `pwnbox.desktop.resolution`
  (`highrr` by default: every monitor runs at its highest refresh rate).
- Workspaces. One plain global workspace set (1-10, no per-monitor splits):
  `ALT + 1..9` / `ALT + 0` (workspace 10) switches to that workspace,
  `SUPER + 1..9` / `SUPER + 0` moves the active window there,
  `CTRL + ALT + Left/Right` goes to the previous/next workspace.

Autostarted at login:

- `awww` with the last wallpaper (fades in on theme changes)
- `pwnbox-theme restore`. Re-applies the saved theme
- `hypridle`. Idle daemon (idle listeners disabled; the session never
  auto-locks or suspends)
- `hyprcorrect`. Desktop spelling correction and selected-text correction
  (see below)
- `hyprpolkitagent`
- `qs -n`. Quickshell
- `gnome-keyring-daemon`
- `cliphist` (text + images)

## Text correction

[hyprcorrect](https://github.com/jondkinney/hyprcorrect) runs in the
background and corrects the word or sentence you just typed. A separate
pwnbox helper corrects an existing selection with the system spellchecker.

| Keys | Action |
| --- | --- |
| `SUPER + ALT + C` | Correct the selected text in place |
| `SUPER + ALT + W` | Fix the last word |
| `SUPER + ALT + S` | Fix the last sentence |
| `SUPER + ALT + V` | Review the correction before applying |
| `SUPER + ALT + L` | Review with the LLM provider |

`SUPER + ALT + C` works on editable GUI text fields. Select the text, press
the chord, and the corrected text replaces it. In a terminal the corrected
selection is copied to the clipboard instead, because a terminal selection is
not an editable range.

The hyprcorrect chords can be rebound with `hyprcorrect prefs` (or the
**hyprcorrect** launcher entry). The daemon needs membership in the `input`
group; pwnbox adds it automatically, so log out and back in once after the
first rebuild. The selected-text helper uses the bundled English `aspell`
dictionary and `wl-clipboard`.

## GNOME

GNOME is available as a second session (`modules/nixos/desktop/gnome.nix`),
themed with Colloid-Dark-Grey and a curated extension set:

- `user-theme@gnome-shell-extensions.gcampax.github.com` (Colloid-Dark-Grey)
- `lockscreen-extension@pratap.fastmail.fm`
- `hidetopbar@mathieu.bidon.ca`
- `notification-configurator@exposedcat`
- `dash-to-dock@micxgx.gmail.com`
- `blur-my-shell@aunetx`
- `tilingshell@ferrarodomenico.com`
- `rounded-window-corners@fxgn`

Shell defaults (enabled extensions, favourites, mutter overlay key, ...) are
applied through dconf in `modules/home/gtk.nix`.

## Quickshell

The bar, notifications, volume OSD, power menu, calendar and system panel are
built with Quickshell. The shell root is
`dotfiles/config/quickshell/shell.qml`.

### Bar styles

`ALT + S → Style` switches between the available bar layouts. The selected
style is stored in `~/.cache/pwnbox/theme/barstyle` and applied live. Fresh
installations start with the `islands` style.

| Style | Description |
| --- | --- |
| `islands` | Boxed groups (default) |
| `floating` | Floating islands |
| `flat` | Classic flat bar |
| `pill` | Centered pill |
| `capsule` | Rounded capsule |
| `bottom` | Bottom dock |
| `split` | Split pills |
| `blocky` | Blocky groups |
| `minipills` | Mini pills |
| `side` | Side bar, left edge |
| `sideright` | Side bar, right edge |
| `sidepill` | Floating pills, left edge |
| `sidepillright` | Floating pills, right edge |
| `sideminipills` | Mini pills, left edge |
| `sideminipillsright` | Mini pills, right edge |

Each style's geometry (height, edge, exclusive zone, clock alignment) is
defined once in `dotfiles/config/quickshell/BarStyles.js`.

### Control center

A single centered control center (`dotfiles/config/quickshell/ControlCenter.qml`)
replaces the individual dropdown panels. It opens in the middle of the screen and
contains everything, organised into cards:

- **Quick Settings.** Wi-Fi, Bluetooth, do-not-disturb, screenshot, GNOME
  settings and display toggles.
- **Power.** Battery status and brightness.
- **Network.** Wi-Fi on/off and access-point list with inline password prompt.
- **Bluetooth.** On/off, device scan, connect/disconnect/pair.
- **Session.** Lock, log out, suspend, reboot, shut down.
- **Calendar.** Live date and month view.
- **Now Playing.** Fullscreen player: large artwork, title/artist, seek bar,
  volume and playback controls.
- **Volume.** Per-app/output/input sliders with mute.
- **System.** CPU, memory, swap, disk, uptime and network stats.
- **Clipboard.** Clipboard history (newest first) with copy-back, per-item
  delete and clear-all.
- **Capture.** Area, full screen (all screens or one entry per monitor),
  active window, annotation and recording (also per monitor). Per-monitor
  full-screen screenshots wait 0.5 s so the control center is gone before the
  shot is taken.
- **Notifications.** Do-not-disturb, clear-all and the notification list.

Clicking any bar element (clock, stats, volume, Wi-Fi, Bluetooth, bell, power)
opens the control center scrolled to the matching section. `Escape` or clicking
outside closes it.

- **Volume OSD.** Appears on volume changes, on the main monitor.

### Reloading Quickshell

The theme scripts restart it automatically when needed. To do it by hand:

```bash
qs -n
```

## Rofi

Rofi is used for the launcher (`ALT + SPACE`), the theme/settings menu
(`ALT + S`), the wallpaper and custom-theme pickers and the bar-style picker.
All of them import the generated palette from
`~/.cache/pwnbox/theme/rofi.rasi`.

## Fuzzel

Fuzzel is used for the clipboard history picker
(`SUPER + \``).

## Lock screen

`hyprlock` uses the current wallpaper (blurred) and the system font. Colours
are written by the theme scripts.
