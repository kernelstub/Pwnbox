# Themes & customization

Everything visual is driven from one palette. You can either let pywal extract
that palette from a wallpaper, or pin it with a custom theme.

## The `ALT + S` menu

| Entry | What it changes |
| --- | --- |
| **Pywal** | Pick a wallpaper; extract a palette from it |
| **Custom** | Pick one of the fixed-palette themes |
| **Style** | Bar layout (15 styles) |
| **Corner radius** | Window rounding, in px |
| **Window borders** | Hyprland window border on/off |
| **UI corner radius** | Bar / panel / rofi rounding, in px |
| **System font** | UI font |
| **System font size** | UI font size |
| **Application font** | Monospace/app font |
| **Application font size** | App font size |
| **Window shadows** | Drop shadow behind windows on/off |
| **Blur** | Window / UI blur on/off |
| **Transparency** | Window / UI opacity (%) |
| **Animations** | Hyprland animations on/off |

Every choice is written to `~/.cache/pwnbox/theme/` and re-applied on login.
Blur and transparency cover Hyprland windows as well as the Quickshell bar,
control center and popups (and rofi): the alpha is baked into Quickshell's
`Theme.js` and the shell restarts on change. Window borders and shadows are
written into the generated Hyprland config and applied with a `hyprctl reload`.

## Wallpaper themes (Pywal)

`ALT + S → Pywal` scans `~/.local/share/pwnbox/wallpapers` (the flake's
`dotfiles/gnome/wallpapers`, linked read-only). Pick an image and pywal derives
a 16-colour palette from it. That palette is then written everywhere:

- Quickshell (`~/.config/quickshell/Theme.js`)
- kitty, rofi, fuzzel
- GTK 3 / 4 and GNOME settings
- Hyprland borders, Hyprlock
- Neovim, Zed
- Telegram, Equibop, Spotify, Signal
- Stremio Enhanced (`~/.config/stremio-enhanced/themes/pwnbox.theme.css`,
  applied once under Settings → Themes; restart the app after a switch)
- IDA Pro 9.x / IDA Free (`<IDA>/themes/pwnbox/` + `~/.idapro/themes/pwnbox/`,
  with the active theme and fonts set in `~/.idapro/ida.reg`; a legacy
  `~/.idapro/cfg/pwnbox.clr` is generated for IDA Free 8.x)
- Obsidian (`~/Documents/Notes/.obsidian/snippets/pwnbox.css`, enabled in
  `appearance.json`; fonts and corner radius follow too)
- Zen (browser chrome, about: pages and 131 site themes, see
  [Browser](browser.md))

Add wallpapers by dropping images into `dotfiles/gnome/wallpapers/` and
rebuilding. The wallpaper fades in on every theme change (`awww`).

## IDA Free / Pro

The IDA theme is a flat CSS theme generated from the same palette:

- every background layer uses `background`, separations use the background
  lightened 12% (the same border as Zed), and function/import highlights
  are the plain background (no tint).
- generated into `~/.idapro/themes/pwnbox/` and mirrored into
  `<IDA>/themes/pwnbox/`; the active theme and the fonts are set in
  `~/.idapro/ida.reg`.
- IDA reads the CSS at startup: **restart IDA** after a theme switch.
- IDA Free 8.x gets a legacy `~/.idapro/cfg/pwnbox.clr` instead.

