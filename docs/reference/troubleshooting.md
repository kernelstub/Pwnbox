# Troubleshooting

## A theme change didn't apply everywhere

Re-apply from saved state:

```bash
~/.scripts/pwnbox-theme restore
```

Some apps only pick up colours when a new window opens (GTK apps). Log out and
back in for a full refresh.

## The bar is missing or looks wrong

Restart Quickshell:

```bash
qs -n
```

The bar style is read from `~/.cache/pwnbox/theme/barstyle`. Check it with
`cat ~/.cache/pwnbox/theme/barstyle`. If a style looks broken, switch to
another from `ALT + S → Style`.

## The control center opens in the wrong place

The control center is centered on the main monitor. If it is off-centre or
opens on the wrong monitor, make sure you rebuilt after the change and that
Quickshell restarted.

## Kitty shows "N by M cells" while resizing

That is kitty's live-resize overlay. It is drawn unconditionally by
`draw_resizing_text()` in `kitty/shaders.c` and has **no config option**, so
pwnbox patches it out in `overlays/default.nix` (`kitty.overrideAttrs` →
`postPatch`). If it comes back after a kitty update, the patch's
`--replace-fail` makes the build fail; update the matched string in the overlay
to the new one in `kitty/shaders.c`.

## Spotify

- **Theme not applied.** Run `pwnbox-spotify apply`, then check
  `~/.local/share/pwnbox/spotify/.applied` exists. If Spotify was updated, the
  writable copy is rebuilt automatically. If Spicetify's backup is stale (for
  example after a Spicetify update), `pwnbox-spotify apply` rebuilds the copy
  and re-applies from scratch.
- **Marketplace not showing.** Restart Spotify once after the first apply:
  custom apps are only baked in by a full `spicetify apply`, which is skipped
  while Spotify is running (the running client only receives live CSS updates).
  Check `spicetify config custom_apps` lists `marketplace` and that
  `~/.config/spicetify/CustomApps/marketplace` exists.
- **Changes don't show while running.** The live update uses
  `spicetify watch -s -l`. Check it is running with `pgrep -af 'spicetify watch'`
  and look at `~/.cache/pwnbox/spotify-watch.log`. The launcher passes
  `--remote-debugging-port`, so relaunch Spotify if you started it long ago.
- **Scrollbars are gone.** That is intentional. The base CSS hides them.
- **Fonts look wrong.** Run `pwnbox-spotify fonts` and reopen Spotify if the
  watcher isn't attached.
- **Many `spotify-wrapped` processes.** One client normally owns a renderer,
  GPU, network, storage, CDM and crashpad helper; those are not duplicate
  instances. If memory keeps growing after the window is closed, run
  `pwnbox-spotify stop` (or `pwnbox-spotify cleanup` for orphans). The launcher
  starts new clients in `pwnbox-spotify-*.scope`, so
  `systemctl --user stop 'pwnbox-spotify-*.scope'` also terminates the whole
  tree.
- **Duplicate Quickshell bars.** The theme helper now waits for the old shell
  to exit and starts exactly one replacement. Run `pwnbox-theme restart-shell`
  to recover a stuck session.

## Discord (Equibop)

- The theme is hot-applied by Equibop watching its `quickCss.css`. Make sure
  the built-in **QuickCSS** feature is enabled in Equibop settings.
- `pwnbox-theme` regenerates `quickCss.css` on every theme change; nothing
  else touches the window.

## Zen / site themes

- **pwnbox styles is disabled as unverified.** The bundled extension is not
  signed by AMO; the Zen wrapper disables signature enforcement so it can run.
  After an upgrade from a build that enforced signatures, restart Zen once.
- **Site themes not applied.** They only match in dark mode; the theme-only
  `user.js` requests the dark colour scheme, so restart Zen once after changing
  it. Also confirm `toolkit.legacyUserProfileCustomizations.stylesheets` is
  `true` in `about:config`.
- **Themes don't update live after a theme change.** The pwnbox styles
  extension polls the local server; click its toolbar icon and read the status
  line (version, last check, error). If it reports an error, make sure the
  server is up: `systemctl --user start pwnbox-styles.service` or
  `pwnbox-theme styles`.
- **Server not reachable.** The `pwnbox-styles` user service keeps it up at
  login; start it manually with `pwnbox-theme styles`.

## IDA Free / Pro

