"""
Timing of the plugin's own work, printed to IDA's output window:

- startup steps and notes, right away
- any single call that takes at least PERF_SLOW_MS, as it happens
- every PERF_REPORT_MS, a summary per measured name since the last one
  (calls, total and longest time), busiest first; nothing when idle

Set PERF_ENABLED = False to turn it all off.
"""

import time
from contextlib import contextmanager

from PySide6.QtCore import QTimer

PERF_ENABLED = False
PERF_REPORT_MS = 5000
PERF_SLOW_MS = 16.0
PERF_PREFIX = "pwnbox perf:"


class Perf:
    def __init__(self):
        self.stats = {}
        self.timer = None

    @contextmanager
    def measure(self, name, report=False):
        """Time the block under `name`; `report` also prints it right away (startup steps)."""
        if not PERF_ENABLED:
            yield
            return
        start = time.perf_counter()
        try:
            yield
        finally:
            ms = (time.perf_counter() - start) * 1000
            stat = self.stats.setdefault(name, [0, 0.0, 0.0])
            stat[0] += 1
            stat[1] += ms
            stat[2] = max(stat[2], ms)
            if report:
                self.note("%s %.1f ms" % (name, ms))
            elif ms >= PERF_SLOW_MS:
                print("%s slow %s %.1f ms" % (PERF_PREFIX, name, ms))

    def note(self, text):
        if PERF_ENABLED:
            print(PERF_PREFIX, text)

    def start(self):
        if PERF_ENABLED and self.timer is None:
            self.timer = QTimer()
            self.timer.timeout.connect(self.report)
            self.timer.start(PERF_REPORT_MS)

    def stop(self):
        if self.timer is not None:
            self.timer.stop()
            self.timer = None

    def report(self):
        if not self.stats:
            return
        items = sorted(self.stats.items(), key=lambda item: -item[1][1])
        print(
            "%s last %ds: %s"
            % (
                PERF_PREFIX,
                PERF_REPORT_MS // 1000,
                "; ".join(
                    "%s %dx %.1f ms (max %.1f)" % (name, calls, total, longest)
                    for name, (calls, total, longest) in items
                ),
            )
        )
        self.stats.clear()


perf = Perf()
