const statusEl = document.getElementById("status");
const enabledEl = document.getElementById("enabled");
const flatEl = document.getElementById("flat");

async function load() {
    const got = await browser.storage.local.get([
        "enabled",
        "flatBorders",
        "version",
        "lastChecked",
        "lastError",
    ]);
    enabledEl.checked = got.enabled !== false;
    flatEl.checked = got.flatBorders !== false;
    let status = "version " + (got.version || "?");
    if (got.lastChecked) {
        const s = Math.round((Date.now() - got.lastChecked) / 1000);
        status +=
            " · " + (s < 60 ? s + "s ago" : Math.round(s / 60) + "min ago");
    }
    if (got.lastError) status += " · error";
    statusEl.textContent = status;
}

enabledEl.addEventListener("change", () => {
    browser.storage.local.set({ enabled: enabledEl.checked });
});

flatEl.addEventListener("change", () => {
    browser.storage.local.set({ flatBorders: flatEl.checked });
});

document.getElementById("options").addEventListener("click", () => {
    browser.runtime.openOptionsPage();
    window.close();
});

load();
