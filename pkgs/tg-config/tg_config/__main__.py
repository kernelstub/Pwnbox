#!/usr/bin/env python3
"""
tg-config — Telegram Desktop settings reader/writer.
Entry point (uv run tg-config  /  python -m tg_config).
"""

import argparse
import os
import sys
from pathlib import Path

import tomllib

from . import schema as _schema
from .editor import apply_set, export_json, import_json
from .experimental import (
    dump_experimental,
    experimental_path,
    load_experimental,
    parse_bool,
    save_experimental,
)
from .formatter import deep_scan_diagnostic, dump_all, dump_app_settings, dump_tail_info
from .io import load, save
from .scanner import get_positions, raw_read
from .schema_loader import load_schema


def _default_config_path() -> Path:
    """Return the default config path (XDG_CONFIG_HOME or ~/.config)."""
    xdg = os.environ.get("XDG_CONFIG_HOME")
    base = Path(xdg) if xdg else Path.home() / ".config"
    return base / "tg-config" / "config.toml"


def _load_config(path: Path | None, *, required: bool):
    """Load config TOML and return (tdata, set, set_exp, unset_exp, theme_path).

    - "set" / "set_exp" / "unset_exp" are lists of strings, using the same
      format as CLI arguments.
    - "theme_path" is the path to .tdesktop-theme file if specified
    - If required=True and file is missing, exits with code 1.
    """

    if path is None:
        return None, [], [], [], None

    if not path.exists():
        if required:
            print(f"[!] Config not found: {path}")
            sys.exit(1)
        return None, [], [], [], None

    try:
        with open(path, "rb") as f:
            cfg = tomllib.load(f)
    except Exception as e:  # pragma: no cover - config errors are runtime only
        print(f"[!] Failed to load config {path}: {e}")
        return None, [], [], [], None

    if not isinstance(cfg, dict):
        print(f"[!] Config root must be a table/object: {path}")
        return None, [], [], [], None

    raw_tdata = cfg.get("tdata")
    tdata = None
    if isinstance(raw_tdata, str) and raw_tdata.strip():
        tdata = Path(os.path.expanduser(raw_tdata.strip()))

    def _as_list(key: str) -> list[str]:
        value = cfg.get(key)
        if value is None:
            return []
        if isinstance(value, str):
            return [value]
        if isinstance(value, list):
            return [str(v) for v in value]
        print(f"[~] Config key {key!r} must be a string or list of strings; ignored")
        return []

    # Old-style list-based config (still supported)
    set_list = _as_list("set")
    set_exp_list = _as_list("set_exp")
    unset_exp_list = _as_list("unset_exp")

    # New-style tables:
    # [settings]
    #   ScalePercent = 150
    #   AutoStart = 0
    settings_tbl = cfg.get("settings")
    if isinstance(settings_tbl, dict):
        for name, value in settings_tbl.items():
            if isinstance(value, bool):
                v = "1" if value else "0"
            else:
                v = str(value)
            set_list.append(f"{name}={v}")
    elif settings_tbl is not None:
        print("[~] [settings] must be a table/object; ignored")

    # [experimental]
    #   show-peer-id-below-about = true
    experimental_tbl = cfg.get("experimental")
    if isinstance(experimental_tbl, dict):
        for name, value in experimental_tbl.items():
            if isinstance(value, bool):
                v = "1" if value else "0"
            else:
                v = str(value)
            set_exp_list.append(f"{name}={v}")
    elif experimental_tbl is not None:
        print("[~] [experimental] must be a table/object; ignored")

    # [theme]
    #   path = "/path/to/theme.tdesktop-theme"
    theme_path = None
    theme_tbl = cfg.get("theme")
    if isinstance(theme_tbl, dict):
        raw_path = theme_tbl.get("path")
        if isinstance(raw_path, str) and raw_path.strip():
            theme_path = Path(os.path.expanduser(raw_path.strip()))
    elif isinstance(theme_tbl, str) and theme_tbl.strip():
        # Also support: theme = "/path/to/theme.tdesktop-theme"
        theme_path = Path(os.path.expanduser(theme_tbl.strip()))
    elif theme_tbl is not None:
        print("[~] [theme] must be a table with 'path' or a string; ignored")

    if any([set_list, set_exp_list, unset_exp_list, tdata, theme_path]):
        print(f"[*] Loaded config: {path}")

    return tdata, set_list, set_exp_list, unset_exp_list, theme_path


