"""
TDF (Telegram Data Format) — read/write TDF$ files and Qt serialization helpers.
"""

import hashlib
import struct
from pathlib import Path
from typing import Optional

TDF_MAGIC = b"TDF$"


# ── Qt serialization ────────────────────────────────────────────────────


def _read_qt_ba(d: bytes, p: int) -> tuple[Optional[bytes], int]:
    n = struct.unpack_from(">I", d, p)[0]
    p += 4
    if n == 0xFFFFFFFF:
        return None, p
    return bytes(d[p : p + n]), p + n


def _read_qt_str(d: bytes, p: int) -> tuple[Optional[str], int]:
    n = struct.unpack_from(">I", d, p)[0]
    p += 4
    if n == 0xFFFFFFFF:
        return None, p
    return d[p : p + n].decode("utf-16-be", errors="replace"), p + n


def _qt_ba(b: Optional[bytes]) -> bytes:
    if b is None:
        return struct.pack(">I", 0xFFFFFFFF)
    return struct.pack(">I", len(b)) + b


def _qt_str(s: Optional[str]) -> bytes:
    if s is None:
        return struct.pack(">I", 0xFFFFFFFF)
    enc = s.encode("utf-16-be")
    return struct.pack(">I", len(enc)) + enc


# ── TDF file I/O ─────────────────────────────────────────────────────────


def read_tdf(base: Path) -> tuple[bytes, int]:
    for s in ["s", "0", "1"]:
        f = Path(str(base) + s)
        if not f.exists():
            continue
        raw = f.read_bytes()
        if raw[:4] != TDF_MAGIC:
            continue
        return raw[8:-16], struct.unpack_from("<i", raw, 4)[0]
    raise FileNotFoundError(f"No valid TDF file found at {base}")


def write_tdf(base: Path, payload: bytes, version: int):
    header = TDF_MAGIC + struct.pack("<i", version)
    # MD5 order must match Telegram Desktop: payload + len + version + magic
    md5_input = payload + struct.pack("<i", len(payload)) + struct.pack("<i", version) + TDF_MAGIC
    md5 = hashlib.md5(md5_input).digest()
    data = header + payload + md5
    Path(str(base) + "s").write_bytes(data)
