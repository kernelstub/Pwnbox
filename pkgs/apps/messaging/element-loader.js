/* pwnbox theme loader for Element Desktop.
 *
 * Element's main process is ESM (`"type": "module"`), so this uses dynamic
 * imports and top-level await instead of require(). It mirrors
 * pkgs/apps/messaging/signal-loader.js: read ~/.config/Element/theme.css (or
 * PWNBOX_ELEMENT_CSS), inject it into every renderer and watch the file so
 * theme changes apply live.
 */
try {
  const electronMod = await import('electron');
  const pwnboxFs = await import('node:fs');
  const pwnboxPath = await import('node:path');

  const app = electronMod.app;
  const BrowserWindow = electronMod.BrowserWindow;

  const cssPath =
    process.env.PWNBOX_ELEMENT_CSS ||
    pwnboxPath.default.join(app.getPath('userData'), 'theme.css');

  const readCss = () => {
    try {
      const css = pwnboxFs.default.readFileSync(cssPath, 'utf8');
      return css && css.trim() ? css : '';
    } catch (e) {
      return '';
    }
  };

  const inserted = new WeakMap();

  const applyToWin = (win) => {
    if (!win || win.isDestroyed()) return;
    const wc = win.webContents;
    const css = readCss();
    if (!css) return;

    const oldKey = inserted.get(wc);
    if (oldKey !== undefined) {
      try {
        wc.removeInsertedCSS(oldKey);
      } catch (e) {}
    }

    try {
      const key = wc.insertCSS(css, { cssOrigin: 'author' });
      if (typeof key === 'string' || typeof key === 'number') {
        inserted.set(wc, key);
      }
      const m = css.match(/--cpd-color-bg-canvas-default:\s*#?([0-9a-fA-F]{6})/);
      if (m) {
        try {
          win.setBackgroundColor('#' + m[1]);
        } catch (e) {}
      }
    } catch (e) {
      console.error('[pwnbox] element css apply failed:', e);
    }
  };

  const applyAll = () => {
    const wins = BrowserWindow.getAllWindows();
    for (let i = 0; i < wins.length; i += 1) applyToWin(wins[i]);
  };

  app.whenReady().then(() => {
    applyAll();
    try {
      pwnboxFs.default.watchFile(cssPath, { interval: 1000 }, () => {
        applyAll();
      });
    } catch (e) {}
  });

  app.on('browser-window-created', (_event, win) => {
    if (win && win.webContents) {
      win.webContents.on('did-finish-load', () => {
        applyToWin(win);
      });
    }
    applyToWin(win);
  });

  console.log('[pwnbox] element theme loader active:', cssPath);
} catch (err) {
  console.error('[pwnbox] element theme loader failed:', err);
}