def main():
    ap = argparse.ArgumentParser(
        description="Telegram Desktop settings reader/writer",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                              # show all known settings
  %(prog)s -v                           # include field descriptions
  %(prog)s --dump-tail                  # inspect unparsed tail in stream
  %(prog)s --deep-scan                  # find all known IDs via bytes.find
  %(prog)s --set ScalePercent=150
  %(prog)s --set AutoStart=1 --set StartMinimized=1
  %(prog)s --set NightMode=1
  %(prog)s --set AnimationsDisabled=1
  %(prog)s --set "PowerSaving+=AllAnimations"
  %(prog)s --set "PowerSaving-=AnimatedStickers"
  %(prog)s --set-exp show-peer-id-below-about=1
  %(prog)s --unset-exp webview-debug-enabled
  %(prog)s --exp-list
  %(prog)s --app-settings
  %(prog)s --export backup.json
  %(prog)s --import-file backup.json
""",
    )
    ap.add_argument(
        "--config",
        default=None,
        help="path to config TOML (default: XDG_CONFIG_HOME/tg-config/config.toml)",
    )
    ap.add_argument(
        "--tdata", default=None, help="path to Telegram Desktop tdata directory"
    )
    ap.add_argument(
        "--set",
        action="append",
        metavar="KEY=VALUE",
        help="set DBI setting value (can be used multiple times)",
    )
    ap.add_argument(
        "--set-exp",
        action="append",
        metavar="KEY=BOOL",
        help="set experimental option in experimental_options.json",
    )
    ap.add_argument(
        "--unset-exp",
        action="append",
        metavar="KEY",
        help="remove key from experimental_options.json",
    )
    ap.add_argument(
        "--exp-list",
        action="store_true",
        help="print known experimental options and current values",
    )
    ap.add_argument(
        "--export", metavar="FILE", help="export current known DBI settings to JSON"
    )
    ap.add_argument(
        "--import-file",
        metavar="FILE",
        dest="import_file",
        help="import DBI settings from JSON",
    )
    ap.add_argument(
        "--dump-tail",
        action="store_true",
        help="show parser stop offset and tail diagnostics",
    )
    ap.add_argument(
        "--deep-scan",
        action="store_true",
        help="scan for all known block IDs across full stream",
    )
    ap.add_argument(
        "--app-settings",
        action="store_true",
        help="decode and print ApplicationSettings blob",
    )
    ap.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="include human-readable descriptions",
    )
    ap.add_argument(
        "--offline",
        action="store_true",
        help="skip GitHub schema fetch, use offline inference",
    )
    ap.add_argument(
        "--schema-version",
        default=None,
        help="force Telegram version for schema lookup (e.g. 5.9.1)",
    )
    ap.add_argument(
        "--schema-info", action="store_true", help="print loaded DBI schema and exit"
    )
    args = ap.parse_args()

    # ── Load config (TOML) ────────────────────────────────────────────────
    config_path = (
        Path(args.config).expanduser() if args.config else _default_config_path()
    )
    cfg_tdata, cfg_set, cfg_set_exp, cfg_unset_exp, cfg_theme_path = _load_config(
        config_path,
        required=bool(args.config),
    )
    
    # Check if config exists and no CLI actions specified
    has_cli_actions = any([
        args.set,
        args.set_exp,
        args.unset_exp,
        args.exp_list,
        args.export,
        args.import_file,
        args.dump_tail,
        args.deep_scan,
        args.app_settings,
        args.schema_info,
    ])
    
    if not config_path.exists() and not has_cli_actions:
        print(f"""[!] Config file not found: {config_path}

Create a config file to automatically apply settings on Telegram startup:

  mkdir -p {config_path.parent}
  cp /usr/share/doc/tg-config/config.example.toml {config_path}
  
  # Or for manual installation:
  # Get example from: https://github.com/meowrch/tg-config/blob/main/config.example.toml

Then edit the config with your preferred settings.

Alternatively, use CLI arguments to modify settings directly:
  tg-config --set ScalePercent=150
  tg-config --set NightMode=1
""")
        sys.exit(0)

    # Merge tdata sources: CLI > config > env/default
    if args.tdata:
        tdata = Path(args.tdata)
    elif cfg_tdata is not None:
        tdata = cfg_tdata
    else:
        tdata = Path(
            os.environ.get(
                "TDATA_PATH", Path.home() / ".local/share/TelegramDesktop/tdata"
            )
        )

    if not tdata.exists():
        print(f"[!] tdata not found: {tdata}")
        sys.exit(1)

    # Merge config actions with CLI arguments; CLI has priority because it runs last
    # (config actions are applied first, then CLI args).
    args.set = (cfg_set or []) + (args.set or [])
    args.set_exp = (cfg_set_exp or []) + (args.set_exp or [])
    args.unset_exp = (cfg_unset_exp or []) + (args.unset_exp or [])
    
    # Apply theme if specified in config (Telegram must be closed)
    if cfg_theme_path:
        from .theme import apply_theme
        
        if cfg_theme_path.exists():
            print(f"[*] Applying theme from config: {cfg_theme_path}")
            apply_theme(cfg_theme_path, tdata, night=False)
        else:
            print(f"[!] Theme file not found: {cfg_theme_path}")

    exp_modified = False
    exp_data: dict[str, bool] = {}
    exp_requested = bool(args.set_exp or args.unset_exp or args.exp_list)
    if exp_requested:
        exp_file = experimental_path(tdata)
        exp_data = load_experimental(exp_file)

        if args.set_exp:
            for kv in args.set_exp:
                if "=" not in kv:
                    print(f"[!] --set-exp format must be KEY=BOOL (got: {kv!r})")
                    continue
                key, raw_value = kv.split("=", 1)
                key = key.strip()
                parsed = parse_bool(raw_value)
                if parsed is None:
                    print(f"[!] {key}: BOOL must be 0/1/true/false/on/off/yes/no")
                    continue
                if key not in _schema.EXPERIMENTAL_OPTIONS:
                    print(f"[~] {key}: key is not in known list, but will be saved")
                old = exp_data.get(key, None)
                exp_data[key] = parsed
                if old != parsed:
                    exp_modified = True
                print(f"[✓] experimental {key} = {str(parsed).lower()}")

        if args.unset_exp:
            for key in args.unset_exp:
                key = key.strip()
                if key in exp_data:
                    del exp_data[key]
                    exp_modified = True
                    print(f"[✓] experimental {key} removed")
                else:
                    print(f"[~] experimental {key} is not present")

        if exp_modified:
            save_experimental(exp_file, exp_data)

        if args.exp_list:
            dump_experimental(exp_data)

    only_exp_actions = exp_requested and not any(
        [
            args.set,
            args.export,
            args.import_file,
            args.dump_tail,
            args.deep_scan,
            args.app_settings,
            args.schema_info,
        ]
    )
    if only_exp_actions:
        return

    # ── Load schema ──────────────────────────────────────────────────────
    _schema.DBI_SCHEMA, tg_version = load_schema(
        tdata=tdata,
        force_version=args.schema_version,
        offline=args.offline,
    )

    if args.schema_info:
        print(f"\n Schema for TG v{tg_version} ({len(_schema.DBI_SCHEMA)} blocks)\n")
        for bid, (name, fmt) in sorted(_schema.DBI_SCHEMA.items()):
            print(f"  0x{bid:04X}  {name:<35} {fmt}")
        return

    # ── Read settings ─────────────────────────────────────────────────────
    print(f"[*] tdata: {tdata}")
    
    # Check if settings file exists
    try:
        raw_data, salt, auth_key, version = load(tdata)
    except FileNotFoundError:
        print(f"""[!] Telegram settings file not found in: {tdata}

This usually means Telegram Desktop has never been launched on this system.

To fix this:
  1. Launch Telegram Desktop at least once
  2. Complete the initial setup (login if needed)
  3. Close Telegram
  4. Run tg-config again

The settings file will be created automatically after the first launch.
""")
        sys.exit(1)
    
    seq_pos = get_positions(raw_data)
    print(
        f"[*] TG version: {tg_version} | TDF version: {version} | Salt: {salt[:8].hex()}..."
    )
    print(f"[*] Sequential: {len(seq_pos)} blocks | Stream size: {len(raw_data)} bytes")

    if args.deep_scan:
        deep_scan_diagnostic(raw_data)
        return

    if args.dump_tail:
        dump_tail_info(raw_data)
        return

    modified = False

    if args.import_file:
        ip = Path(args.import_file)
        if not ip.exists():
            print(f"[!] File not found: {ip}")
            sys.exit(1)
        raw_data = import_json(raw_data, ip)
        modified = True

    if args.set:
        for kv in args.set:
            if "+=" in kv or ("-=" in kv and not kv.startswith("-")):
                k, v = kv, ""
            elif "=" not in kv:
                print(f"[!] Format must be KEY=VALUE (got: {kv!r})")
                continue
            else:
                k, v = kv.split("=", 1)
                k, v = k.strip(), v.strip()
            prev = raw_data
            raw_data = apply_set(raw_data, k, v)
            if raw_data is not prev:
                modified = True

    if modified:
        save(tdata, raw_data, salt, auth_key, version)

    if args.export:
        export_json(raw_data, Path(args.export))

    dump_all(raw_data, verbose=args.verbose)

    if args.app_settings:
        blob = raw_read(
            raw_data,
            _schema.DBI_SCHEMA.get(
                next(
                    (
                        k
                        for k, v in _schema.DBI_SCHEMA.items()
                        if v[0] == "ApplicationSettings"
                    ),
                    None,
                )
            ),
        )
        if blob:
            dump_app_settings(blob, verbose=args.verbose)
        else:
            print("[*] ApplicationSettings not found")


if __name__ == "__main__":
    main()
