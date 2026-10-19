"""
Formatting & diagnostic output — fmt_value, dump_all, dump_app_settings,
dump_tail_info, probe_block, deep_scan_diagnostic.
"""

import struct

from . import schema as _schema
from .scanner import _advance_for, get_positions, raw_find_block, raw_read
from .tdf import _read_qt_ba, _read_qt_str

RESET = "\033[0m"
BOLD = "\033[1m"
CYAN = "\033[36m"
GREEN = "\033[32m"
DIM = "\033[2m"


def fmt_value(name: str, fmt: str, value) -> str:
    if value is None:
        return "None"
    if fmt == "ba":
        return f"<bytes [{value[:16].hex()}…]>"
    if fmt == "i32":
        s = str(value)
        if name == "ScalePercent":
            s += " (auto)" if value == 0 else f" ({value}%)"
        elif name == "NotifyView":
            s += (
                [" (with text)", " (name only)", " (nothing)"][value]
                if 0 <= value <= 2
                else ""
            )
        elif name == "WorkMode":
            s += (
                [" (window)", " (tray)", " (window+tray)"][value]
                if 0 <= value <= 2
                else ""
            )
        elif name == "PowerSaving":
            flags = [v for k, v in _schema.POWER_SAVING_FLAGS.items() if value & k]
            s += f" ({', '.join(flags)})" if flags else f" (0x{value:04X})"
        elif name in (
            "AutoStart",
            "StartMinimized",
            "SoundNotify",
            "DesktopNotify",
            "AutoUpdate",
            "SeenTrayTooltip",
            "SendToMenu",
            "CompressPastedImage",
            "AskDownloadPath",
            "AutoPlayGif",
            "AnimationsDisabled",
            "RefreshSystemColorScheme",
        ):
            s += " (on)" if value else " (off)"
        elif name == "LastUpdateCheck" and value > 0:
            import datetime

            s += f" ({datetime.datetime.fromtimestamp(value).strftime('%Y-%m-%d %H:%M')})"
        return s
    if fmt in ("u64", "u32"):
        return f"{value} (0x{value:016X})"
    if fmt == "theme_key":
        return (
            f"day=0x{value['day']:016X} "
            f"night=0x{value['night']:016X} "
            f"night_mode={'yes' if value['night_mode'] else 'no'}"
        )
    if fmt == "two_u64":
        return f"day=0x{value['day']:016X} night=0x{value['night']:016X}"
    if fmt == "two_i32":
        return f"day={value['day']} night={value['night']}"
    return repr(value)


def dump_all(data: bytes, verbose: bool = False):
    DBI_SCHEMA = _schema.DBI_SCHEMA
    print(f"\n{BOLD}{'─' * 72}{RESET}")
    print(f"{BOLD} Telegram Desktop — settings{RESET}")
    print(f"{BOLD}{'─' * 72}{RESET}\n")
    print(f" {'ID':>6} {'Name':<35} Value")
    print(f" {'─' * 6} {'─' * 35} {'─' * 30}")

    found_any = False
    for block_id, (name, fmt) in sorted(DBI_SCHEMA.items()):
        if raw_find_block(data, block_id) == -1:
            continue
        value = raw_read(data, block_id)
        val_str = fmt_value(name, fmt, value)
        print(
            f" {CYAN}0x{block_id:04X}{RESET} {BOLD}{name:<35}{RESET} {GREEN}{val_str}{RESET}"
        )
        if verbose:
            desc = _schema.DBI_DESCRIPTION.get(name, "")
            if desc:
                print(f"         {DIM}{desc}{RESET}")
        found_any = True

    if not found_any:
        print(" (no known blocks found)")
    print()


def dump_app_settings(blob: bytes, verbose: bool = False):
    if not blob:
        print("[*] ApplicationSettings blob is empty")
        return
    APP_SCHEMA = _schema.APP_SCHEMA
    print(f"\n{BOLD}{'─' * 72}{RESET}")
    print(f"{BOLD} ApplicationSettings (Core::Settings blob){RESET}")
    print(f"{BOLD}{'─' * 72}{RESET}\n")
    print(f" {'ID':>6} {'Name':<35} Value")
    print(f" {'─' * 6} {'─' * 35} {'─' * 30}")

    p = 0
    parsed = 0
    while p + 4 <= len(blob):
        block_id = struct.unpack_from(">I", blob, p)[0]
        p += 4
        if block_id not in APP_SCHEMA:
            print(f"\n (stopped at unknown block 0x{block_id:04X} at offset {p - 4})")
            break
        name, fmt = APP_SCHEMA[block_id]
        try:
            if fmt == "i32":
                value = struct.unpack_from(">i", blob, p)[0]
                p += 4
            elif fmt == "str":
                value, p = _read_qt_str(blob, p)
            elif fmt == "ba":
                value, p = _read_qt_ba(blob, p)
            else:
                break
        except (struct.error, UnicodeDecodeError):
            break
        print(
            f" {CYAN}0x{block_id:04X}{RESET} {BOLD}{name:<35}{RESET} {GREEN}{fmt_value(name, fmt, value)}{RESET}"
        )
        parsed += 1
    print(f"\n Parsed: {parsed} blocks ({len(blob)} bytes in blob)\n")


