"""
Static schema constants — DBI block IDs, descriptions, aliases, APP_SCHEMA.
The actual runtime schema is loaded dynamically via schema_loader.load_schema().
"""

# Populated at runtime by __main__ after load_schema()
DBI_SCHEMA: dict[int, tuple[str, str]] = {}

# Human-readable descriptions for --verbose mode
DBI_DESCRIPTION: dict[str, str] = {
    "AutoStart": "Start with system (0=off, 1=on)",
    "StartMinimized": "Start minimized to tray (0/1)",
    "SoundNotify": "Notification sound (0/1)",
    "WorkMode": "Tray mode (0=window, 1=tray, 2=window+tray)",
    "SeenTrayTooltip": "Tray tooltip already shown (0/1)",
    "DesktopNotify": "Desktop notifications (0/1)",
    "AutoUpdate": "Auto update (0/1)",
    "LastUpdateCheck": "Unix timestamp of last update check",
    "AskDownloadPath": "Ask path before downloading (0/1)",
    "SendToMenu": '"Send to Telegram" context menu item (0/1)',
    "CompressPastedImage": "Compress pasted images (0/1)",
    "NotifyView": "Notification view (0=with text, 1=name only, 2=nothing)",
    "BackgroundKey": "Wallpaper file keys {day, night}",
    "SavedGifsLimit": "Saved GIF limit",
    "DownloadPath": "Download folder path",
    "DialogLastPath": "Last path in file picker dialog",
    "TileBackground": "Tile wallpaper {day, night} (0/1)",
    "AutoPlayGif": "Auto-play GIF (0/1)",
    "StickersRecentLimit": "Recent stickers limit",
    "StickersFavedLimit": "Favorite stickers limit",
    "AnimationsDisabled": "Disable UI animations (0/1)",
    "ScalePercent": "UI scale: 0=auto, 100, 125, 150, 200, 300",
    "LangPackKey": "Language pack file key",
    "LanguagesKey": "Languages list file key",
    "ApplicationSettings": "Main settings blob (Core::Settings)",
    "PowerSaving": "Power saving flags (bitmask)",
    "ThemeKey": "Theme file keys {day, night, night_mode}",
    "ConnectionType": "Proxy settings (blob)",
    "DcOptions": "MTP DC options (blob)",
}

POWER_SAVING_FLAGS: dict[int, str] = {
    0x001: "AnimationsInChats",
    0x002: "VideoInChats",
    0x004: "AnimatedEmoji",
    0x008: "AnimatedStickers",
    0x010: "AnimatedBackground",
    0x020: "AllAnimations",
}

# Sub-field aliases for --set
ALIASES: dict[str, tuple[str, str]] = {
    "NightMode": ("ThemeKey", "night_mode"),
    "ThemeKeyDay": ("ThemeKey", "day"),
    "ThemeKeyNight": ("ThemeKey", "night"),
    "TileBackgroundDay": ("TileBackground", "day"),
    "TileBackgroundNight": ("TileBackground", "night"),
}

# Schema for ApplicationSettings blob (Core::Settings)
APP_SCHEMA: dict[int, tuple[str, str]] = {
    0x01: ("DesktopNotify", "i32"),
    0x02: ("NotifyView", "i32"),
    0x03: ("NativeNotifications", "i32"),
    0x04: ("NotificationsCount", "i32"),
    0x05: ("NotificationsCorner", "i32"),
    0x06: ("SoundNotify", "i32"),
    0x07: ("IncludeMuted", "i32"),
    0x08: ("CountUnreadMessages", "i32"),
    0x0A: ("AutoDownloadPhoto", "i32"),
    0x0B: ("AutoDownloadAudio", "i32"),
    0x0C: ("AutoDownloadGif", "i32"),
    0x0D: ("AutoPlayGif", "i32"),
    0x0F: ("DialogsMode", "i32"),
    0x11: ("SongVolume", "i32"),
    0x12: ("VideoVolume", "i32"),
    0x13: ("AskDownloadPath", "i32"),
    0x14: ("DownloadPath", "str"),
    0x15: ("CompressPastedImage", "i32"),
    0x16: ("StickersFavedLimit", "i32"),
    0x17: ("DialogLastPath", "str"),
    0x1A: ("SendFilesWay", "i32"),
    0x20: ("ThirdColumnWidth", "i32"),
    0x21: ("ThirdSectionInfoEnabled", "i32"),
    0x22: ("SmallDialogsList", "i32"),
    0x23: ("ForwardQuoted", "i32"),
    0x26: ("GroupCallPushToTalk", "i32"),
    0x28: ("GroupCallPushToTalkDelay", "i32"),
    0x2B: ("VoicePlaybackSpeed", "i32"),
    0x30: ("TabbedPanelShowOnHover", "i32"),
    0x33: ("DialogFilters", "ba"),
    0x34: ("DialogFiltersEnabled", "i32"),
    0x36: ("VoiceRecordBitrateKbps", "i32"),
    0x37: ("VideoMessageQuality", "i32"),
}

# Known keys from Telegram Desktop experimental_options.json
# (settings/settings_experimental.cpp + referenced option ids)
EXPERIMENTAL_OPTIONS: dict[str, str] = {
    "tabbed-panel-show-on-click": "Show emoji/stickers panel only after click",
    "forum-hide-chats-list": "Hide chats list in forums",
    "fractional-scaling-enabled": "Enable precise fractional scaling",
    "high-dpi-downscale": "Alternative high-DPI downscale mode",
    "view-profile-in-chats-list-context-menu": 'Add "View Profile" to chats list context menu',
    "show-peer-id-below-about": "Show peer ID in profile",
    "show-channel-joined-below-about": "Show channel join date in profile",
    "use-small-msg-bubble-radius": "Use small message bubble radius",
    "disable-autoplay-next": "Disable autoplay of next track",
    "send-large-photos": "Send photos with increased side limit",
    "webview-debug-enabled": "Enable webview debugging",
    "webview-legacy-edge": "Use legacy Edge webview",
    "auto-scroll-inactive-chat": "Auto-scroll/read inactive chat",
    "hide-reply-button": "Hide Reply button in notifications",
    "custom-notification": "Force non-native notifications availability",
    "gnotification": "Force GLib GNotification",
    "freetype": "Use FreeType font engine",
    "skip-url-scheme-register": "Skip tg:// scheme registration on update",
    "deadlock-detector": "Enable deadlock detector",
    "external-media-viewer": "Use external media viewer",
    "new-windows-size-as-first": "Open new windows with first window size",
    "prefer-ipv6": "Prefer IPv6",
    "fast-buttons-mode": "Fast buttons mode (1-9)",
    "touchbar-disabled": "Disable Touch Bar (macOS)",
    "alternative-scroll-processing": "Legacy scroll handling in profiles",
    "moderate-common-groups": "Moderate users across multiple groups",
    "force-compose-search-one-column": "Force embedded search in one-column mode",
    "unlimited-recent-stickers": "Unlimited recent stickers",
}
