# Browser (Zen)

Zen is the default browser. It is wrapped by the flake and follows the active
theme like every other app.

## What is preinstalled

Seven extensions are force-installed by policy on first launch (no clicks):

| Extension | What it does |
| --- | --- |
| **pwnbox styles** | Our own extension: applies all site themes in real time |
| **Pywalfox** | Applies the pywal palette to the browser UI, live on theme change |
| **uBlock Origin** | Ad and tracker blocking |
| **Wappalyzer** | Web technology detection |
| **TWP - Translate Web Pages** | Web page translation |
| **Mullvad Browser Extension** | Mullvad VPN companion |
| **ClearURLs** | Removes tracking parameters from URLs |

The native messaging host for Pywalfox and the `toolkit.legacyUserProfileCustomizations.stylesheets`
preference are installed automatically, so `userChrome.css` / `userContent.css`
work out of the box.

Preinstalled extensions stay unpinned from the toolbar: on login
(`pwnbox-theme restore`) their buttons are moved out of the toolbar into the
unified extensions menu, so they are installed and enabled but not pinned.

## Bookmarks

No bookmarks are shipped. The profile starts empty and stays entirely yours.

## Browser chrome

`~/.scripts/pwnbox-theme` generates two files inside the Zen profile's `chrome/`
folder on every theme change:

| File | Themes |
| --- | --- |
| `userChrome.css` | The browser UI (toolbar, sidebar, tabs, urlbar, menus, DevTools) — flat, no shadows, subtle borders, application font |
| `userContent.css` | about: pages (newtab, settings, addons, protections) |

Both are recoloured from the active palette; the browser chrome follows the
theme **live** (Pywalfox refetches on every change), the about: pages on the
next browser start.

## Site themes

131 website themes ship with the flake (`dotfiles/zen/userstyles/`), adapted
from the [catppuccin/userstyles](https://github.com/catppuccin/userstyles)
collection (MIT, credited) but recoloured with **your** palette — nothing
Catppuccin remains. Borders are a subtle lift of the background colour, and the
application font is used everywhere.

They are applied by the **pwnbox styles** extension (sideloaded into Zen by
the flake): it fetches the generated styles from the local server, checks for
a new version every three seconds and injects the matching site style on every
page. Change the theme and open sites restyle themselves **live** — no
restart needed.

The server runs automatically at login as the `pwnbox-styles` user systemd
service (bound to `127.0.0.1`, nothing is exposed to the network). If it is not
up yet, `pwnbox-theme styles` starts it; that command also opens the style index
at **http://localhost:8311/** for browsing the available site themes.

Click the extension's toolbar icon to open a popup with the master switches
(enable all themes, flat borders) and a link to the full options page:

- **Enable all site themes** — master on/off switch
- **Flat borders** — toggle the subtle background-tinted borders
- **Per-site toggles** — enable/disable each of the 131 site themes
- **Check for updates now** + status line (version, last check, errors)

Changes apply to every open page instantly.

## Hardening

Zen is hardened by `dotfiles/zen/user.js`, applied to the profile on every
rebuild and at startup:

- All telemetry, studies, crash reports and search suggestions disabled
- Strict tracking protection, first-party isolation, query stripping, no
  speculative connections, no prefetch, trimmed referrers
- Cache/history/formdata cleared on shutdown; **cookies are kept** so you stay
  logged in
- Dark colour scheme forced on all sites, so dark-gated styles apply everywhere

The file is managed; changes to these settings belong in
`dotfiles/zen/user.js`, not in the browser UI.