- **IDA won't start.** The `ida`/`idat`/`hv` commands are FHS wrappers
  around your local install. They look in `~/Software/RE/IDA`
  (set `PWNBOX_IDA_HOME` to change it). If you get
  `not found in …`, the path is wrong or IDA isn't installed there.
- **`./ida` fails with a missing `lib*.so`.** The raw binary relies on
  `programs.nix-ld` (`modules/nixos/nix.nix`), which provides the common
  X11/Qt/desktop libraries. If some other downloaded binary asks for a
  library that isn't there, add its nixpkgs package to
  `programs.nix-ld.libraries`.
- **Theme doesn't update after switching wallpaper.** IDA reads its CSS at
  startup — restart IDA. If it still doesn't change, the wal template may
  be stale: rebuild (`./scripts/install.sh switch`) so the template in the
  store matches the flake, then switch the wallpaper once more.
- **"corrupted registry file".** `~/.idapro/ida.reg` has a CRC. Only
  `pwnbox-ida-reg` should touch it; if it got broken another way, delete
  it (IDA recreates it, losing only UI settings) or restore a backup.
- **Fonts unchanged.** Fonts are written to `ida.reg` only while IDA is
  closed. Close IDA, run `~/.scripts/pwnbox-theme borders`, and reopen.
- **Pseudocode not retagged.** The plugin lives in `~/.idapro/plugins/`
  (installed on rebuild). It enables itself only when the `pwnbox` theme
  is active in Options → Colors.

## Telegram (AyuGram)

- While AyuGram runs, the theme file is rewritten and AyuGram reloads it live.
- The first time (or after the theme path changes), the path must be
  registered, which requires Telegram to be closed. Close and reopen it once;
  after that updates are live.
- Fonts are written to AyuGram's settings only while Telegram is closed.

## Stremio Enhanced

- **Theme not applied.** The pwnbox theme must be applied once in the app:
  Stremio Enhanced → Settings → Themes → **pwnbox** → Apply. Afterwards
  `pwnbox-theme` rewrites the same file on every theme change. Stremio reads
  it at startup, so **restart the app** after switching themes.
- **Colours don't match the wallpaper.** The theme is generated from the
  pywal palette (`~/.cache/wal/colors.json`). Re-run
  `~/.scripts/pwnbox-theme restore` and restart the app. If the file
  `~/.config/stremio-enhanced/themes/pwnbox.theme.css` is missing, the app's
  config directory does not exist yet — launch Stremio Enhanced once first.
- **"server.js not found" on startup.** The streaming server is seeded to
  `~/.config/stremio-enhanced/streamingserver/server.js` on activation. If it
  is missing, rebuild (`./scripts/install.sh switch`) or let the app download
  it from the dialog it shows.
- **Fonts look wrong.** The app font is written into the theme CSS. If it
  still falls back, the installed package may predate the font fix — rebuild
  (`./scripts/install.sh switch`) so the FHS sandbox carries the pwnbox fonts.

## Fonts or font sizes didn't change

Run the pickers again and confirm the state files:

```bash
cat ~/.cache/pwnbox/theme/font-ui ~/.cache/pwnbox/theme/font-app
cat ~/.cache/pwnbox/theme/font-size-ui ~/.cache/pwnbox/theme/font-size-app
~/.scripts/pwnbox-theme borders
```

kitty is signalled automatically; Quickshell is restarted automatically.

## A build failed

Re-run verbosely and read the tail:

```bash
./scripts/install.sh switch --verbose
```

The full log is at `/tmp/pwnbox-install.log`. If the system is unusable, boot
an older generation from the boot menu.

## GTK apps keep the old colours

GTK reloads its colour scheme awkwardly. The theme script toggles the GNOME
colour scheme to nudge it; if a specific app still lags, restart that app.

## Out of disk space

Garbage collection runs daily and keeps 7 days. To reclaim more:

```bash
sudo nix-collect-garbage -d
```

## Ly / login screen

LY reads the palette statically from `modules/nixos/desktop/ly.nix`, so it does
not follow wallpaper themes at runtime. Change it there if needed.

## Where to look

| Area | Path |
| --- | --- |
| Theme engine | `~/.scripts/pwnbox-theme` |
| Saved state | `~/.cache/pwnbox/theme/` |
| Spotify watcher log | `~/.cache/pwnbox/spotify-watch.log` |
| Quickshell Theme | `~/.config/quickshell/Theme.js` |
| Installer log | `/tmp/pwnbox-install.log` |
