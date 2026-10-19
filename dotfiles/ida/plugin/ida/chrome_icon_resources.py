"""
IDA's icon resources and the theme's versions of them, shared by the icon
replacements (chrome_action_icons.py, ...).

Icons are named by path: the Qt resource path without its `:/<prefix>/`
(:/IDAG/resources/menu/OpenFunctions.svg is resources/menu/OpenFunctions.svg),
which is also how IDA's icon table keys them. The theme's version of an icon
is that path in the theme folder (themes/pwnbox/resources/menu/
OpenFunctions.svg). The prefixes (IDAG, HVUI, ...) are dropped; dump-icons
checks no two resources then share a path.
"""

import os

import ida_kernwin
from PySide6.QtCore import QDirIterator

ICON_SUFFIXES = (".svg", ".png")


class IconResources:
    """Walks IDA's Qt resources once (a few hundred images)."""

    def __init__(self, theme_dir):
        self.theme_dir = theme_dir
        self.resources = {}
        self.table = {}
        it = QDirIterator(":/", QDirIterator.IteratorFlag.Subdirectories)
        while it.hasNext():
            resource = it.next()
            parts = resource[len(":/"):].split("/", 1)
            if len(parts) != 2 or not resource.endswith(ICON_SUFFIXES):
                continue
            path = parts[1]
            self.resources.setdefault(path, resource)
            icon_id = ida_kernwin.get_icon_id_by_name(path)
            if icon_id >= 0:
                self.table.setdefault(icon_id, path)

    def theme_file(self, path):
        """The theme's version of `path` (a file), or None if it has none."""
        file = os.path.join(self.theme_dir, *path.split("/"))
        return file if os.path.isfile(file) else None
