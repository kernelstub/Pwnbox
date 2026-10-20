"""
Динамическая загрузка DBI-схемы.

Приоритет источников:
  1. Кэш  ~/.cache/tg-settings/schema_<version>.json
  2. GitHub  (storage_settings_scheme.h для конкретного тега)
  3. Offline  — схема строится из самого расшифрованного потока tdata/settings
               методом sequential scan с «якорными» блоками известного формата.
               Статического fallback больше нет.
"""

import json
import os
import re
import struct
import urllib.error
import urllib.request
from pathlib import Path
from typing import Optional

CACHE_DIR = Path.home() / ".cache" / "tg-settings"


# ────────────────────────────────────────────────────────────────────────────
# Cache
# ────────────────────────────────────────────────────────────────────────────


def _cache_path(version_str: str) -> Path:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    return CACHE_DIR / f"schema_{version_str}.json"


def _load_cache(version_str: str) -> Optional[dict]:
    p = _cache_path(version_str)
    if p.exists():
        try:
            with open(p) as f:
                return json.load(f)
        except Exception:
            pass
    return None


def _save_cache(version_str: str, schema: dict):
    try:
        with open(_cache_path(version_str), "w") as f:
            json.dump(schema, f, indent=2)
    except Exception:
        pass


# ────────────────────────────────────────────────────────────────────────────
# Version detection
# ────────────────────────────────────────────────────────────────────────────


def _find_telegram_binary() -> Optional[Path]:
    candidates = [
        Path("/usr/bin/telegram-desktop"),
        Path("/usr/local/bin/telegram-desktop"),
        Path.home() / ".local/bin/Telegram",
        Path.home() / ".local/share/TelegramDesktop/Telegram",
        Path("/opt/telegram/Telegram"),
        Path("/opt/Telegram/Telegram"),
        Path.home() / ".var/app/org.telegram.desktop/data/TelegramDesktop/Telegram",
    ]
    for p in candidates:
        if p.exists() and os.access(p, os.X_OK):
            return p
    import shutil

    for name in ("Telegram", "telegram-desktop"):
        found = shutil.which(name)
        if found:
            return Path(found)
    return None


def get_tg_version_from_binary(binary: Optional[Path] = None) -> Optional[str]:
    if binary is None:
        binary = _find_telegram_binary()
    if binary is None:
        return None
    try:
        data = binary.read_bytes()
        pattern = rb"(\d+\.\d+\.\d+(?:\.\d+)?)\x00"
        matches = re.findall(pattern, data)
        valid = []
        for m in matches:
            parts = m.decode().split(".")
            try:
                major = int(parts[0])
                if 1 <= major <= 19 and len(parts) in (3, 4):
                    valid.append(m.decode())
            except ValueError:
                continue
        if not valid:
            return None
        from collections import Counter

        return Counter(valid).most_common(1)[0][0]
    except Exception:
        return None


def get_tg_version_from_tdata(tdata: Path) -> Optional[str]:
    for suffix in ["s", "0", "1"]:
        f = tdata / f"settings{suffix}"
        if not f.exists():
            continue
        try:
            raw = f.read_bytes()
            if raw[:4] != b"TDF$":
                continue
            ver_int = struct.unpack_from("<I", raw, 4)[0]
            if ver_int > 1_000_000:
                major = ver_int // 1_000_000
                rest = ver_int % 1_000_000
                minor = rest // 1000
                patch = rest % 1000
                return f"{major}.{minor}.{patch}"
        except Exception:
            continue
    return None


# ────────────────────────────────────────────────────────────────────────────
# GitHub API
# ────────────────────────────────────────────────────────────────────────────

GITHUB_API = "https://api.github.com"
REPO = "telegramdesktop/tdesktop"


def _gh_get(url: str) -> Optional[dict | list]:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "tdesktop-settings-tool/1.0",
            "Accept": "application/vnd.github.v3+json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 403:
            print("[!] GitHub rate limit exceeded.")
        return None
    except Exception as e:
        print(f"[!] GitHub API error: {e}")
        return None


def find_git_tag(version_str: str) -> Optional[str]:
    for tag_fmt in [f"v{version_str}", version_str]:
        url = f"{GITHUB_API}/repos/{REPO}/git/refs/tags/{tag_fmt}"
        data = _gh_get(url)
        if data and "ref" in data:
            return tag_fmt

    url = f"{GITHUB_API}/repos/{REPO}/tags?per_page=50"
    tags = _gh_get(url)
    if not tags:
        return None

    version_clean = version_str.lstrip("v")
    for tag in tags:
        if tag.get("name", "").lstrip("v") == version_clean:
            return tag["name"]

    parts = version_clean.split(".")
    if len(parts) >= 2:
        prefix = f"v{parts[0]}.{parts[1]}."
        for tag in tags:
            if tag.get("name", "").startswith(prefix):
                print(f"[~] Exact tag not found, using closest match: {tag['name']}")
                return tag["name"]
    return None


