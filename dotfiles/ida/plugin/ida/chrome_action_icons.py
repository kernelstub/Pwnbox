"""
Action icons (toolbar, menus): IDA 9.4 only accepts its own built-in resource
paths in `qproperty-themeicon-*` (anything else blanks the icon), so the
theme's icons are set on the actions through the SDK instead.
"""

import time

import ida_kernwin
from PySide6.QtCore import QTimer

from ida.icon_meta_gen import ACTION_ICONS, UNNAMED_ICONS

ACTION_SCAN_MIN_S = 0.1
REPORT_MISSING_ICONS = True


class ActionIcons:
    """Gives every action showing one of IDA's icons the theme's version of
    it (see chrome_icon_resources.py and src/ida/icon_meta.yaml), found one
    of two ways:

    - icons in IDA's icon table, by path: the action's icon id is a table
      entry, whose path IconResources knows.
    - icons IDA loads without a name (e.g. the Git actions'), by action:
      nothing maps their id back to a file, so icon_meta lists the actions
      (UNNAMED_ICONS, `map_by_action`).

    An action in ACTION_ICONS (config `actions`) gets that icon instead,
    whatever icon it shows.

    Every pass looks at every action's current icon, so actions registered
    later (Hex-Rays, the debugger, plugins) and icons IDA changes later are
    both caught. Icons the theme has no version of are reported
    (REPORT_MISSING_ICONS)."""

    def __init__(self, resources):
        self.resources = resources
        self.unnamed = {}
        for path, actions in UNNAMED_ICONS:
            for action in actions:
                self.unnamed[action] = (path, resources.theme_file(path))
        self.overrides = {action: (path, resources.theme_file(path)) for action, path in ACTION_ICONS.items()}
        self.loaded = {}
        self.custom_ids = set()
        self.replaced = {}
        self.reported = set()
        self.last_scan = 0.0
        self.pending = False
        self.hooks = _ActionIconHooks(self)
        self.hooks.hook()

    def request_scan(self):
        """Scan soon (once per burst of requests, at most every ACTION_SCAN_MIN_S)."""
        if not self.pending:
            self.pending = True
            delay = max(0.0, ACTION_SCAN_MIN_S - (time.monotonic() - self.last_scan))
            QTimer.singleShot(int(delay * 1000), self._scheduled_scan)

    def _scheduled_scan(self):
        self.pending = False
        self.refresh()

    def refresh(self):
        self.last_scan = time.monotonic()
        missing = {}
        for action in ida_kernwin.get_registered_actions():
            ok, original = ida_kernwin.get_action_icon(action)
            if not ok or original < 0 or original in self.custom_ids:
                continue
            if action in self.overrides:
                name, file = self.overrides[action]
            elif original in self.resources.table:
                name = self.resources.table[original]
                file = self.resources.theme_file(name)
            elif action in self.unnamed:
                name, file = self.unnamed[action]
            else:
                name, file = "#%d (unnamed, not in the icon meta)" % original, None
            custom = self._custom_icon(file) if file is not None else None
            if custom is not None and ida_kernwin.update_action_icon(action, custom):
                self.replaced[action] = original
            elif (name, action) not in self.reported:
                missing.setdefault(name, []).append(action)
        if REPORT_MISSING_ICONS and missing:
            print("pwnbox: no theme icon for %d icons, IDA's kept: %s" % (len(missing), "; ".join(
                "%s (%s)" % (name, ", ".join(sorted(actions))) for name, actions in sorted(missing.items()))))
            self.reported.update((name, a) for name, actions in missing.items() for a in actions)

    def _custom_icon(self, file):
        if file not in self.loaded:
            custom = ida_kernwin.load_custom_icon(file)
            self.loaded[file] = custom if custom > 0 else None
            if custom > 0:
                self.custom_ids.add(custom)
        return self.loaded[file]

    def stop(self):
        """Give the actions back their original icons and free the theme's."""
        self.hooks.unhook()
        registered = set(ida_kernwin.get_registered_actions())
        for action, original in self.replaced.items():
            if action in registered:
                ida_kernwin.update_action_icon(action, original)
        for custom in self.loaded.values():
            if custom is not None:
                ida_kernwin.free_custom_icon(custom)
        self.replaced.clear()
        self.loaded.clear()
        self.custom_ids.clear()


class _ActionIconHooks(ida_kernwin.UI_Hooks):
    """Asks for a scan when IDA may have registered actions or changed their
    icons (IDA has no hook for a single action)."""

    def __init__(self, icons):
        super().__init__()
        self.icons = icons

    def updated_actions(self):
        self.icons.request_scan()

    def ready_to_run(self):
        self.icons.request_scan()

    def database_inited(self, is_new_database, idc_script):
        self.icons.request_scan()

    def plugin_loaded(self, plugin_info):
        self.icons.request_scan()

    def debugger_menu_change(self, enable):
        self.icons.request_scan()

    def widget_visible(self, widget):
        self.icons.request_scan()
