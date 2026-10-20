# Fonts

pwnbox has two independent font settings, both in `ALT + S`:

| Setting | Default | Used for |
| --- | --- | --- |
| **System font** | `Manrope` | UI text: bar, rofi, fuzzel, GTK, Discord, Spotify |
| **System font size** | `9` | The size of that UI text |
| **Application font** | `Iosevka Nerd Font Mono` | Monospace text: terminal, code, Zed buffers |
| **Application font size** | `9` | The size of that monospace text |

Sizes are chosen from `7 8 9 10 11 12 13 14 15 16 18 20`. The settings are
stored in `~/.cache/pwnbox/theme/font-ui`, `font-app`, `font-size-ui` and
`font-size-app`, and re-applied on login.

## Font choices

Pick from a curated list that includes:

`Manrope`, `Fairfax HD`, `Ubuntu`, the Spleen bitmap fonts,
`Iosevka`, `JetBrains Mono`, `MesloLGS`, `FiraCode`, `Inconsolata`,
`Noto Sans`, `DejaVu Sans` and `Liberation`. Each comes with its Nerd Font
variants where available. Everything is installed by the flake; nothing is
downloaded at runtime.

## Where each font lands

| App | System font | Application font |
| --- | --- | --- |
| Quickshell (bar/panels) | `fontFamily` + `fontSize` | icons via Nerd Font |
| kitty | n/a | `font_family` + `font_size` |
| rofi | `font` | n/a |
| fuzzel | `font` | n/a |
| GTK 2/3/4 + GNOME | `gtk-font-name` / gsettings | n/a |
| Hyprlock | `font_family` | n/a |
| Zed | `ui_font_family` + `ui_font_size` | `buffer_font_family` + `buffer_font_size` |
| Discord (Equibop) | `--font` + root size | `--font-code` |
| Stremio Enhanced | n/a | `font-family` in the generated `pwnbox.theme.css` |
| Spotify | body text + root size | code / monospace |
| Telegram (AyuGram) | system (Qt) | `monoFont` |
| IDA Pro 9.x / Free | `Debug registers`, `Structured data views`, `Tabular views` | `Disassembly`, `Hex view`, `Output window`, `Text input` (via `ida.reg`) |
| Zathura | n/a | `set font` |
| Zen (browser chrome + site styles) | n/a | generated `userChrome.css` + userstyles |

Apps that run inside the terminal (micro, Neovim, ranger, btop, fastfetch, …)
inherit the kitty font automatically.

## How it is applied

`~/.scripts/pwnbox-theme` regenerates each app's font configuration whenever
the font or size changes:

- managed config files stay read-only; a generated *include* or a generated
  companion file carries the font (for example `~/.cache/pwnbox/theme/kitty.conf`
  is included at the end of `kitty.conf`).
- Spotify reads `~/.config/spicetify/Themes/pwnbox/user.css`, which is composed
  from a managed base plus a generated font block.
- Zathura reads a generated `zathura.conf` through an `include` in `zathurarc`.

When a font changes, kitty is signalled to reload, Zed applies it live
(its `settings.json` is a real file that gets edited in place), GTK apps get
the new font via gsettings (GTK 3/4) or a rewritten `~/.gtkrc-2.0` (GTK 2),
and Quickshell is restarted automatically. IDA's fonts are written to
`~/.idapro/ida.reg` (only while IDA is closed) and apply on its next start.
