"""
Dock window icons and header buttons: IDA takes them from its own icon table
without an action, so ActionIcons cannot reach them. Windows are recognised
by their title instead (the `windows` section of config-icons-ida.yaml,
WINDOW_ICONS: title -> icon path in the theme folder), in their tab, header,
title bar and Windows menu entry; header buttons by tooltip.
"""

import os
import time

import ida_kernwin
from PySide6.QtCore import QEvent, QObject
from PySide6.QtGui import QIcon, QPainter
from PySide6.QtWidgets import QAbstractButton, QApplication, QLabel, QMenu, QStyle, QTabBar

from ida.window_icons_gen import WINDOW_ICONS
from perf import perf

DOCK_WINDOW_CLASS = "IDADockWidget"
DOCK_TITLE_CLASS = "DockWidgetTitle"
DOCK_AREA_TITLE_CLASS = "DockAreaDragTitle"
DOCK_TAB_BAR_CLASS = "DockTabBar"
DOCK_BUTTON_ICONS = {
    "Close": "extra/window-close.svg",
    "Fullscreen": "extra/window-fullscreen.svg",
    "Float": "extra/window-float.svg",
}
WINDOWS_MENU = "Windows"
WATCHED_PROPERTY = "pwnboxWindowIcons"
TITLE_PROPERTY = "pwnboxWindowTitle"
DOCK_SCAN_FALLBACK_S = 2


class WindowIcons(QObject):
    """Dock window icons, by window title, wherever IDA shows them: the
    window's own icon (title bar when floating), its header, its tab and its
    Windows menu entry, plus the header's buttons. IDA re-applies its
    icons at will, so the headers and tab bars are watched and fixed up right
    before they paint, and the Windows menu right before it shows."""

    def __init__(self, theme_dir):
        super().__init__()

        def icon(path):
            file = os.path.join(theme_dir, *path.split("/"))
            return QIcon(file) if os.path.isfile(file) else None

        self.icons = [(title, is_prefix, icon(path)) for title, is_prefix, path in WINDOW_ICONS]
        self.button_icons = {tip: icon(path) for tip, path in DOCK_BUTTON_ICONS.items()}
        self.stale = True
        self.last_scan = 0.0
        self.hooks = _WindowIconHooks(self)
        self.hooks.hook()

    def mark_stale(self):
        self.stale = True

    def icon(self, title):
        """The theme's icon for a dock window title, or None."""
        title = title.strip()
        for name, is_prefix, icon in self.icons:
            if title == name or (is_prefix and title.startswith(name)):
                return icon
        return None

    def refresh(self):
        now = time.monotonic()
        if not self.stale and now - self.last_scan < DOCK_SCAN_FALLBACK_S:
            return
        self.stale = False
        self.last_scan = now
        for w in QApplication.allWidgets():
            kind = w.metaObject().className()
            if kind == DOCK_WINDOW_CLASS:
                _set_icon(self.icon(w.windowTitle()), w.windowIcon, w.setWindowIcon)
            elif kind == DOCK_TAB_BAR_CLASS and isinstance(w, QTabBar):
                self._watch(w)
                self._fix_tabs(w)
            elif kind == DOCK_TITLE_CLASS:
                self._watch_title(w)
                self._watch_buttons(w)
            elif kind == DOCK_AREA_TITLE_CLASS:
                self._watch_buttons(w)
            elif isinstance(w, QMenu) and _menu_text(w.title()) == WINDOWS_MENU:
                self._watch(w)

    def stop(self):
        self.hooks.unhook()

    def _watch(self, widget):
        if not widget.property(WATCHED_PROPERTY):
            widget.setProperty(WATCHED_PROPERTY, True)
            widget.installEventFilter(self)
            widget.update()

    def _watch_title(self, title):
        labels = title.findChildren(QLabel)
        text = next((label.text() for label in labels if label.text()), "")
        for label in labels:
            if not label.text():
                if label.property(TITLE_PROPERTY) != text:
                    label.setProperty(TITLE_PROPERTY, text)
                    label.update()
                self._watch(label)

    def _watch_buttons(self, header):
        """The header's Close / Fullscreen / Float buttons."""
        for button in header.findChildren(QAbstractButton):
            icon = self.button_icons.get(button.toolTip())
            if icon is not None:
                self._watch(button)
                _set_icon(icon, button.icon, button.setIcon)

    def _fix_tabs(self, bar):
        for i in range(bar.count()):
            _set_icon(self.icon(bar.tabText(i)), lambda: bar.tabIcon(i),
                      lambda icon: bar.setTabIcon(i, icon))

    def _fix_menu(self, menu):
        """The Windows menu's entries are named after the windows' titles."""
        for action in menu.actions():
            _set_icon(self.icon(_menu_text(action.text())), action.icon, action.setIcon)

    def eventFilter(self, watched, event):
        if event.type() == QEvent.Type.Show and isinstance(watched, QMenu):
            try:
                with perf.measure("window icons: menu"):
                    self._fix_menu(watched)
            except RuntimeError:
                pass
            return False
        if event.type() != QEvent.Type.Paint:
            return False
        with perf.measure("window icons: paint " + type(watched).__name__):
            return self._paint_event(watched)

    def _paint_event(self, watched):
        try:
            if isinstance(watched, QTabBar):
                self._fix_tabs(watched)
            elif isinstance(watched, QAbstractButton):
                _set_icon(self.button_icons.get(watched.toolTip()), watched.icon, watched.setIcon)
            elif isinstance(watched, QLabel):
                return self._paint_label(watched)
        except RuntimeError:
            pass
        return False

    def _paint_label(self, label):
        """Paint the theme's icon in place of a header's icon label (IDA keeps
        re-applying its own pixmap, so it is painted over rather than replaced)."""
        pixmap = label.pixmap()
        if pixmap.isNull():
            return False
        rect_args = (label.layoutDirection(), label.alignment(), label.contentsRect())
        icon = self.icon(str(label.property(TITLE_PROPERTY) or ""))
        if icon is None:
            return False
        size = pixmap.deviceIndependentSize().toSize()
        rect = QStyle.alignedRect(rect_args[0], rect_args[1], size, rect_args[2])
        painter = QPainter(label)
        painter.drawPixmap(rect.topLeft(), icon.pixmap(size, pixmap.devicePixelRatio()))
        painter.end()
        return True


def _menu_text(text):
    """A menu or action text without its & mnemonics and tab-separated shortcut."""
    return text.split("\t")[0].replace("&&", "\0").replace("&", "").replace("\0", "&").strip()


def _set_icon(icon, get, set_):
    """set_(icon) unless it is already set (setting icons repaints)."""
    if icon is not None and get().cacheKey() != icon.cacheKey():
        set_(icon)


class _WindowIconHooks(ida_kernwin.UI_Hooks):
    """Marks the docks stale when IDA shows, hides or switches windows; the
    scan waits for the next refresh."""

    def __init__(self, icons):
        super().__init__()
        self.icons = icons

    def widget_visible(self, widget):
        self.icons.mark_stale()

    def widget_invisible(self, widget):
        self.icons.mark_stale()

    def current_widget_changed(self, widget, prev_widget):
        self.icons.mark_stale()
