"""
High-level load / save for tdata/settings.
"""

import shutil
from pathlib import Path

from .crypto import decrypt_local, derive_key, encrypt_local
from .tdf import _qt_ba, _read_qt_ba, read_tdf, write_tdf


def load(tdata: Path) -> tuple[bytes, bytes, bytes, int]:
    """Returns (raw_data, salt, auth_key, tdf_version)."""
    payload, version = read_tdf(tdata / "settings")
    salt, pos = _read_qt_ba(payload, 0)
    enc, _ = _read_qt_ba(payload, pos)
    auth_key = derive_key(salt)
    raw_data = decrypt_local(enc, auth_key)
    return raw_data, salt, auth_key, version


def save(tdata: Path, raw_data: bytes, salt: bytes, auth_key: bytes, version: int):
    """Backs up existing settings files then writes new ones."""
    for s in ["s", "0", "1"]:
        p = tdata / f"settings{s}"
        if p.exists():
            shutil.copy2(p, tdata / f"settings.bak.{s}")
    enc = encrypt_local(raw_data, auth_key)
    payload = _qt_ba(salt) + _qt_ba(enc)
    write_tdf(tdata / "settings", payload, version)
    print(f"[✓] settings saved ({len(raw_data)} bytes)")
