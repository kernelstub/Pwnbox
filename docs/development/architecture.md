# Architecture

## Repository layout

```
.
├── flake.nix                 # inputs and outputs
├── scripts/
│   ├── install.sh            # bootstrap / rebuild helper
│   └── iso.sh                # live/installer ISO builder
├── hosts/                    # per-machine configs (one dir per host)
│   └── nixos/                # template host
├── modules/
│   ├── nixos/                # system modules
│   │   ├── desktop/          # Hyprland, GNOME, LY, fonts, GTK, X
│   │   ├── hardening.nix     # kernel/network hardening
│   │   ├── options.nix       # the pwnbox.* option tree
│   │   └── …
│   └── home/                 # home-manager modules
│       ├── dotfiles.nix      # links configs, theme activation
│       ├── gtk.nix           # GTK + dconf
│       ├── neovim.nix
│       ├── packages.nix
│       └── shell.nix         # zsh + aliases
├── pkgs/                     # package sets, toolset categories, custom.nix
│   ├── categories/           # one file per pentest tool category
│   ├── apps/
│   │   ├── browsers/         # Zen, Tor Browser hardening, pywalfox host
│   │   ├── media/            # Stremio Enhanced, Spicetify Marketplace
│   │   ├── messaging/        # Signal, Element, Wire, SimpleX, Telegram config
│   │   ├── notes/            # Obsidian plugins
│   │   └── wallets/          # Exodus
│   ├── desktop/              # dotfiles, fonts, cursors, GRUB theme
│   ├── security/             # IDA wrapper, Impacket tools, SharpHound
│   ├── categories.nix
│   ├── custom.nix
│   ├── default.nix
│   └── toolset.nix
├── docs/                     # manual, grouped by audience
│   ├── setup/                # install and ISO guides
│   ├── usage/                # desktop, apps, themes and privacy
│   ├── reference/            # packages and troubleshooting
│   └── development/          # architecture and contributor workflow
├── overlays/                 # nixpkgs overlay
└── dotfiles/
    ├── config/               # app configs (kitty, rofi, quickshell, …)
    │   └── wal/              # pywal templates + monochrome seed
    ├── ida/                  # IDA theme plugin + tintable icon templates
    ├── themes/               # custom fixed-palette themes
    ├── zen/                  # theme-only user.js + site style templates
    ├── gnome/                # fonts, GTK base CSS, wallpapers
    └── scripts/              # pwnbox-theme, pwnbox-spotify, …
```

## How files are deployed

Home-manager links most config files read-only from the Nix store
(`xdg.configFile`). Files that must change at runtime are handled in one of two
ways:

1. **Included/generated companion.** The managed file ends with an `include`
   or an `@import` of a writable file under `~/.cache/pwnbox/theme/`
   (kitty, rofi, fuzzel, Hyprland, GTK).
2. **Base + generated output.** The managed file is a *base*; a script
   composes the final file next to it (Spotify `user.css`), or the managed file
   *includes* a generated snippet (Zathura `zathura.conf`).

This is why `~/.config/kitty/kitty.conf` is a store symlink but
`~/.cache/pwnbox/theme/kitty.conf` is writable.

## What happens on `ALT + S`

```
rofi menu
   │
    ├─ Pywal ─────► wal -i <image>  ─┐
    ├─ Custom ────► build scheme ────┤
    │                                ▼
    │                        install palette
    │                    (kitty, rofi, fuzzel, GTK,
    │                     Hyprland, Neovim, Zed,
    │                     Quickshell Theme.js,
    │                     IDA theme + registry + .clr,
    │                     Stremio Enhanced theme,
    │                     Signal theme.css,
    │                     Zen chrome + site styles)
   │                                │
   ├─ bar style ──► qs ipc call barstyle set
   ├─ radius/blur/opacity/animations ──► hyprctl reload + quickshell restart
   ├─ fonts/sizes ──► regenerate per-app font config
   │
   └──────────────► reload_apps
                        ├─ kitty: SIGUSR1
                        ├─ hyprctl reload
                        ├─ GTK colour-scheme refresh
                        ├─ restart Quickshell
                        ├─ Pywalfox update (browser re-theme)
                        └─ live app theming
                             ├─ Spotify (Spicetify watch)
                             ├─ Telegram (theme file watcher + auto-restart for fonts)
                             ├─ Equibop (quickCss hot-apply)
                             └─ Signal (patched app watches theme.css)
```

The palette flows from a single source of truth: the 16-colour scheme produced
by pywal (or a custom `theme.conf`). `dotfiles/config/wal/templates/` contains
the templates that turn it into each app's format.

## State and generated files

- Settings live in `~/.cache/pwnbox/theme/` (see
  [Themes → Where state lives](../usage/themes.md#where-state-lives)).
- Generated app configs live next to their managed base or under
  `~/.cache/pwnbox/theme/`.
- On activation, the Stremio streaming server (`server.js`) is seeded into
  `~/.config/stremio-enhanced/streamingserver/` (see
  [Apps](../usage/apps.md#stremio-enhanced)).
- On login, `pwnbox-theme restore` re-applies the saved wallpaper/theme and
  effects, then `reload_apps` re-syncs the live apps.

## Scripts

| Script | Role |
| --- | --- |
| `~/.scripts/pwnbox-theme` | The theme engine (menu, pickers, palette, fonts, state) |
| `~/.scripts/pwnbox-ida-reg` | Patches `~/.idapro/ida.reg` (theme + fonts, CRC re-seal) |
| `~/.scripts/pwnbox-spotify` | Writable Spotify + Spicetify + watch |
| `~/.scripts/pwnbox-screenshot` | Region/full/saved screenshots |
| `~/.scripts/status` | Small status helper |

## Flake outputs

| Output | Purpose |
| --- | --- |
| `nixosConfigurations.<host>` | The system configuration |
| `nixosModules.default` / `.home-manager` | Reusable modules |
| `homeManagerModules.default` | Home configuration |
| `overlays.default` | nixpkgs overlay (fonts, cursors, toolset) |
| `packages.<system>` | Toolset packages |
| `formatter.<system>` | `nixfmt` |
| `devShells.<system>.default` | `nixfmt`, `statix`, `deadnix` |
