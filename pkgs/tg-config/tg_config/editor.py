"""
High-level settings editor — apply_set, import/export JSON.
"""

import base64
import json
from pathlib import Path

from . import schema as _schema
from .formatter import fmt_value
from .scanner import raw_patch, raw_read


def apply_set(data: bytes, key: str, val: str) -> bytes:
    DBI_SCHEMA = _schema.DBI_SCHEMA
    NAME_TO_ID = {v[0]: k for k, v in DBI_SCHEMA.items()}

    # PowerSaving += / -= flags
    if "+=" in key or "-=" in key:
        op = "+=" if "+=" in key else "-="
        fname = key.split(op, 1)[1]
        flag_map = {v: k for k, v in _schema.POWER_SAVING_FLAGS.items()}
        if fname not in flag_map:
            print(f"[!] Unknown flag: {fname}")
            print(f"    Available: {', '.join(flag_map)}")
            return data
        bit = flag_map[fname]
        cur = raw_read(data, NAME_TO_ID["PowerSaving"]) or 0
        new_val = (cur | bit) if op == "+=" else (cur & ~bit)
        new_data, found = raw_patch(data, NAME_TO_ID["PowerSaving"], new_val)
        print(f"[✓] PowerSaving = {new_val} ({'patched' if found else 'appended'})")
        return new_data

    sub_field = None
    if key in _schema.ALIASES:
        key, sub_field = _schema.ALIASES[key]

    if key not in NAME_TO_ID:
        print(f"[!] Unknown setting: {key}")
        print(f"    Available: {', '.join(sorted(NAME_TO_ID))}")
        return data

    block_id = NAME_TO_ID[key]
    _, fmt = DBI_SCHEMA[block_id]

    if sub_field is not None:
        cur = raw_read(data, block_id)
        if cur is None:
            print(f"[!] Block {key} not found in settings")
            return data
        new_v = dict(cur)
        new_v[sub_field] = (
            bool(int(val, 0)) if sub_field == "night_mode" else int(val, 0)
        )
        new_data, found = raw_patch(data, block_id, new_v)
        print(f"[✓] {key}.{sub_field} = {val} ({'patched' if found else 'appended'})")
        return new_data

    if fmt in ("i32", "u32", "u64"):
        try:
            value = int(val, 0)
        except ValueError:
            print(
                f"[!] {key}: expected integer for type {fmt}, got {val!r}; "
                "skipping this change"
            )
            return data
    elif fmt == "str":
        value = val
    elif fmt == "ba":
        value = bytes.fromhex(val)
    else:
        print(f"[!] Type {fmt} does not support direct --set editing")
        return data

    new_data, found = raw_patch(data, block_id, value)
    disp = fmt_value(key, fmt, value)
    print(
        f"[✓] {key} = {disp} ({'patched in-place' if found else 'appended new block'})"
    )
    return new_data


def export_json(data: bytes, path: Path):
    DBI_SCHEMA = _schema.DBI_SCHEMA
    from .scanner import raw_find_block

    result = {}
    for block_id, (name, fmt) in sorted(DBI_SCHEMA.items()):
        if raw_find_block(data, block_id) == -1:
            continue
        value = raw_read(data, block_id)
        if fmt == "ba":
            result[name] = {
                "_type": "ba",
                "data": base64.b64encode(value).decode() if value else None,
            }
        elif fmt in ("theme_key", "two_u64", "two_i32"):
            result[name] = {"_type": fmt, **value}
        else:
            result[name] = value
    with open(path, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2, default=str)
    print(f"[✓] Exported {len(result)} fields → {path}")


def import_json(data: bytes, path: Path) -> bytes:
    DBI_SCHEMA = _schema.DBI_SCHEMA
    NAME_TO_ID = {v[0]: k for k, v in DBI_SCHEMA.items()}
    with open(path, encoding="utf-8") as f:
        obj = json.load(f)
    for name, val in obj.items():
        if name.startswith("_") or name not in NAME_TO_ID:
            if not name.startswith("_"):
                print(f"[!] {name}: not in schema, skipped")
            continue
        block_id = NAME_TO_ID[name]
        _, fmt = DBI_SCHEMA[block_id]
        if isinstance(val, dict) and "_type" in val:
            if val["_type"] == "ba":
                value = base64.b64decode(val["data"]) if val.get("data") else None
            else:
                value = {k: v for k, v in val.items() if k != "_type"}
        elif fmt in ("i32", "u32", "u64"):
            value = int(val)
        else:
            value = val
        data, found = raw_patch(data, block_id, value)
        print(f"[✓] {name} ({'patched' if found else 'appended'})")
    return data
