# Custom pwnbox themes

Each **subfolder** here that contains a `theme.conf` or `preset.conf` is a
theme. It appears in the `ALT + S` settings menu under **THEME → Custom** as a
thumbnail card: its wallpaper with the theme name below. Folders that also
ship a `preset.conf` additionally appear under **THEME → Presets**, which
applies the palette *and* the whole look: fonts, gaps, borders, transparency,
bar style and every other `ALT + S` setting.

A fresh installation starts with the `Pwnbox` theme; if its folder is missing,
the built-in Monochrome palette is the fallback.

```
dotfiles/themes/
└── Pwnbox/                 # applied by default on a fresh installation
    ├── theme.conf          # fixed 16-colour palette
    ├── preset.conf         # optional: full look-and-feel preset
    └── wallpaper.png
```

More themes live in
[kernelstub/Pwnbox-Themes](https://github.com/kernelstub/Pwnbox-Themes). To add
one, copy its folder here; any subfolder with a `theme.conf` or `preset.conf`
is picked up.

Unlike the wallpaper picker (which extracts a palette from an image with
pywal), a custom theme has a **fixed** palette that you write down yourself and
a **fixed** wallpaper, so the colours do not depend on the image.

## `theme.conf`

An INI-style file: `key = value`, one per line. Blank lines are ignored and
`#` or `;` only start a comment at the beginning of a line (so hex colours such
as `#1a1b26` are fine).

| Key | Meaning |
| --- | --- |
| `name` | Label shown in the picker. Defaults to the folder name. |
| `wallpaper` | Image used by the theme, relative to this folder (or absolute). Defaults to the first image in the folder, then to the bundled default wallpaper. |
| `background` | Window/terminal background. |
| `foreground` | Main text colour. |
| `cursor` | Text cursor. Defaults to `foreground`. |
| `color0` … `color15` | The 16-colour terminal palette. |

Any colour you leave out falls back to the monochrome palette, so a minimal
theme is just:

```ini
name = My theme
background = #101014
foreground = #e6e6e6
```

The Quickshell bar/notifications, rofi, GTK apps, window borders and the
editor's accent colours are all derived from the 16 colours above (see
`dotfiles/config/wal/templates/`), exactly like a wallpaper theme.

## `preset.conf` — full theme presets

A theme folder that contains a `preset.conf` is a **preset**: applying it from
`ALT + S → THEME → Presets` switches the palette *and* every other setting in
one shot. The file uses the same INI format as `theme.conf` and reuses its
palette (and wallpaper/name) when it does not define its own — a
`preset.conf` may live next to a `theme.conf` or replace it entirely.

Settings keys (every one is optional; a missing key keeps the current value):

| Key | Meaning |
| --- | --- |
| `barstyle` | Bar layout, one of the 15 style ids (`islands`, `floating`, `flat`, `pill`, `capsule`, `bottom`, `split`, `blocky`, `minipills`, `side`, `sideright`, `sidepill`, `sidepillright`, `sideminipills`, `sideminipillsright`). |
| `radius` | Window corner radius in px. |
| `uiradius` | UI (bar/panel/rofi) corner radius in px. |
| `borders` | Window borders `on` / `off`. |
| `shadows` | Window drop shadows `on` / `off`. |
| `blur` | Window / UI blur `on` / `off`. |
| `opacity` | Transparency of windows and the bar, `1`–`100` (100 = opaque). |
| `animations` | Hyprland animations `on` / `off`. |
| `gaps` | Spacing between windows (Hyprland `gaps_in`) in px. |
| `gaps_out` | Spacing between windows and the screen edges (`gaps_out`) in px. |
| `scale` | Display scale in % (50–200). |
| `font-ui` | System font (any name from the font picker). |
| `font-app` | Application / monospace font. |
| `font-size-ui` | System font size in px. |
| `font-size-app` | Application font size in px. |

A full preset is just the palette plus these lines:

```ini
# (palette keys from theme.conf, or here if there is no theme.conf)

barstyle = islands
radius = 9
uiradius = 9
borders = on
shadows = on
blur = on
opacity = 92
animations = on
gaps = 5
gaps_out = 10
scale = 100
font-ui = IoskeleyMono Nerd Font
font-app = IoskeleyMono Nerd Font
font-size-ui = 9
font-size-app = 9
```

## Adding a theme

1. Create `dotfiles/themes/<Name>/theme.conf` (copy `Pwnbox` as a base).
2. Drop a wallpaper in the same folder.
3. Optionally add a `preset.conf` to make it a full preset.
4. `git add` the folder — the flake only includes git-tracked files, so an
   untracked theme is silently ignored — then `nixos-rebuild switch`, and
   choose it from `ALT + S → THEME → Custom` (or `→ Presets`).

The command line equivalent is `pwnbox-theme custom` (or `pwnbox-theme preset`).
