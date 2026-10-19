"""
List row icons (Functions, Local Types, ...): rows get their icons straight
from IDA's resources, not through an action, so ActionIcons cannot reach
them. A QIcon does not tell where it was loaded from, so originals are
recognised by their pixels: every icon the theme has a version of
(<theme>/<path>, see chrome_icon_resources.py) is rendered from its resource
(:/<prefix>/<path>) the way IDA renders it, and a row icon drawing the same
pixels is swapped for the theme's.

The same lookup fixes menu entries whose icon IDA sets directly, with no
action behind it (submenus like Edit > Strings, which shows the current
string type), when their menu shows.
"""

import hashlib
import time

import ida_kernwin
from PySide6.QtCore import QEvent, QObject, QSize, QTimer
from PySide6.QtGui import QIcon, QImage
from PySide6.QtWidgets import QAbstractItemView, QApplication, QHeaderView, QMenu, QStyledItemDelegate

from perf import perf

FINGERPRINT_SIZE = QSize(16, 16)
TABLE_SLICE_MS = 8
VIEW_SCAN_FALLBACK_S = 10
MENU_WATCHED_PROPERTY = "pwnboxIconSwap"


def _fingerprint(image):
    """Identity of an icon's pixels (size, scale and contents)."""
    image = image.convertToFormat(QImage.Format.Format_ARGB32)
    data = bytes(image.constBits())[:image.sizeInBytes()]
    return image.width(), image.height(), image.devicePixelRatio(), hashlib.sha1(data).digest()


def _scale():
    app = QApplication.instance()
    assert isinstance(app, QApplication)
    return app.devicePixelRatio()


class IconSwap(QObject):
    """Swaps IDA's original icons for the theme's in list/tree rows drawn by
    a plain QStyledItemDelegate (it gets an IconSwapDelegate), and in menu
    entries when their menu shows."""

    def __init__(self, resources):
        super().__init__()
        self.pairs = []
        for path, resource in sorted(resources.resources.items()):
            file = resources.theme_file(path)
            if file is not None:
                original = QIcon(resource)
                if not original.isNull():
                    self.pairs.append((original, QIcon(file)))
        self.tables = {}
        self.building = {}
        self.icon_cache = {}
        self.stale = True
        self.last_scan = 0.0
        self.hooks = _IconSwapHooks(self)
        self.hooks.hook()

    def mark_stale(self):
        self.stale = True

    def _build(self, scale):
        """Start building the lookup table for `scale`, unless built or underway."""
        if scale not in self.tables and scale not in self.building:
            self.building[scale] = ({}, iter(self.pairs), time.perf_counter())
            QTimer.singleShot(0, lambda: self._build_slice(scale))

    def _build_slice(self, scale):
        table, pairs, start = self.building[scale]
        deadline = time.perf_counter() + TABLE_SLICE_MS / 1000
        with perf.measure("row icons: table slice"):
            for original, theme in pairs:
                table.setdefault(_fingerprint(original.pixmap(FINGERPRINT_SIZE, scale).toImage()), theme)
                if time.perf_counter() >= deadline:
                    QTimer.singleShot(0, lambda: self._build_slice(scale))
                    return
        del self.building[scale]
        self.tables[scale] = table
        perf.note("row icons: table @%g of %d icons built in %.0f ms (wall clock, in slices)"
                  % (scale, len(self.pairs), (time.perf_counter() - start) * 1000))
        for w in QApplication.allWidgets():
            if isinstance(w, QAbstractItemView) and isinstance(w.itemDelegate(), IconSwapDelegate):
                w.viewport().update()

    def icon(self, icon):
        """The theme's replacement for an original IDA icon, or None (also
        while the lookup table is being built)."""
        if icon is None or icon.isNull() or not self.pairs:
            return None
        scale = _scale()
        key = (icon.cacheKey(), scale)
        if key not in self.icon_cache:
            table = self.tables.get(scale)
            if table is None:
                self._build(scale)
                return None
            self.icon_cache[key] = table.get(_fingerprint(icon.pixmap(FINGERPRINT_SIZE, scale).toImage()))
        return self.icon_cache[key]

    def refresh(self):
        if not self.pairs:
            return
        self._build(_scale())
        now = time.monotonic()
        if not self.stale and now - self.last_scan < VIEW_SCAN_FALLBACK_S:
            return
        self.stale = False
        self.last_scan = now
        for w in QApplication.allWidgets():
            if isinstance(w, QAbstractItemView) and not isinstance(w, QHeaderView):
                delegate = w.itemDelegate()
                if delegate is not None and delegate.metaObject().className() == "QStyledItemDelegate":
                    w.setItemDelegate(IconSwapDelegate(self, w))
            elif isinstance(w, QMenu) and not w.property(MENU_WATCHED_PROPERTY):
                w.setProperty(MENU_WATCHED_PROPERTY, True)
                w.installEventFilter(self)

    def eventFilter(self, watched, event):
        """A menu about to show (IDA has just refilled it): swap its entries'
        original icons, e.g. submenus whose icon IDA sets directly."""
        if event.type() == QEvent.Type.Show and isinstance(watched, QMenu):
            try:
                with perf.measure("row icons: menu"):
                    for action in watched.actions():
                        replacement = self.icon(action.icon())
                        if replacement is not None:
                            action.setIcon(replacement)
            except RuntimeError:
                pass
        return False

    def stop(self):
        self.hooks.unhook()


class IconSwapDelegate(QStyledItemDelegate):
    """A plain item delegate, except original IDA icons are swapped for the theme's."""

    def __init__(self, swap, parent):
        super().__init__(parent)
        self.swap = swap

    def initStyleOption(self, option, index):
        with perf.measure("row icons: row"):
            super().initStyleOption(option, index)
            replacement = self.swap.icon(getattr(option, "icon"))
            if replacement is not None:
                setattr(option, "icon", replacement)


class _IconSwapHooks(ida_kernwin.UI_Hooks):
    """Marks the views stale when an IDA window shows (it may hold new
    lists); the scan waits for the next refresh."""

    def __init__(self, swap):
        super().__init__()
        self.swap = swap

    def widget_visible(self, widget):
        self.swap.mark_stale()
