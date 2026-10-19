"""
Theme management — apply .tdesktop-theme files.
Based on the proven method from tdesktop-theme-apply-v6.py
"""

import re
import secrets
import shutil
import struct
import subprocess
from pathlib import Path

from .crypto import decrypt_local, derive_key, encrypt_local
from .tdf import _qt_ba, _qt_str, _read_qt_ba, _read_qt_str, read_tdf, write_tdf


def _to_file_part(key: int) -> str:
    """Convert 64-bit key to hex filename (16 chars, reversed nibbles)."""
    result = []
    for _ in range(16):
        v = key & 0x0F
        result.append(chr(ord("0") + v) if v < 10 else chr(ord("A") + v - 10))
        key >>= 4
    return "".join(result)


def _generate_key(tdata: Path) -> int:
    """Generate a new unique theme file key."""
    while True:
        key = secrets.randbits(64)
        if not key:
            continue
        if not any(
            Path(str(tdata / _to_file_part(key)) + s).exists() for s in ["s", "0", "1"]
        ):
            return key


def _read_theme_file_raw(tdata: Path, key: int, auth_key: bytes) -> bytes | None:
    """Read existing theme file and return raw inner bytes."""
    fname = Path(str(tdata / _to_file_part(key)) + "s")
    if not fname.exists():
        return None
    raw = fname.read_bytes()
    if raw[:4] != b"TDF$":
        return None
    payload = raw[8:-16]
    enc, _ = _read_qt_ba(payload, 0)
    try:
        return decrypt_local(enc, auth_key)
    except Exception:
        return None


_WINDOW_BG_RE = re.compile(
    rb"^[ \t]*windowBg[ \t]*:[ \t]*#([0-9a-fA-F]{6})", re.MULTILINE
)


def _window_bg_rgb(colors: bytes) -> tuple[int, int, int]:
    """Pull the literal global background colour out of a colours file."""
    match = _WINDOW_BG_RE.search(colors)
    if not match:
        return (0, 0, 0)
    value = match.group(1).decode("ascii")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


# Telegram's Data::WallPaper constants (data_wall_paper.cpp).
_WALLPAPER_TAG = -112  # kWallPaperSerializeTagId
_WALLPAPER_VERSION_TAG = 0x7FFFFFFF
_WALLPAPER_VERSION = 1
_WALLPAPER_CUSTOM_ID = 0xFFFFFFFFFFFFFFFF  # CustomWallPaper (legacy id -1)
_BACKGROUND_KEY_ID = 0x61  # dbiBackgroundKey


def _serialize_wallpaper(rgb: tuple[int, int, int]) -> bytes:
    """Serialize a solid-colour custom WallPaper (no pattern, no image)."""
    r, g, b = rgb
    color = (r << 16) | (g << 8) | b
    return (
        struct.pack(">QQ", _WALLPAPER_CUSTOM_ID, 0)  # id, accessHash
        + struct.pack(">ii", _WALLPAPER_VERSION_TAG, _WALLPAPER_VERSION)
        + struct.pack(">i", 0)  # flags (no pattern)
        + _qt_str("")  # slug
        + struct.pack(">i", 0)  # blurred
        + struct.pack(">i", 1)  # background colours count
        + struct.pack(">I", color)  # solid 0xRRGGBB
        + struct.pack(">ii", 0, 0)  # pattern intensity, gradient rotation
        + struct.pack(">Q", 0)  # ownerId
    )


def _write_background_file(
    tdata: Path, key: int, rgb: tuple[int, int, int], auth_key: bytes, version: int
):
    """Write a solid-colour chat background under `key`."""
    descriptor = struct.pack(">i", _WALLPAPER_TAG)
    descriptor += _qt_ba(_serialize_wallpaper(rgb))
    descriptor += _qt_ba(None)  # no background image data
    encrypted = _qt_ba(encrypt_local(descriptor, auth_key))
    write_tdf(tdata / _to_file_part(key), encrypted, version)


