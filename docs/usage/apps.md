# Apps

pwnbox themes far more than the desktop shell. This page explains how each app
gets its colours and fonts, and which ones update live while running.

## Live theming (no restart)

When you change the theme, four apps refresh themselves in place:

| App | Mechanism |
| --- | --- |
| **Spotify** | Spicetify `watch` refreshes the injected CSS and reloads the UI |
| **Telegram (AyuGram)** | AyuGram watches the theme file and reloads it |
| **Discord (Equibop)** | Equibop watches `quickCss.css` and hot-applies it |
| **Signal** | the patched desktop app watches `~/.config/Signal/theme.css` and re-injects it |
| **Element** | the patched desktop app watches `~/.config/Element/theme.css` and re-injects it |
| **Wire** | the patched desktop app watches `~/.config/Wire/theme.css` and re-injects it |

You can keep them open. `ALT + S` is enough. The browser re-themes live too
(Pywalfox); see [Browser](browser.md). Stremio Enhanced reads its theme file
at startup, so restart it after a theme switch. SimpleX Chat has no live
theme support — `pwnbox-theme` restarts it automatically when the palette
changed.

## Signal

Signal Desktop does not support custom themes upstream, so the flake patches
the packaged app (`pkgs/apps/messaging/signal-desktop.nix`): the build unpacks `app.asar`,
appends a tiny loader (`pkgs/apps/messaging/signal-loader.js`) to the main process bundle and
repacks it. The loader reads `~/.config/Signal/theme.css` and injects it into
every renderer window via `webContents.insertCSS`, watching the file so
changes apply live.

On every theme change, `pwnbox-theme` (`sync_signal`) regenerates that file
from the active pywal / custom palette:

- the Axo design tokens (`--axo-color-*`: surfaces, labels, fills, borders,
  message bubbles, material colours) are mapped onto the palette ramp, with
  semantic slots (affirmative / warning / destructive / brand) taken from the
  `red`, `green`, `yellow` and `accent` palette entries;
- the application font from `ALT + S` is applied through `--font-sans` /
  `--font-mono` and the global `font-family` rules.

`pwnbox-theme` only writes the theme when Signal is installed. No setup step
is needed in the app itself: restart-free, and the theme follows both pywal
wallpapers and custom themes.

## Element

Element (Matrix) is themed the same way as Signal: the flake patches the
packaged app (`pkgs/apps/messaging/element-desktop.nix`) by appending
`pkgs/apps/messaging/element-loader.js` to the ESM main process bundle
(`lib/electron-main.js` in `app.asar`). The loader injects
`~/.config/Element/theme.css` into every window and watches the file, so
palette and font changes apply live.

On every theme change, `pwnbox-theme` (`sync_element`) regenerates that file:

- the Compound design tokens (`--cpd-color-*`: canvas/panel backgrounds,
  text, borders, icons, badge and status colours, gradients) are mapped onto
  the palette ramp, with action/accent slots taken from `accent`,
  destructive/affirmative/info slots from `red` / `green` / `cyan`;
