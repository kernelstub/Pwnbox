"""
Binary stream scanner — sequential scan + bytes.find() fallback.
Reads and patches raw DBI blocks in decrypted settings stream.
"""

import struct

# Runtime reference — populated by __main__ after load_schema()
from . import schema as _schema
from .tdf import _qt_ba, _qt_str, _read_qt_ba, _read_qt_str

UNKNOWN_BLOCK_SIZES: dict[int, int] = {}

_scan_cache: tuple[int, dict[int, int]] = (-1, {})


def _advance_for(data: bytes, p: int, fmt: str) -> int:
    if fmt in ("i32", "u32"):
        return 4
    if fmt == "u64":
        return 8
    if fmt == "theme_key":
        return 8 + 8 + 4
    if fmt == "two_u64":
        return 8 + 8
    if fmt == "two_i32":
        return 4 + 4
    if fmt in ("str", "ba"):
        if p + 4 > len(data):
            raise IndexError("EOF")
        n = struct.unpack_from(">I", data, p)[0]
        return 4 if n == 0xFFFFFFFF else 4 + n
    raise ValueError(f"Unknown fmt: {fmt}")


def scan_stream(data: bytes) -> dict[int, int]:
    DBI_SCHEMA = _schema.DBI_SCHEMA
    positions: dict[int, int] = {}
    p = 0
    while p + 4 <= len(data):
        block_id = struct.unpack_from(">I", data, p)[0]
        vp = p + 4
        if block_id in DBI_SCHEMA:
            _, fmt = DBI_SCHEMA[block_id]
            positions[block_id] = p
            try:
                advance = _advance_for(data, vp, fmt)
            except (IndexError, struct.error):
                break
            if advance > 20 * 1024 * 1024:
                break
            p = vp + advance
        elif block_id in UNKNOWN_BLOCK_SIZES:
            hint = UNKNOWN_BLOCK_SIZES[block_id]
            if hint >= 0:
                advance = hint
            elif hint in (-1, -2):
                if vp + 4 > len(data):
                    break
                n = struct.unpack_from(">I", data, vp)[0]
                advance = 4 if n == 0xFFFFFFFF else 4 + n
                if advance > 20 * 1024 * 1024:
                    break
            else:
                break
            p = vp + advance
        else:
            break
    return positions


def get_positions(data: bytes) -> dict[int, int]:
    global _scan_cache
    did = id(data)
    if _scan_cache[0] != did:
        _scan_cache = (did, scan_stream(data))
    return _scan_cache[1]


def _invalidate_cache():
    global _scan_cache
    _scan_cache = (-1, {})


def raw_find_block(data: bytes, block_id: int) -> int:
    pos = get_positions(data).get(block_id, -1)
    if pos != -1:
        return pos

    DBI_SCHEMA = _schema.DBI_SCHEMA
    if block_id not in DBI_SCHEMA:
        return -1

    _, fmt = DBI_SCHEMA[block_id]
    if fmt not in ("i32", "u32", "u64", "theme_key", "two_u64", "two_i32"):
        return -1

    needle = struct.pack(">I", block_id)
    last = -1
    p = 0
    while True:
        idx = data.find(needle, p)
        if idx == -1:
            break
        last = idx
        p = idx + 1
    return last


def raw_read(data: bytes, block_id: int):
    DBI_SCHEMA = _schema.DBI_SCHEMA
    pos = raw_find_block(data, block_id)
    if pos == -1 or block_id not in DBI_SCHEMA:
        return None
    _, fmt = DBI_SCHEMA[block_id]
    p = pos + 4
    try:
        if fmt == "i32":
            return struct.unpack_from(">i", data, p)[0]
        if fmt == "u32":
            return struct.unpack_from(">I", data, p)[0]
        if fmt == "u64":
            return struct.unpack_from(">Q", data, p)[0]
        if fmt == "str":
            val, _ = _read_qt_str(data, p)
            return val
        if fmt == "ba":
            val, _ = _read_qt_ba(data, p)
            return val
        if fmt == "theme_key":
            return {
                "day": struct.unpack_from(">Q", data, p)[0],
                "night": struct.unpack_from(">Q", data, p + 8)[0],
                "night_mode": bool(struct.unpack_from(">I", data, p + 16)[0]),
            }
        if fmt == "two_u64":
            return {
                "day": struct.unpack_from(">Q", data, p)[0],
                "night": struct.unpack_from(">Q", data, p + 8)[0],
            }
        if fmt == "two_i32":
            return {
                "day": struct.unpack_from(">i", data, p)[0],
                "night": struct.unpack_from(">i", data, p + 4)[0],
            }
    except (struct.error, UnicodeDecodeError, IndexError):
        return None
    return None


def _encode_value(fmt: str, value) -> bytes:
    if fmt == "i32":
        return struct.pack(">i", value)
    if fmt == "u32":
        return struct.pack(">I", value)
    if fmt == "u64":
        return struct.pack(">Q", value)
    if fmt == "str":
        return _qt_str(value)
    if fmt == "ba":
        return _qt_ba(value)
    if fmt == "theme_key":
        return (
            struct.pack(">Q", value["day"])
            + struct.pack(">Q", value["night"])
            + struct.pack(">I", 1 if value["night_mode"] else 0)
        )
    if fmt == "two_u64":
        return struct.pack(">Q", value["day"]) + struct.pack(">Q", value["night"])
    if fmt == "two_i32":
        return struct.pack(">i", value["day"]) + struct.pack(">i", value["night"])
    raise ValueError(f"Unsupported fmt: {fmt}")


def raw_patch(data: bytes, block_id: int, value) -> tuple[bytes, bool]:
    DBI_SCHEMA = _schema.DBI_SCHEMA
    if block_id not in DBI_SCHEMA:
        raise ValueError(f"block_id 0x{block_id:02X} is not in schema")
    _, fmt = DBI_SCHEMA[block_id]
    encoded = _encode_value(fmt, value)
    needle = struct.pack(">I", block_id)
    pos = raw_find_block(data, block_id)

    if pos == -1:
        _invalidate_cache()
        return data + needle + encoded, False

    p = pos + 4
    try:
        old_len = _advance_for(data, p, fmt)
    except (IndexError, struct.error):
        old_len = len(encoded)

    buf = bytearray(data)
    buf[p : p + old_len] = encoded
    _invalidate_cache()
    return bytes(buf), True
