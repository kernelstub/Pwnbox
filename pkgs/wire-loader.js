/* pwnbox theme loader for Wire Desktop.
 *
 * Wire's main process is a webpack CJS bundle. The shell (sidebar etc.) lives
 * in the main window, but the actual webapp runs in a remote <webview>, so
 * this loader injects into every webContents (web-contents-created catches
 * webview guests too) instead of only BrowserWindows.
 */
(function () {
  'use strict';
  try {
    var electron = require('electron');
    var fs = require('node:fs');
    var path = require('node:path');

    var app = electron.app;
    var webContents = electron.webContents;

    var cssPath = process.env.PWNBOX_WIRE_CSS
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

    var applyToWc = function (wc) {
      if (!wc || wc.isDestroyed()) return;
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
      } catch (e) {
        console.error('[pwnbox] wire css apply failed:', e);
      }
    };

    var applyAll = function () {
      var all = webContents.getAllWebContents();
      for (var i = 0; i < all.length; i += 1) applyToWc(all[i]);
    };

    app.whenReady().then(function () {
      applyAll();
      try {
        fs.watchFile(cssPath, { interval: 1000 }, function () { applyAll(); });
      } catch (e) {}
    });

    app.on('web-contents-created', function (_event, wc) {
      if (!wc) return;
      wc.on('dom-ready', function () { applyToWc(wc); });
      wc.on('did-finish-load', function () { applyToWc(wc); });
      applyToWc(wc);
    });

    console.log('[pwnbox] wire theme loader active:', cssPath);
  } catch (err) {
    console.error('[pwnbox] wire theme loader failed:', err);
  }
})();