- the raw `--cpd-color-gray-*` and `--cpd-color-green-*` ramps (referenced
  directly by Element's own theme css) are regenerated as a foreground →
  background and accent-shade ramp respectively;
- the application font from `ALT + S` goes into
  `--cpd-font-family-sans` / `--cpd-font-family-mono`.

The Element "theme" setting itself can stay at its default (dark): the
injected variables override the built-in dark theme.

`sync_element` also writes a proper Element custom theme
(`~/.cache/pwnbox/theme/userstyles/element-pwnbox.json`, served at
`http://localhost:8311/element-pwnbox.json` by the pwnbox userstyles
server). To make **Pwnbox** show up in the theme picker, add it once:

1. Settings → Labs (the tab is enabled through `show_labs_settings` in the
   packaged webapp config, see `pkgs/apps/messaging/element-desktop.nix`) → enable
   **Developer mode**;
2. avatar menu → Developer tools → Custom themes → paste the URL → Add;
3. Settings → Appearance → Theme → select **Pwnbox**.

(Element has no `feature_custom_themes` labs flag anymore — custom themes
are gated behind Developer mode instead. The theme is stored per-account,
so it also applies on other devices using the same Matrix account.)

## Wire

Wire Desktop is an Electron shell whose actual webapp runs in a remote
`<webview>`, so the flake patches the packaged app
(`pkgs/apps/messaging/wire-desktop.nix`) by appending `pkgs/apps/messaging/wire-loader.js` to the main
process bundle (`electron/dist/main.js` in `app.asar`). The loader injects
`~/.config/Wire/theme.css` into **every** webContents
(`web-contents-created` catches the webview guest as well as the shell
window) and watches the file, so palette and font changes apply live.

On every theme change, `pwnbox-theme` (`sync_wire`) regenerates that file:

- Wire's CSS variables are overridden on `body`: the `--gray-10` … 
  `--gray-100` ramp becomes a foreground → background ramp, the
  `--foreground` / `--background` fade ramps are regenerated with the
  matching alpha, and the framework slots (app/sidebar/input bar, borders,
  modals, message actions and reactions, text inputs, calling controls) are
  mapped onto the flat palette surfaces;
- the accent block (`--accent-color`, its `-50` … `-900` ramp, fades,
  selection, buttons, toggles) is derived from the `accent` palette entry,
  with the `red` / `green` / `yellow` / `cyan` entries feeding the
  `--*-500` color triples Wire uses for statuses and svg fills;
- the application font from `ALT + S` goes into `--font-family-base` and
  the UI corner radius into `--button-border-radius`.

Wire's built-in dark theme stays selected; the injected variables override
it.

## SimpleX Chat

SimpleX Chat's desktop app is built with Compose, not a web view, so there is
no CSS to inject and no live reload: the palette is written as a theme
override and applied on app start.

On every theme change, `pwnbox-theme` (`sync_simplex`):

- merges a `pwnbox` theme override (all twelve `ThemeColors` slots:
  accent, background, surfaces, message bubbles and replies) into
  `~/.config/simplex/themes.yaml`, preserving any other themes in the file;
- selects it via `CurrentTheme` / `SystemDarkTheme` / `CurrentThemeIds` in
  `~/.config/simplex/settings.properties` (only these three keys are
  touched);
- restarts a running instance automatically, since both files are only read
  at startup.

Fonts: the app hardcodes its bundled Inter fonts, so the pwnbox launcher
(`pkgs/apps/messaging/simplex-launcher.sh`) swaps `fonts/Inter-*.ttf` inside the app jar
for the current application font (via `fc-match`) in a writable copy under
`~/.local/share/pwnbox/simplex` and runs that copy — the repack only happens
when the font setting changes.

## Stremio Enhanced

pwnbox ships [Stremio Enhanced](https://github.com/REVENGE977/stremio-enhanced)
(the community fork with plugin and theme support) instead of plain Stremio.
It is packaged in `pkgs/apps/media/stremio-enhanced.nix` and enabled in
`pkgs/custom.nix` as `pwnbox.stremio-enhanced`.

### The package

- The upstream **AppImage** (x86_64 and aarch64) is wrapped in an FHS
  environment so it runs on NixOS unmodified.
- **Fonts.** The FHS sandbox only exposes a minimal font set by default, so
  the flake puts the whole pwnbox font library (Manrope, Fairfax Hax HD,
  the Nerd Fonts, …) into the sandbox and points fontconfig at
  it — the `ALT + S` application font renders correctly.
- **Streaming server.** Stremio plays through its local streaming server
  (`server.js`). The flake fetches it from `dl.strem.io` at build time
  (`serverVersion` in `pkgs/apps/media/stremio-enhanced.nix`) and seeds it to
  `~/.config/stremio-enhanced/streamingserver/server.js` (plus `version.txt`)
  on activation. The app updates it itself when Stremio releases a new
  version; bump `serverVersion` and rebuild to pre-seed a newer one.

### Theme

On every theme change, `pwnbox-theme` (`sync_stremio`) writes a Stremio
Enhanced theme file to `~/.config/stremio-enhanced/themes/pwnbox.theme.css`:

- The palette is read from pywal first (`~/.cache/wal/colors.json`), then the
  pwnbox cache, then the monochrome seed — so the app always shows the active
  wallpaper or custom theme's colours.
- Flat look: primary and secondary backgrounds are the same colour, with
  subtle background-lifted surfaces for modals and menus, a soft accent glow,
  the `ALT + S` **application font** and the **UI corner radius**.
- No global border overrides.

Apply the **pwnbox** theme once (Stremio Enhanced → Settings → Themes); from
then on it follows every theme change. The file is read at startup, so
**restart Stremio Enhanced** to see a new palette.

## Spotify

Spotify is patched with [Spicetify](https://spicetify.app) so it can be
themed. Because nixpkgs' Spotify lives read-only in the Nix store,
`pwnbox-spotify` keeps a writable copy under `~/.local/share/pwnbox/spotify`
and patches that.

- Palette → `~/.config/spicetify/Themes/pwnbox/color.ini`
- Layout + full theming → `user.css`, composed at runtime from the managed
  `user-base.css` plus a generated font block.
- The base CSS themes **inputs, search fields, context menus, popovers, modals,
  tooltips and buttons**, flattens Spotify's artwork gradients and **removes
  every scrollbar**.
- Fonts follow the System (body) and Application (code) fonts.
- **Spicetify Marketplace** is installed by default
  (`~/.config/spicetify/CustomApps/marketplace`, enabled in `custom_apps`) so
  extensions, themes and CSS snippets can be installed from inside Spotify.

Live updates use `spicetify watch -s -l`. The launcher passes
`--remote-debugging-port` so the watcher can attach without relaunching
Spotify; a background helper keeps the watcher alive.

Commands:

```bash
pwnbox-spotify apply
pwnbox-spotify fonts
pwnbox-spotify launch
pwnbox-spotify restart
pwnbox-spotify stop
pwnbox-spotify cleanup
```

`launch` reuses a running client, focusing its window instead of starting a
second instance. Each client runs in a transient `pwnbox-spotify-*.scope`, and
a user timer reaps renderer/GPU helpers left behind after a crash. `stop` closes
every scope; `cleanup` only removes leftovers when no top-level client is
running.

## Discord (Equibop)

Equibop is the Discord client (Equicord). Its theme lives in
`~/.config/equibop/theme-base.css`. On every theme change `pwnbox-theme`
recolours it to `~/.config/equibop/settings/quickCss.css`, which Equibop
watches and applies live.

Fonts are set through `--font` (System) and `--font-code` (Application), plus a
generated root font size. The network font imports were removed; local fonts
are used instead.

## Telegram (AyuGram)

AyuGram is configured through `tg-config`, which writes into Telegram's
encrypted `tdata`.

- Palette → `~/.config/telegram/pwnbox.tdesktop-theme` (generated from
  `awesome.tdesktop-theme`, with a flat solid chat background colour).
- AyuGram watches that file, so rewriting it reloads the colours **live**.
- Fonts: the application font is written into AyuGram's `monoFont` setting
  on every theme/font sync. AyuGram only reads it at startup, so pwnbox
  restarts it automatically when the font actually changed and AyuGram is
  running. Telegram's UI uses the system font.

`pwnbox-theme` only syncs `tdata` (which requires Telegram to be closed) when
AyuGram is not running. While it is running, the theme file is rewritten and
AyuGram reloads itself.

## Editors & terminals

| App | Theme | Fonts |
| --- | --- | --- |
| **kitty** | generated `kitty.conf` include | Application font + size |
| **Zed** | `~/.config/zed/themes/pwnbox.json` | UI + buffer fonts/sizes |
| **Neovim** | generated `nvim-palette.lua` | inherits the terminal |
| **micro / ranger** | terminal colours + config | inherit the terminal |

## Obsidian

The vault is `~/Documents/Notes` (created by `scripts/install.sh`).

- Palette → `~/.obsidian/snippets/pwnbox.css`, enabled and kept enabled in
  `appearance.json` on every theme change; fonts and corner radius follow the
  pwnbox states.
- Community plugins (Dataview, Templater, Obsidian Git, Kanban, Outliner,
  Style Settings, LaTeX Suite, QuickAdd) are installed and enabled once by
  the activation script — updates stay in Obsidian's hands afterwards.
- Restart Obsidian (or "Reload app without saving") after a theme change.

## GTK & launchers

- **GTK 2 / 3 / 4 / GNOME.** `~/.cache/pwnbox/theme/gtk-colors.css` is imported
  by the GTK config, and `gsettings`/`dconf` keep fonts and colour scheme in
  sync (GTK 2 gets the font through `~/.gtkrc-2.0`).
- **rofi.** Imports `~/.cache/pwnbox/theme/rofi.rasi`.
- **fuzzel.** Uses `~/.cache/pwnbox/theme/fuzzel.ini`.
- **Zathura.** A generated include (`~/.cache/pwnbox/theme/zathura.conf`) sets
  the application font.

## IDA Free / Pro

IDA is proprietary and not in nixpkgs, so pwnbox wraps a **locally
installed copy**. Nothing is downloaded: install IDA yourself and the flake
takes care of the rest.

### The wrapper

`pkgs/security/ida-fhs.nix` builds an FHS environment with every system library IDA
links against (Qt platform deps, X11/XCB, fontconfig, freetype, glib, GTK,
libglvnd, wayland, dbus, zlib, …). It is installed whenever
`pwnbox.packages.hacking` is on and provides:

| Command | What it runs |
| --- | --- |
| `ida` | The GUI (IDA Pro 9.x) / `ida64` on older builds |
| `ida64` | `ida64` (falls back to `ida`) |
| `idat` | Text mode |
| `hv` | The bundled hex viewer |

The wrapper looks for the install in `~/Software/RE/IDA` by default.
Point it anywhere with `PWNBOX_IDA_HOME`:

```bash
PWNBOX_IDA_HOME=/opt/ida-9.4 ida
export PWNBOX_IDA_HOME=$HOME/tools/ida   # persist it
```

The IDA installer's own `.desktop` entry (which runs the raw binary) is
rewritten to use the wrapper on every rebuild.

The raw binary runs on its own too: `programs.nix-ld`
(`modules/nixos/nix.nix`) provides the same library set, so
`~/Software/RE/IDA/ida` works directly — like any other unpatched binary
you download.

### Theme

On every theme change, `pwnbox-theme` generates a CSS theme
(`pwnbox` in the theme picker) into `~/.idapro/themes/pwnbox/` and mirrors
it into `<IDA>/themes/pwnbox/`:

- **Flat look.** Every background layer (window, views, dialogs, lists,
  tooltips, graphs, registers, nav band) is the same `background` colour.
- **Subtle borders.** All separations (listing, menubar, toolbars, docks,
  output window, choosers, tabs, inputs, graph nodes) use the same
  background lightened 12% — the Zed border.
- **No highlight tints.** Function/identifier highlights and import/graph
  node tints are the plain background; syntax colours stay.
- **Fonts.** The pwnbox application font is used for `Disassembly`,
  `Hex view`, `Output window` and `Text input`; the system font for the
  rest. Both are written to `~/.idapro/ida.reg` (with its CRC re-sealed).
- The active theme is set to `pwnbox` in `~/.idapro/ida.reg`. IDA reads
  the CSS at startup — **restart IDA** to see a new palette.
- For IDA Free 8.x (the pre-CSS UI), a legacy
  `~/.idapro/cfg/pwnbox.clr` is generated too.

### Plugin

The pwnbox plugin is installed into `~/.idapro/plugins/`. It retags
Hex-Rays pseudocode tokens (so keywords, operators, members and variables
each get their own colour), themes the nav band arrows and the window
chrome, and enables itself only while the `pwnbox` theme is active.
Action icons are left as IDA's own (the theme has none bundled).

## Browser

Zen is themed end to end: chrome, about: pages and 131 site themes. See
[Browser](browser.md). Tor Browser is deliberately unthemed and hardened for
hostile sites; see [Privacy](privacy.md#browser).

## Desktop shell

Quickshell, Hyprland borders, Hyprlock and the notification daemon all read
`~/.config/quickshell/Theme.js` and the generated Hyprland include. See
[Desktop](desktop.md).