def _apply_solid_background(
    tdata: Path,
    settings: bytearray,
    auth_key: bytes,
    version: int,
    rgb: tuple[int, int, int],
) -> bool:
    """Point Telegram's day/night chat background at a solid colour.

    Telegram falls back to its built-in green doodle wallpaper whenever the
    active theme carries no background image (window_theme.cpp:
    ``ChatBackground::set`` → ``IsThemeWallPaper(paper) && _themeImage.isNull()``
    → ``setPaper(Data::DefaultWallPaper())``).  Writing a solid-colour custom
    wallpaper keeps the chat flat and exactly the theme's `windowBg`.

    Returns True when `settings` was modified (new key assigned).
    """
    off = settings.find(struct.pack(">I", _BACKGROUND_KEY_ID))
    kd = kn = 0
    if off != -1:
        kd, kn = struct.unpack_from(">QQ", settings, off + 4)

    changed = False
    if kd == 0 and kn == 0:
        kd = kn = _generate_key(tdata)
        changed = True
    elif kd == 0:
        kd = kn
        changed = True
    elif kn == 0:
        kn = kd
        changed = True

    _write_background_file(tdata, kd, rgb, auth_key, version)
    if kn != kd:
        _write_background_file(tdata, kn, rgb, auth_key, version)
    print(f"[✓] Solid chat background: #{rgb[0]:02x}{rgb[1]:02x}{rgb[2]:02x}")

    if not changed:
        return False
    if off != -1:
        struct.pack_into(">QQ", settings, off + 4, kd, kn)
    else:
        settings += struct.pack(">I", _BACKGROUND_KEY_ID)
        settings += struct.pack(">QQ", kd, kn)
    return True


def _write_theme_file(
    tdata: Path,
    key: int,
    content: bytes,
    path_abs: str,
    path_rel: str,
    auth_key: bytes,
    version: int,
):
    """Write a colours-only theme file (no background image).

    pwnbox intentionally does NOT carry over the previous theme's background
    image, so the empty/zeros suffix is always written.  The chat background is
    provided separately as a solid colour (see `_write_background_file`).
    """
    suffix_bytes = struct.pack(">QQ", 0, 0)  # bg ids
    suffix_bytes += _qt_str("")  # bg slug 1
    suffix_bytes += _qt_str("")  # bg slug 2
    suffix_bytes += struct.pack(">Q", 0)
    suffix_bytes += struct.pack(">i", 0)
    suffix_bytes += struct.pack(">ii", 0, 0)
    suffix_bytes += _qt_ba(None)
    suffix_bytes += _qt_ba(None)
    suffix_bytes += struct.pack(">I", 0)

    inner = _qt_ba(content)
    inner += _qt_str("special://new_tag")
    inner += _qt_str(path_abs)
    inner += _qt_str(path_rel)
    inner += suffix_bytes  # ← preserve original fields

    encrypted = _qt_ba(encrypt_local(inner, auth_key))
    write_tdf(tdata / _to_file_part(key), encrypted, version)
    print(
        f"[✓] Theme file written: {_to_file_part(key)}s ({len(inner)}B inner)"
    )


