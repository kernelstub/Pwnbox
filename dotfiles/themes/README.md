# Custom pwnbox themes

Each **subfolder** here that contains a `theme.conf` is a custom colour theme.
It appears in the `ALT + S` settings menu under **THEME → Custom** as a
thumbnail card: its wallpaper with the theme name below.

A fresh installation starts with the `Pwnbox` theme; if its folder is missing,
the built-in Monochrome palette is the fallback.

```
dotfiles/themes/
└── Pwnbox/                 # applied by default on a fresh installation
    ├── theme.conf
    └── wallpaper.png
```

More themes live in
[kernelstub/Pwnbox-Themes](https://github.com/kernelstub/Pwnbox-Themes). To add
one, copy its folder here; any subfolder with a `theme.conf` is picked up.

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

## Adding a theme

1. Create `dotfiles/themes/<Name>/theme.conf` (copy `Pwnbox` as a base).
2. Drop a wallpaper in the same folder.
3. `git add` the folder — the flake only includes git-tracked files, so an
   untracked theme is silently ignored — then `nixos-rebuild switch`, and
   choose it from `ALT + S → THEME → Custom`.

The command line equivalent is `pwnbox-theme custom`.