See [Apps](apps.md#ida-free--pro) for the full picture.

## Obsidian

The `~/Documents/Notes` vault (created by `scripts/install.sh`) follows the same
palette through the `pwnbox` CSS snippet:

- `pwnbox-theme` regenerates the snippet from the active palette and keeps it
  enabled in `appearance.json`, alongside the pwnbox fonts and the window
  corner radius.
- Community plugins are preinstalled and enabled by the activation script:
  **Dataview, Templater, Obsidian Git, Kanban, Outliner, Style Settings,
  LaTeX Suite** and **QuickAdd** (installed once, never downgraded).
- Restart Obsidian (or "Reload app without saving") after a theme change.

## Custom themes

A custom theme is a folder under `dotfiles/themes/<Name>/` with a `theme.conf`
and (optionally) a wallpaper:

```
dotfiles/themes/
└── Pwnbox/
    ├── theme.conf
    └── wallpaper.png
```

A fresh installation applies the `Pwnbox` theme by default; if its folder is
missing, the built-in Monochrome palette is the fallback. Additional themes can
be installed from [kernelstub/Pwnbox-Themes](https://github.com/kernelstub/Pwnbox-Themes)
or created locally.

`theme.conf` is INI-style:

```ini
name = My theme
wallpaper = wallpaper.png

background = #101014
foreground = #e6e6e6
cursor = #e6e6e6

color0 = #17171c
color1 = #f7768e
```

Any missing colour falls back to the monochrome palette, so a minimal theme is
just `name`, `background` and `foreground`. See
`dotfiles/themes/README.md` for the full reference.

After adding a theme folder, `git add` it and rebuild
(`./scripts/install.sh switch`) so it is linked, then choose it from
`ALT + S → Custom`. The flake only sees files tracked by
git, so an untracked theme folder is silently ignored even after a rebuild. The
command-line equivalent is `pwnbox-theme custom`.

Thumbnails are cached in `~/.cache/pwnbox/theme/thumbs` but keyed on the
resolved wallpaper path and size/mtime, so replacing a theme's `wallpaper.png`
updates the picker automatically on the next rebuild (`pwnbox-theme refresh`
runs during activation). No cache clearing is needed.

## Community themes

The community gallery is
[kernelstub/Pwnbox-Themes](https://github.com/kernelstub/Pwnbox-Themes). Themes
there follow the same folder layout as the built-in ones:

```bash
cp -r Pwnbox-Themes/themes/<name> ~/pwnbox/dotfiles/themes/
cd ~/pwnbox
git add dotfiles/themes/<name>
./scripts/install.sh switch
```

Then choose it from `ALT + S → Custom`, or run `pwnbox-theme custom`. The
repository includes a validator (`scripts/validate-theme.py`) and a
[creation guide](https://github.com/kernelstub/Pwnbox-Themes/blob/main/docs/usage/create.md).

## What is generated

The theme scripts read the active palette and write a small set of files that
apps include or read:

| Generated file | Used by |
| --- | --- |
| `~/.config/quickshell/Theme.js` | Quickshell bar/panels |
| `~/.cache/pwnbox/theme/kitty.conf` | kitty (included by the base config) |
| `~/.cache/pwnbox/theme/rofi.rasi` | rofi (imported by the themes) |
| `~/.cache/pwnbox/theme/fuzzel.ini` | fuzzel |
| `~/.cache/pwnbox/theme/gtk-colors.css` | GTK 3/4 |
| `~/.cache/pwnbox/theme/nvim-palette.lua` | Neovim |
| `~/.cache/pwnbox/theme/hyprland.conf` | Hyprland borders |
| `~/.cache/pwnbox/theme/colors.json` | helpers/scripts |
| `~/.config/zed/themes/pwnbox.json` | Zed |
| `~/.config/telegram/pwnbox.tdesktop-theme` | Telegram / AyuGram |
| `~/.config/spicetify/Themes/pwnbox/color.ini` | Spotify |
| `~/.config/equibop/settings/quickCss.css` | Discord (Equibop) |
| `~/.config/Signal/theme.css` | Signal (injected by the patched app, see [Apps](apps.md#signal)) |
| `~/.config/stremio-enhanced/themes/pwnbox.theme.css` | Stremio Enhanced |
| `<IDA>/themes/pwnbox/theme.css` (+ `icons/`) | IDA Pro 9.x / Free (CSS theme) |
| `~/.idapro/cfg/pwnbox.clr` | IDA Free 8.x (legacy `.clr`) |
| `~/.idapro/ida.reg` | IDA active theme + fonts (patched in place) |
| `~/Documents/Notes/.obsidian/snippets/pwnbox.css` | Obsidian (enabled snippet + `appearance.json`) |
| `<zen profile>/chrome/userChrome.css` | Zen browser UI |
| `<zen profile>/chrome/userContent.css` | Zen about: pages |
| `~/.cache/pwnbox/theme/userstyles/*.user.css` | Site themes for the pwnbox styles extension |

## Where state lives

| File | Meaning |
| --- | --- |
| `~/.cache/pwnbox/theme/wallpaper` | Current wallpaper path |
| `~/.cache/pwnbox/theme/custom-theme` | Current custom theme name |
| `~/.cache/pwnbox/theme/barstyle` | Current bar style |
| `~/.cache/pwnbox/theme/radius-window` | Window radius |
| `~/.cache/pwnbox/theme/radius-ui` | UI radius |
| `~/.cache/pwnbox/theme/blur` | `on` / `off` |
| `~/.cache/pwnbox/theme/opacity` | Transparency % |
| `~/.cache/pwnbox/theme/animations` | `on` / `off` |
| `~/.cache/pwnbox/theme/borders` | `on` / `off` |
| `~/.cache/pwnbox/theme/shadows` | `on` / `off` |
| `~/.cache/pwnbox/theme/font-ui` | System font |
| `~/.cache/pwnbox/theme/font-app` | Application font |
| `~/.cache/pwnbox/theme/font-size-ui` | System font size |
| `~/.cache/pwnbox/theme/font-size-app` | Application font size |

## Command line

`~/.scripts/pwnbox-theme` can be called directly:

```bash
pwnbox-theme menu
pwnbox-theme pick
pwnbox-theme custom
pwnbox-theme monochrome
pwnbox-theme apply <image>
pwnbox-theme barstyle
pwnbox-theme borders
pwnbox-theme windowborders
pwnbox-theme shadows
pwnbox-theme restore
pwnbox-theme styles
pwnbox-theme uifont
pwnbox-theme appfont
pwnbox-theme uifontsize
pwnbox-theme appfontsize
pwnbox-theme blur
pwnbox-theme transparency
pwnbox-theme animations
```
