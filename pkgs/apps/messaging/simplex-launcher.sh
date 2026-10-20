#!/usr/bin/env bash
# pwnbox SimpleX Chat launcher.
#
# SimpleX ships as a Compose-multiplatform AppImage whose UI hardcodes the
# bundled Inter fonts (fonts/Inter-*.ttf inside common-desktop-*.jar). To make
# the app follow the pwnbox application font we keep a writable copy of the
# extracted AppImage under ~/.local/share/pwnbox/simplex, swap the bundled
# Inter files for the current application font, and run that copy inside the
# upstream FHS wrapper via APPIMAGE_DEBUG_EXEC.
set -euo pipefail

app_src='@appDir@'
fhs='@fhsBin@'
python='@python3@'
fc_match='@fcMatch@'

base="${XDG_DATA_HOME:-$HOME/.local/share}/pwnbox/simplex"
app="$base/app"
stamp="$base/.store-path"
font_state="${XDG_CACHE_HOME:-$HOME/.cache}/pwnbox/theme/font-app"
font_stamp="$base/.font"

# Refresh the writable app copy when the package (store path) changes.
sync_app() {
    if [ -x "$app/AppRun" ] && [ -f "$stamp" ] && [ "$(cat "$stamp" 2>/dev/null || true)" = "$app_src" ]; then
        return 0
    fi
    mkdir -p "$base"
    rm -rf "$app.tmp" "$app" "$font_stamp"
    cp -a "$app_src" "$app.tmp"
    chmod -R u+w "$app.tmp"
    mv "$app.tmp" "$app"
    printf '%s' "$app_src" >"$stamp"
}

# Replace the bundled Inter fonts with the pwnbox application font.
patch_fonts() {
    local family
    family="$(cat "$font_state" 2>/dev/null || true)"
    [ -n "$family" ] || family='Iosevka Nerd Font Mono'
    [ -f "$font_stamp" ] && [ "$(cat "$font_stamp" 2>/dev/null || true)" = "$family" ] && return 0

    local jar
    jar="$(find "$app/usr/lib/app" -maxdepth 1 -name 'common-desktop-*.jar' -print -quit 2>/dev/null)"
    [ -n "$jar" ] || return 0

    local tmp target pattern src
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/fonts"
    for pair in \
        'Inter-Light.ttf|weight=300' \
        'Inter-Regular.ttf|weight=400' \
        'Inter-Medium.ttf|weight=500' \
        'Inter-Semibold.ttf|weight=600' \
        'Inter-Bold.ttf|weight=700' \
        'Inter-Italic.ttf|weight=400:slant=italic'; do
        target="${pair%%|*}"
        pattern="${pair#*|}"
        src="$("$fc_match" -f '%{file}\n' "$family:$pattern" 2>/dev/null | head -1)"
        [ -n "$src" ] && [ -f "$src" ] || continue
        cp -f "$src" "$tmp/fonts/$target"
    done

    if [ -n "$(ls -A "$tmp/fonts" 2>/dev/null || true)" ]; then
        "$python" - "$jar" "$tmp/fonts" <<'PYEOF'
import os
import shutil
import sys
import zipfile

jar, fontsdir = sys.argv[1], sys.argv[2]
out = jar + ".pwnbox-new"
with zipfile.ZipFile(jar, "r") as zin, zipfile.ZipFile(out, "w") as zout:
    for item in zin.infolist():
        if item.filename.startswith("fonts/Inter-"):
            continue
        with zin.open(item) as src, zout.open(item, "w") as dst:
            shutil.copyfileobj(src, dst)
    for name in sorted(os.listdir(fontsdir)):
        with open(os.path.join(fontsdir, name), "rb") as f:
            zout.writestr(zipfile.ZipInfo("fonts/" + name), f.read(), compress_type=zipfile.ZIP_DEFLATED)
os.replace(out, jar)
PYEOF
        printf '%s' "$family" >"$font_stamp"
    fi
    rm -rf "$tmp"
}

sync_app
patch_fonts

export APPIMAGE_DEBUG_EXEC="$app/AppRun"
exec "$fhs" "$@"
