# Browser (Zen)

Zen is the default browser. It is wrapped by the flake and follows the active
theme like every other app.

## What is preinstalled

Only the theming integration is installed by policy:

| Extension | What it does |
| --- | --- |
| **pwnbox styles** | Our own extension: applies all site themes in real time |
| **Pywalfox** | Applies the pywal palette to the browser UI, live on theme change |

No ad blockers, privacy extensions or other add-ons are forced. Install and
manage extensions yourself from `about:addons`.

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

### Included sites

<details>
<summary>131 themed websites</summary>

**Development & docs** — alacritty.org, arch-wiki, bstats, codeberg, crates.io,
crowdin, devdocs, dev.to, docs.deno.com, docs.rs, freedesktop, ghostty.org,
github, gleam.run, go.dev, graphite, hackage, home-manager-options-search,
hoogle, hoppscotch, learn-x-in-y-minutes, mdbook, mdn, neovim.io,
nixos-manual, nixos-search, npm, npmx, pypi, pythonanywhere, react.dev,
regex101, scalar, stack-overflow, web.dev, zen-browser-docs

**AI, search & productivity** — alternativeto, amplenote, anonymous-overflow,
boringproxy, brave-search, chatgpt, claude, deepseek, deepl, ecosia, gmail,
google-drive, google-gemini, google-photos, grabify, have-i-been-pwned,
homepage, indie-wiki-buddy, inoreader, invokeai, keyoxide, lingva, linkedin,
microsoft-word, migadu-webmail, ollama, openmediavault, paste.rs, perplexity,
poe, porkbun, proton, raindrop, rentry.co, searchix, searxng, startpage, stylus,
syncthing, tabnews, tldraw, tuta, vercel, vikunja, whatsapp-web, wikipedia,
wikiwand

**Media, social & streaming** — anilist, bsky, cinny, cobalt, elk, hacker-news,
holodex, hyperpipe, instagram, invidious, lastfm, lemmy, libreddit, listenbrainz,
lobste.rs, mastodon, modrinth, namemc, nitter, phanpy, pinterest,
planet-minecraft, pronouns.cc, pronouns.page, reddit, seventv, shinigami-eyes,
snapchat-web, spotify-web, status.cafe, substack, twitch, twitter, youtube

**Learning, games & fun** — advent-of-code, canvas-lms, chess.com, desmos,
formative, ichi.moe, jisho, keybr.com, lichess, minesweeper, picrew,
pwnbox-scrollbars, quizlet, trinket

</details>

## No hardening

Zen is a normal browser. `dotfiles/zen/user.js` is intentionally limited to
the dark colour scheme used by the site themes; it does not change telemetry,
tracking protection, cache behaviour or extension installs. The one exception
is `xpinstall.signatures.required = false`, which is required to keep the
bundled pwnbox styles extension enabled because it is not signed by AMO.
Installing any other extension still requires explicit user confirmation;
everything else comes from Zen itself. Updates are shipped by rebuilding the
flake because the browser lives in the Nix store.

Upgrades from older pwnbox releases remove the previous hardening prefs from
`prefs.js` and replace the old `user.js` automatically. Previously
force-installed ad blockers and privacy add-ons are no longer managed; they
remain as ordinary user-installed extensions and can be removed in
`about:addons`.

Tor Browser is the hardened browser; see [Privacy](privacy.md).
