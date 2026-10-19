(function () {
  'use strict';
  try {
    var electron = require('electron');
    var fs = require('node:fs');
    var path = require('node:path');

    var app = electron.app;
    var BrowserWindow = electron.BrowserWindow;

    var cssPath = process.env.PWNBOX_SIGNAL_CSS
      || path.join(app.getPath('userData'), 'theme.css');

    var readCss = function () {
      try {
        var css = fs.readFileSync(cssPath, 'utf8');
        return css && css.trim() ? css : '';
      } catch (e) {
        return '';
      }
    };

    var inserted = new WeakMap();

    var applyToWin = function (win) {
      if (!win || win.isDestroyed()) return;
      var wc = win.webContents;
      var css = readCss();
      if (!css) return;

      var oldKey = inserted.get(wc);
      if (oldKey !== undefined) {
        try { wc.removeInsertedCSS(oldKey); } catch (e) {}
      }

      try {
        var key = wc.insertCSS(css, { cssOrigin: 'author' });
        if (typeof key === 'string' || typeof key === 'number') {
          inserted.set(wc, key);
        }
        var m = css.match(/--axo-color-surface-primary:\s*#?([0-9a-fA-F]{6})/);
        if (m) {
          try { win.setBackgroundColor('#' + m[1]); } catch (e) {}
        }
      } catch (e) {
        console.error('[pwnbox] signal css apply failed:', e);
      }
    };

    var applyAll = function () {
      var wins = BrowserWindow.getAllWindows();
      for (var i = 0; i < wins.length; i += 1) applyToWin(wins[i]);
    };

    app.whenReady().then(function () {
      applyAll();
      try {
        fs.watchFile(cssPath, { interval: 1000 }, function () { applyAll(); });
      } catch (e) {}
    });

    app.on('browser-window-created', function (_event, win) {
      if (win && win.webContents) {
        win.webContents.on('did-finish-load', function () { applyToWin(win); });
      }
      applyToWin(win);
    });

    console.log('[pwnbox] signal theme loader active:', cssPath);
  } catch (err) {
    console.error('[pwnbox] signal theme loader failed:', err);
  }
})();
