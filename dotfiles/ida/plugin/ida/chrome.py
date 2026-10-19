"""
Window chrome a theme cannot reach, because it is not drawn by Qt style
sheets:

- the Windows title bar: drawn by the OS (DWM). On Windows 11 the caption,
  caption text and border colours can be set per window; on Windows 10 we
  can only ask for the dark title bar.
- the nav band scroll buttons: IDA sets their (black) icon in code after the
  theme is applied, so we replace it at runtime.

Icons are in chrome_*.py modules (chrome_faded_disabled_icons,
chrome_action_icons, chrome_icon_swap, chrome_window_icons, sharing
chrome_icon_resources); Chrome sets them up and
refreshes them with everything else.
"""

import ctypes
import os
import re
import sys

from PySide6.QtCore import QObject, QTimer
from PySide6.QtGui import QIcon
from PySide6.QtWidgets import QAbstractButton, QApplication

from color_gen import TITLEBAR__BORDER, TITLEBAR__CAPTION, TITLEBAR__TEXT
from ida.chrome_action_icons import ActionIcons
from ida.chrome_faded_disabled_icons import install_faded_disabled_icons
from ida.chrome_icon_resources import IconResources
from ida.chrome_icon_swap import IconSwap
from ida.chrome_window_icons import WindowIcons
from perf import perf

DWMWA_USE_IMMERSIVE_DARK_MODE = 20
DWMWA_BORDER_COLOR = 34
DWMWA_CAPTION_COLOR = 35
DWMWA_TEXT_COLOR = 36

THEME_DIR_RE = re.compile(r'url\("([^"]*/themes/pwnbox)/icons/')
POLL_MS = 1000


def _colorref(hex_color):
    r, g, b = (int(hex_color[i:i + 2], 16) for i in (1, 3, 5))
    return b << 16 | g << 8 | r


def _app():
    app = QApplication.instance()
    assert isinstance(app, QApplication)
    return app


def theme_dir():
    """The active pwnbox theme folder, or None if another theme is active
    (or there is no GUI)."""
    app = QApplication.instance()
    if not isinstance(app, QApplication):
        return None
    m = THEME_DIR_RE.search(app.styleSheet())
    return m.group(1) if m else None


class Chrome(QObject):
    def __init__(self, theme_dir):
        super().__init__()
        self.styled = set()
        self.nav_icons = {
            "Scroll up": QIcon(os.path.join(theme_dir, "icons", "arrow-left.svg")),
            "Scroll down": QIcon(os.path.join(theme_dir, "icons", "arrow-right.svg")),
        }
        self.nav_buttons: list[QAbstractButton] = []
        self.dwm = ctypes.windll.dwmapi if sys.platform == "win32" else None
        with perf.measure("init: faded disabled icons (setStyle)", report=True):
            self.style = install_faded_disabled_icons()
        with perf.measure("init: icon resources", report=True):
            self.icon_resources = IconResources(theme_dir)
        with perf.measure("init: action icons", report=True):
            self.action_icons = ActionIcons(self.icon_resources)
        with perf.measure("init: row icons", report=True):
            self.icon_swap = IconSwap(self.icon_resources)
        with perf.measure("init: window icons", report=True):
            self.window_icons = WindowIcons(theme_dir)

        _app().focusChanged.connect(self.refresh)
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.refresh)
        self.timer.start(POLL_MS)
        with perf.measure("init: first refresh", report=True):
            self.refresh()

    def stop(self):
        self.timer.stop()
        try:
            _app().focusChanged.disconnect(self.refresh)
        except (RuntimeError, TypeError):
            pass
        self.action_icons.stop()
        self.icon_swap.stop()
        self.window_icons.stop()

    def refresh(self, *_):
        with perf.measure("refresh"):
            with perf.measure("refresh: title bars"):
                for w in QApplication.topLevelWidgets():
                    if w.isVisible():
                        self._style_title_bar(w)
            with perf.measure("refresh: nav buttons"):
                self._fix_nav_buttons()
            with perf.measure("refresh: action icons"):
                self.action_icons.refresh()
            with perf.measure("refresh: row icons"):
                self.icon_swap.refresh()
            with perf.measure("refresh: window icons"):
                self.window_icons.refresh()

    def _set_dwm(self, hwnd, attr, value):
        v = ctypes.c_int(value)
        return self.dwm.DwmSetWindowAttribute(hwnd, attr, ctypes.byref(v), ctypes.sizeof(v)) == 0

    def _style_title_bar(self, w):
        if self.dwm is None:
            return
        hwnd = int(w.winId())
        if hwnd in self.styled:
            return
        self.styled.add(hwnd)
        self._set_dwm(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, 1)
        self._set_dwm(hwnd, DWMWA_CAPTION_COLOR, _colorref(TITLEBAR__CAPTION))
        self._set_dwm(hwnd, DWMWA_TEXT_COLOR, _colorref(TITLEBAR__TEXT))
        self._set_dwm(hwnd, DWMWA_BORDER_COLOR, _colorref(TITLEBAR__BORDER))

    def _fix_nav_buttons(self):
        if not self.nav_buttons:
            self.nav_buttons = [
                w for w in QApplication.allWidgets()
                if isinstance(w, QAbstractButton)
                and w.metaObject().className() == "nav_scroll_button_t"
            ]
        alive = []
        for b in self.nav_buttons:
            try:
                icon = self.nav_icons.get(b.toolTip())
            except RuntimeError:
                continue
            alive.append(b)
            if icon is not None and b.icon().cacheKey() != icon.cacheKey():
                b.setIcon(icon)
        self.nav_buttons = alive
