{ tor-browser }:
tor-browser.override {
  extraPrefs = ''
    // pwnbox: pin Tor Browser to the Safest security level.  Pin the prefs
    // controlled by the slider as well, so a fresh profile starts at Safest
    // without first entering Tor Browser's "custom" state.
    //
    // Keep the controlled prefs below in sync with the Safest row of
    // kSecuritySettings in omni.ja/modules/SecurityLevel.sys.mjs.
    lockPref("browser.security_level.security_slider", 1);
    lockPref("browser.security_level.security_custom", false);
    lockPref("javascript.options.ion", false);
    lockPref("javascript.options.baselinejit", false);
    lockPref("javascript.options.native_regexp", false);
    lockPref("javascript.options.asmjs", false);
    lockPref("javascript.options.wasm", true); // NoScript still blocks wasm at Safest
    lockPref("mathml.disabled", true);
    lockPref("gfx.font_rendering.graphite.enabled", false);
    lockPref("gfx.font_rendering.opentype_svg.enabled", false);
    lockPref("svg.disabled", true);

    // Content engines that are common exploit surfaces.
    lockPref("javascript.enabled", false);
    lockPref("webgl.disabled", true);
    lockPref("webgl.enable-webgl2", false);
    lockPref("media.webaudio.enabled", false);
    lockPref("media.peerconnection.enabled", false);
    lockPref("media.navigator.enabled", false);
    lockPref("media.eme.enabled", false);
    lockPref("media.autoplay.default", 5);
    lockPref("media.autoplay.blocking_policy", 2);

    // Documents, popups and external protocol launches.
    lockPref("pdfjs.disabled", true);
    lockPref("pdfjs.enableScripting", false);
    lockPref("dom.disable_open_during_load", true);
    lockPref("dom.disable_window_move_resize", true);
    lockPref("dom.disable_window_flip", true);
    lockPref("dom.event.clipboardevents.enabled", false);
    lockPref("network.protocol-handler.external-default", false);
    lockPref("network.protocol-handler.warn-external-default", true);

    // Device and notification permissions are denied by default.
    lockPref("geo.enabled", false);
    lockPref("permissions.default.geo", 2);
    lockPref("permissions.default.camera", 2);
    lockPref("permissions.default.microphone", 2);
    lockPref("permissions.default.desktop-notification", 2);
    lockPref("dom.webnotifications.enabled", false);
    lockPref("dom.push.enabled", false);

    // No extension installs, remote debugging or DevTools chrome access.
    lockPref("xpinstall.enabled", false);
    lockPref("xpinstall.signatures.required", true);
    lockPref("extensions.pocket.enabled", false);
    lockPref("devtools.chrome.enabled", false);
    lockPref("devtools.debugger.remote-enabled", false);

    // Disable background network activity and unnecessary local state.
    lockPref("browser.cache.disk.enable", false);
    lockPref("browser.cache.offline.enable", false);
    lockPref("network.prefetch-next", false);
    lockPref("network.dns.disablePrefetch", true);
    lockPref("network.predictor.enabled", false);
    lockPref("network.http.speculative-parallel-limit", 0);
    lockPref("browser.safebrowsing.malware.enabled", false);
    lockPref("browser.safebrowsing.phishing.enabled", false);
    lockPref("browser.safebrowsing.downloads.remote.enabled", false);
    lockPref("browser.formfill.enable", false);
    lockPref("signon.rememberSignons", false);

    // Telemetry and crash uploads stay off even if the user changes prefs.
    lockPref("app.normandy.enabled", false);
    lockPref("app.shield.optoutstudies.enabled", false);
    lockPref("browser.ping-centre.telemetry", false);
    lockPref("browser.crashReports.unsubmittedCheck.enabled", false);
    lockPref("breakpad.reportURL", "");
    lockPref("datareporting.healthreport.uploadEnabled", false);
    lockPref("datareporting.policy.dataSubmissionEnabled", false);
    lockPref("toolkit.telemetry.enabled", false);
    lockPref("toolkit.telemetry.unified", false);
  '';
}