def probe_block(data: bytes, offset: int):
    DBI_SCHEMA = _schema.DBI_SCHEMA
    block_id = struct.unpack_from(">I", data, offset)[0]
    print(f"[probe] Unknown block 0x{block_id:04X} at offset {offset}")
    print(f"        Bytes: {data[offset : offset + 40].hex()}")
    print("        Trying candidate value sizes:\n")

    candidates = [
        ("i32 (4B)", 4),
        ("i64 (8B)", 8),
        ("12B", 12),
        ("16B", 16),
        ("20B", 20),
        ("24B", 24),
        ("28B", 28),
        ("32B", 32),
        ("36B", 36),
        ("40B", 40),
    ]
    vp = offset + 4
    if vp + 4 <= len(data):
        n = struct.unpack_from(">I", data, vp)[0]
        if n == 0xFFFFFFFF:
            candidates.append(("QByteArray(null)", 4))
        elif n <= 10 * 1024 * 1024:
            candidates.append((f"QByteArray(n={n})", 4 + n))

    for desc, adv in candidates:
        nxt = offset + 4 + adv
        if nxt + 4 > len(data):
            continue
        nxt_id = struct.unpack_from(">I", data, nxt)[0]
        known = DBI_SCHEMA.get(nxt_id)
        if known:
            mark = f"✅ {known[0]}"
        elif nxt_id == 0:
            mark = "🔚 zeros"
        else:
            mark = f"❌ unknown 0x{nxt_id:08X}"
        print(f"  {desc:<22} → next: 0x{nxt_id:08X} {mark}")

    print()
    print(f"  → Add correct size to UNKNOWN_BLOCK_SIZES[0x{block_id:02X}] and rerun.")


def dump_tail_info(data: bytes):
    DBI_SCHEMA = _schema.DBI_SCHEMA
    positions = get_positions(data)
    parsed_end = 0
    if positions:
        last_id = max(positions, key=lambda k: positions[k])
        last_pos = positions[last_id]
        _, fmt = DBI_SCHEMA[last_id]
        vp = last_pos + 4
        try:
            parsed_end = vp + _advance_for(data, vp, fmt)
        except Exception:
            parsed_end = last_pos

    tail = data[parsed_end:]
    print(f"\n[*] Sequential scan stopped at offset {parsed_end}")
    print(f"[*] Tail: {len(tail)} bytes")
    if len(tail) >= 4:
        first_id = struct.unpack_from(">I", tail, 0)[0]
        known = DBI_SCHEMA.get(first_id)
        status = f"KNOWN: {known[0]}" if known else "UNKNOWN"
        print(f"[*] First block_id in tail: 0x{first_id:04X} ({status})")
        print(f"[*] HEX: {tail[:48].hex()}")
        if not known:
            print()
            probe_block(data, parsed_end)
    print("\n All found blocks (sequential + fallback):")
    found = []
    for block_id, (name, fmt) in sorted(DBI_SCHEMA.items()):
        pos = raw_find_block(data, block_id)
        if pos == -1:
            continue
        in_tail = pos >= parsed_end
        value = raw_read(data, block_id)
        val_str = fmt_value(name, fmt, value)
        via = "📌 tail/fallback" if in_tail else " sequential   "
        found.append((pos, block_id, name, fmt, val_str, via))
    found.sort()
    for pos, block_id, name, fmt, val_str, via in found:
        print(f"  {via} @{pos:<5} 0x{block_id:04X} {name:<30} {val_str}")
    print()


def deep_scan_diagnostic(data: bytes):
    DBI_SCHEMA = _schema.DBI_SCHEMA
    positions_seq = get_positions(data)
    print(f"\n{'─' * 72}")
    print(f" Deep scan — all occurrences of known block_id in {len(data)} bytes")
    print(f"{'─' * 72}\n")
    print(f" {'Offset':>8} {'ID':>6} {'Name':<30} Value")
    print(f" {'─' * 8} {'─' * 6} {'─' * 30} {'─' * 30}")

    found_offsets: list[tuple[int, int]] = []
    for block_id in DBI_SCHEMA:
        needle = struct.pack(">I", block_id)
        p = 0
        while True:
            idx = data.find(needle, p)
            if idx == -1:
                break
            found_offsets.append((idx, block_id))
            p = idx + 1
    found_offsets.sort()

    for offset, block_id in found_offsets:
        name, fmt = DBI_SCHEMA[block_id]
        tag = " seq" if block_id in positions_seq else "find"
        p = offset + 4
        val_str = "?"
        try:
            if fmt == "i32":
                val_str = fmt_value(name, fmt, struct.unpack_from(">i", data, p)[0])
            elif fmt == "u32":
                val_str = fmt_value(name, fmt, struct.unpack_from(">I", data, p)[0])
            elif fmt == "u64":
                val_str = fmt_value(name, fmt, struct.unpack_from(">Q", data, p)[0])
            elif fmt == "theme_key":
                kd = struct.unpack_from(">Q", data, p)[0]
                kn = struct.unpack_from(">Q", data, p + 8)[0]
                nm = struct.unpack_from(">I", data, p + 16)[0]
                val_str = f"day=0x{kd:016X} night=0x{kn:016X} nm={nm}"
            elif fmt == "two_u64":
                kd = struct.unpack_from(">Q", data, p)[0]
                kn = struct.unpack_from(">Q", data, p + 8)[0]
                val_str = f"day=0x{kd:016X} night=0x{kn:016X}"
            elif fmt == "two_i32":
                v1 = struct.unpack_from(">i", data, p)[0]
                v2 = struct.unpack_from(">i", data, p + 4)[0]
                val_str = f"day={v1} night={v2}"
            elif fmt in ("str", "ba"):
                n = struct.unpack_from(">I", data, p)[0]
                val_str = (
                    "null"
                    if n == 0xFFFFFFFF
                    else f"<{fmt} {n}B>"
                    if n <= 10 * 1024 * 1024
                    else f"<false positive n=0x{n:08X}>"
                )
        except (struct.error, IndexError):
            val_str = "<read error>"

        print(
            f" {offset:>8} {CYAN}0x{block_id:04X}{RESET} {BOLD}{name:<30}{RESET} {val_str} {DIM}[{tag}]{RESET}"
        )
    print()