def apply_theme(theme_path: Path, tdata: Path, night: bool = False) -> bool:
    """Apply a .tdesktop-theme file by overwriting the existing theme file.

    This is the ONLY method that reliably works without user interaction.
    It reads the current theme key from settings and overwrites that file.

    Args:
        theme_path: Path to .tdesktop-theme file
        tdata: Path to Telegram Desktop tdata directory
        night: If True, apply as night theme; otherwise day theme

    Returns:
        True if successful
    """
    if not theme_path.exists():
        print(f"[!] Theme file not found: {theme_path}")
        return False

    if theme_path.suffix != ".tdesktop-theme":
        print(f"[!] Theme file must have .tdesktop-theme extension: {theme_path}")
        return False

    if not tdata.exists():
        print(f"[!] tdata not found: {tdata}")
        return False

    # Check if Telegram Desktop is running
    if subprocess.run(
        ["pgrep", "-xi", "telegram-desktop"], capture_output=True
    ).returncode == 0:
        print("[!] Close Telegram Desktop before applying theme")
        return False

    # ── Read settings ─────────────────────────────────────────────────────
    try:
        payload, version = read_tdf(tdata / "settings")
        salt, pos = _read_qt_ba(payload, 0)
        enc_raw, _ = _read_qt_ba(payload, pos)
        auth_key = derive_key(salt)

        print(f"[*] TDF version: {version}")
        print(f"[*] Salt: {salt[:8].hex()}...")

        data = decrypt_local(enc_raw, auth_key)
        print(f"[✓] Decrypted settings: {len(data)} bytes")
    except Exception as e:
        print(f"[!] Failed to read settings: {e}")
        return False

    # ── Read current dbiThemeKey ──────────────────────────────────────────
    dbi_theme_key = 0x54
    off = data.find(struct.pack(">I", dbi_theme_key))
    kd = kn = 0
    nm = False
    if off != -1:
        kd, kn = struct.unpack_from(">QQ", data, off + 4)
        nm = bool(struct.unpack_from(">I", data, off + 20)[0])
        print(f"[*] day=0x{kd:016X}  night=0x{kn:016X}  night_mode={nm}")
    else:
        print("[!] dbiThemeKey not found in settings — theme was never applied")

    # ── Determine target key ──────────────────────────────────────────────
    # v6: DO NOT create new key — overwrite existing file
    # Telegram manages keys in settings; we only need to update the file
    settings_buf = bytearray(data)
    settings_changed = False

    target_key = kn if nm else kd

    if target_key == 0:
        # No key yet — create new one and write to settings
        target_key = _generate_key(tdata)
        print(f"[*] Key not found, creating new: 0x{target_key:016X}")
        new_kd = target_key if not nm else kd
        new_kn = target_key if nm else kn
        if off != -1:
            struct.pack_into(">Q", settings_buf, off + 4, new_kd)
            struct.pack_into(">Q", settings_buf, off + 12, new_kn)
        else:
            settings_buf += struct.pack(">I", dbi_theme_key)
            settings_buf += struct.pack(">QQ", new_kd, new_kn)
            settings_buf += struct.pack(">I", 1 if nm else 0)
        settings_changed = True
    else:
        print(
            f"[*] Overwriting existing key: 0x{target_key:016X} → {_to_file_part(target_key)}s"
        )

    # ── Write theme file ──────────────────────────────────────────────────
    content = theme_path.read_bytes()
    path_abs = str(theme_path.resolve())
    path_rel = str(theme_path)

    _write_theme_file(tdata, target_key, content, path_abs, path_rel, auth_key, version)

    # ── Flat chat background ──────────────────────────────────────────────
    # Store the chat background as a solid colour wallpaper equal to the
    # theme's `windowBg`, so Telegram does not fall back to its default green
    # doodle pattern.
    rgb = _window_bg_rgb(content)
    if _apply_solid_background(tdata, settings_buf, auth_key, version, rgb):
        settings_changed = True

    if settings_changed:
        # Backup settings
        for s in ["s", "0", "1"]:
            p = tdata / f"settings{s}"
            if p.exists():
                shutil.copy2(p, tdata / f"settings.bak.{s}")
        enc2 = encrypt_local(bytes(settings_buf), auth_key)
        write_tdf(tdata / "settings", _qt_ba(salt) + _qt_ba(enc2), version)
        print("[✓] settings updated")

    print(f"\n[✓] Done! Launch Telegram Desktop.")
    print(f"    Theme: {theme_path.name}")
    print(f"    Key: 0x{target_key:016X} ({'night' if nm else 'day'})")

    return True