def fetch_scheme_header(tag: str) -> Optional[str]:
    path = "Telegram/SourceFiles/storage/details/storage_settings_scheme.h"
    url = f"https://raw.githubusercontent.com/{REPO}/{tag}/{path}"
    req = urllib.request.Request(
        url, headers={"User-Agent": "tdesktop-settings-tool/1.0"}
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.read().decode("utf-8", errors="replace")
    except Exception as e:
        print(f"[!] Failed to download schema: {e}")
        return None


# ────────────────────────────────────────────────────────────────────────────
# Enum parser  (используется когда есть доступ к GitHub)
# ────────────────────────────────────────────────────────────────────────────

_NAME_TO_FMT_HINTS: list[tuple[re.Pattern, str]] = [
    (re.compile(r"Key$"), "u64"),
    (re.compile(r"Keys?$"), "u64"),
    (re.compile(r"Authorization$"), "ba"),
    (re.compile(r"Settings$"), "ba"),
    (re.compile(r"Config$"), "ba"),
    (re.compile(r"Options$"), "ba"),
    (re.compile(r"Path$"), "str"),
    (re.compile(r"ThemeKey$"), "theme_key"),
    (re.compile(r"TileBackground$"), "two_i32"),
    (re.compile(r"BackgroundKey$"), "two_u64"),
    (re.compile(r"Percent$"), "i32"),
    (re.compile(r"Volume$"), "i32"),
    (re.compile(r"Speed$"), "i32"),
    (re.compile(r"Saving$"), "i32"),
    (re.compile(r"CacheSettings"), "ba"),
]


def _guess_fmt(name: str) -> str:
    for pattern, fmt in _NAME_TO_FMT_HINTS:
        if pattern.search(name):
            return fmt
    return "i32"


def parse_dbi_enum(header_src: str) -> dict[int, tuple[str, str]]:
    SKIP = {"dbiEncryptedWithSalt", "dbiEncrypted", "dbiVersion", "dbiKey", "dbiUser"}
    SKIP_SUFFIX = "Old"

    enum_match = re.search(r"\benum\s*\{([^}]+)\}", header_src, re.DOTALL)
    if not enum_match:
        return {}

    schema: dict[int, tuple[str, str]] = {}
    current_val = 0

    for line in enum_match.group(1).splitlines():
        line = re.sub(r"//.*", "", line).strip().rstrip(",").strip()
        if not line:
            continue
        m = re.match(r"(dbi\w+)\s*(?:=\s*(0[xX][0-9a-fA-F]+|\d+))?", line)
        if not m:
            continue
        raw_name, val_str = m.group(1), m.group(2)
        if val_str is not None:
            current_val = int(val_str, 0)
        if raw_name in SKIP or raw_name.endswith(SKIP_SUFFIX):
            current_val += 1
            continue
        name = raw_name[3:]
        schema[current_val] = (name, _guess_fmt(name))
        current_val += 1

    return schema


# ────────────────────────────────────────────────────────────────────────────
# Offline schema inference  — строим схему из самого потока tdata/settings
#
# Идея:
#   У нас есть «якорные» блоки — block_id с известным форматом, которые
#   присутствуют во всех версиях TG и никогда не меняют своё значение
#   формата (i32, ba, u64, …).  Мы используем их как опорные точки чтобы
#   пройти поток sequential scan и «измерить» размер каждого блока.
#   Блоки которых нет в якорях получают имя Unknown_0xXX и формат
#   определяется эвристически через поиск следующего якоря.
# ────────────────────────────────────────────────────────────────────────────

# Якоря — block_id с гарантированно известным форматом.
# Это минимально-стабильное подмножество схемы tdesktop,
# существующее с версии 1.x и не менявшееся по типу данных.
_ANCHORS: dict[int, tuple[str, str]] = {
    0x06: ("AutoStart", "i32"),
    0x07: ("StartMinimized", "i32"),
    0x0A: ("SeenTrayTooltip", "i32"),
    0x0C: ("AutoUpdate", "i32"),
    0x0D: ("LastUpdateCheck", "i32"),
    0x0E: ("SoundNotify", "i32"),
    0x0F: ("AutoDownload", "i32"),
    0x10: ("DesktopNotify", "i32"),
    0x14: ("WorkMode", "i32"),
    0x1A: ("ConnectionType", "ba"),
    0x1C: ("DcOptions", "ba"),
    0x1D: ("SendToMenu", "i32"),
    0x23: ("DialogLastPath", "str"),
    0x24: ("RecentEmoji", "ba"),
    0x27: ("RecentStickers", "ba"),
    0x28: ("EmojiVariants", "ba"),
    0x4B: ("MtpAuthorization", "ba"),
    0x4D: ("SessionSettings", "ba"),
    0x4E: ("LangPackKey", "u64"),
    0x54: ("ThemeKey", "theme_key"),
    0x55: ("TileBackground", "two_i32"),
    0x57: ("PowerSaving", "i32"),
    0x58: ("ScalePercent", "i32"),
    0x5A: ("LanguagesKey", "u64"),
    0x5C: ("CacheSettings", "ba"),
    0x5E: ("ApplicationSettings", "ba"),
    0x60: ("FallbackProductionConfig", "ba"),
    0x61: ("BackgroundKey", "two_u64"),
    0x64: ("NotifyView", "i32"),
}

# Таблица размеров фиксированных форматов (байт после block_id)
_FMT_FIXED: dict[str, int] = {
    "i32": 4,
    "u32": 4,
    "u64": 8,
    "theme_key": 20,  # u64 day + u64 night + u32 night_mode
    "two_u64": 16,  # u64 + u64
    "two_i32": 8,  # i32 + i32
}


def _value_size(data: bytes, p: int, fmt: str) -> Optional[int]:
    """Возвращает размер значения в байтах начиная с позиции p."""
    if fmt in _FMT_FIXED:
        return _FMT_FIXED[fmt]
    # str / ba  → QByteArray: 4 байта длина + данные
    if fmt in ("str", "ba"):
        if p + 4 > len(data):
            return None
        n = struct.unpack_from(">I", data, p)[0]
        return 4 if n == 0xFFFFFFFF else 4 + n
    return None


def _guess_fmt_by_bytes(data: bytes, vp: int) -> tuple[str, int]:
    """
    Эвристика для блока с неизвестным форматом.
    Перебираем кандидатов и смотрим — ведёт ли предполагаемый размер
    к следующему якорному block_id (или к нулям в конце потока).
    Возвращает (fmt, size).
    """
    # Порядок: сначала фиксированные, потом переменные
    fixed_candidates = [
        ("i32", 4),
        ("u32", 4),
        ("u64", 8),
        ("two_i32", 8),
        ("two_u64", 16),
        ("theme_key", 20),
        ("i32", 12),
        ("i32", 24),
        ("i32", 32),
    ]
    for fmt, size in fixed_candidates:
        nxt = vp + size
        if nxt + 4 > len(data):
            continue
        nxt_id = struct.unpack_from(">I", data, nxt)[0]
        if nxt_id in _ANCHORS or nxt_id == 0:
            return fmt, size

    # Пробуем QByteArray
    if vp + 4 <= len(data):
        n = struct.unpack_from(">I", data, vp)[0]
        if n == 0xFFFFFFFF:
            nxt = vp + 4
            if nxt + 4 <= len(data):
                nxt_id = struct.unpack_from(">I", data, nxt)[0]
                if nxt_id in _ANCHORS or nxt_id == 0:
                    return "ba", 4
        elif 0 < n < 10 * 1024 * 1024:
            nxt = vp + 4 + n
            if nxt + 4 <= len(data):
                nxt_id = struct.unpack_from(">I", data, nxt)[0]
                if nxt_id in _ANCHORS or nxt_id == 0:
                    return "ba", 4 + n

    # Ничего не подошло — скипаем 4 байта (i32 по умолчанию)
    return "i32", 4


def infer_schema_from_stream(raw_stream: bytes) -> dict[int, tuple[str, str]]:
    """
    Строит DBI-схему из расшифрованного потока tdata/settings.

    Проходит поток sequential scan используя _ANCHORS как опорные точки.
    Для неизвестных block_id определяет размер эвристически и
    присваивает имя Unknown_0xXX.

    Возвращает схему вида {block_id: (name, fmt)}.
    Блоки реально присутствующие в потоке — гарантированно есть в схеме.
    """
    schema: dict[int, tuple[str, str]] = {}
    p = 0
    unknown_counter = 0

    while p + 4 <= len(raw_stream):
        block_id = struct.unpack_from(">I", raw_stream, p)[0]

        # Конец потока
        if block_id == 0:
            break

        # Мусор — выходим
        if not (0x01 <= block_id <= 0xFFFF):
            break

        vp = p + 4

        if block_id in _ANCHORS:
            name, fmt = _ANCHORS[block_id]
            size = _value_size(raw_stream, vp, fmt)
            if size is None:
                break
            schema[block_id] = (name, fmt)
            p = vp + size

        else:
            # Неизвестный блок — определяем формат эвристически
            fmt, size = _guess_fmt_by_bytes(raw_stream, vp)
            name = f"Unknown_0x{block_id:02X}"
            schema[block_id] = (name, fmt)
            unknown_counter += 1
            p = vp + size

    if unknown_counter:
        print(
            f"[~] Offline inference: {len(schema)} blocks "
            f"({unknown_counter} unknown — Unknown_0xXX)"
        )
    else:
        print(f"[✓] Offline inference: {len(schema)} blocks, all recognized")

    return schema


# ────────────────────────────────────────────────────────────────────────────
# Public API
# ────────────────────────────────────────────────────────────────────────────


def load_schema(
    tdata: Optional[Path] = None,
    binary: Optional[Path] = None,
    force_version: Optional[str] = None,
    offline: bool = False,
    raw_stream: Optional[bytes] = None,
) -> tuple[dict[int, tuple[str, str]], str]:
    """
    Загружает DBI-схему.  Порядок источников:

      1. Кэш  (~/.cache/tg-settings/schema_<version>.json)
      2. GitHub  (storage_settings_scheme.h)
      3. Offline inference  (из расшифрованного потока tdata/settings)

    Параметры:
      tdata          — путь к папке tdata  (для определения версии и offline)
      binary         — путь к бинарнику TG  (для определения версии)
      force_version  — принудительная версия вида "5.9.1"
      offline        — пропустить GitHub, сразу offline inference
      raw_stream     — уже расшифрованный поток (если есть — используется
                       для offline inference без повторной расшифровки)

    Возвращает (schema_dict, version_str).
    """
    # ── Определяем версию ────────────────────────────────────────────────
    version = force_version
    if not version and tdata:
        version = get_tg_version_from_tdata(tdata)
    if not version:
        version = get_tg_version_from_binary(binary)
    if not version:
        version = "unknown"

    print(f"[*] TG version: {version}")

    # ── Кэш ─────────────────────────────────────────────────────────────
    if version != "unknown":
        cached = _load_cache(version)
        if cached:
            schema = {int(k): tuple(v) for k, v in cached.items()}
            print(f"[*] Schema loaded from cache ({len(schema)} blocks)")
            return schema, version

    # ── GitHub ───────────────────────────────────────────────────────────
    if not offline and version != "unknown":
        print(f"[*] Loading schema from GitHub for v{version}...")
        tag = find_git_tag(version)
        if tag:
            print(f"[*] Tag: {tag}")
            header_src = fetch_scheme_header(tag)
            if header_src:
                schema = parse_dbi_enum(header_src)
                if schema:
                    _save_cache(version, {str(k): list(v) for k, v in schema.items()})
                    print(f"[✓] Schema from GitHub: {len(schema)} blocks, cache saved")
                    return schema, version
        print("[~] GitHub unavailable, switching to offline inference")

    # ── Offline inference ────────────────────────────────────────────────
    print("[*] Offline inference — building schema from tdata/settings stream...")

    stream = raw_stream
    if stream is None and tdata is not None:
        stream = _read_raw_stream(tdata)

    if stream is None:
        # Совсем нет данных — отдаём только якоря как минимальную схему
        print("[~] Stream unavailable, using minimal anchor schema")
        return dict(_ANCHORS), version

    schema = infer_schema_from_stream(stream)

    # Кэшируем результат inference чтобы не повторять каждый раз
    if version != "unknown":
        _save_cache(version, {str(k): list(v) for k, v in schema.items()})
        print("[*] Inferred schema cached")

    return schema, version


def _read_raw_stream(tdata: Path) -> Optional[bytes]:
    """
    Читает и расшифровывает поток из tdata/settings.
    Используется только для offline inference внутри load_schema.
    """
    # Импортируем здесь чтобы избежать циклического импорта
    # (io.py → schema_loader, schema_loader → io было бы циклом)
    try:
        from .crypto import decrypt_local, derive_key
        from .tdf import _read_qt_ba, read_tdf
    except ImportError:
        # Если вызывается как standalone скрипт
        import sys

        sys.path.insert(0, str(Path(__file__).parent.parent))
        from tg_config.crypto import decrypt_local, derive_key
        from tg_config.tdf import _read_qt_ba, read_tdf

    try:
        payload, _ = read_tdf(tdata / "settings")
        salt, pos = _read_qt_ba(payload, 0)
        enc, _ = _read_qt_ba(payload, pos)
        auth_key = derive_key(salt)
        return decrypt_local(enc, auth_key)
    except Exception as e:
        print(f"[!] Failed to read stream for inference: {e}")
        return None
