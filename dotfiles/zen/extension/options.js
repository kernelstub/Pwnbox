const statusEl = document.getElementById("status");
const enabledEl = document.getElementById("enabled");
const flatEl = document.getElementById("flatBorders");
const sitesEl = document.getElementById("sites");

function setStatus(text) {
    statusEl.textContent = text;
}

function timeAgo(ts) {
    if (!ts) return "never";
    const s = Math.round((Date.now() - ts) / 1000);
    return s < 60 ? s + "s ago" : Math.round(s / 60) + "min ago";
}

async function load() {
    const got = await browser.storage.local.get([
        "enabled",
        "flatBorders",
        "disabled",
        "sites",
        "version",
        "lastChecked",
        "lastError",
    ]);
    enabledEl.checked = got.enabled !== false;
    flatEl.checked = got.flatBorders !== false;
    const disabled = got.disabled || [];
    const sites = got.sites || [];

    sitesEl.textContent = "";
    if (!sites.length) {
        sitesEl.textContent =
            "no styles loaded yet — is the local server running?";
    }
    for (const site of sites) {
        const label = document.createElement("label");
        const cb = document.createElement("input");
        cb.type = "checkbox";
        cb.checked = !disabled.includes(site);
        cb.addEventListener("change", async () => {
            const cur =
                (await browser.storage.local.get(["disabled"])).disabled || [];
            const next = cb.checked
                ? cur.filter((s) => s !== site)
                : [...cur, site];
            await browser.storage.local.set({ disabled: next });
            setStatus(site + (cb.checked ? " enabled" : " disabled"));
        });
        label.appendChild(cb);
        label.appendChild(document.createTextNode(" " + site));
        sitesEl.appendChild(label);
    }

    let status =
        (sites.length
            ? sites.length + " themes, version " + (got.version || "?")
            : "no themes loaded") +
        " · last check " +
        timeAgo(got.lastChecked);
    if (got.lastError) status += " · error: " + got.lastError;
    setStatus(status);
    if (!got.version) {
        browser.runtime.sendMessage("pwnbox-refresh").then(() => load());
    }
}

enabledEl.addEventListener("change", async () => {
    await browser.storage.local.set({ enabled: enabledEl.checked });
    setStatus(enabledEl.checked ? "all themes enabled" : "all themes disabled");
});

flatEl.addEventListener("change", async () => {
    await browser.storage.local.set({ flatBorders: flatEl.checked });
    setStatus(flatEl.checked ? "flat borders on" : "flat borders off");
});

document.getElementById("refresh").addEventListener("click", async () => {
    setStatus("checking…");
    const version = await browser.runtime.sendMessage("pwnbox-refresh");
    setStatus("updated to version " + version);
    load();
});

document.getElementById("enableAll").addEventListener("click", async () => {
    await browser.storage.local.set({ disabled: [] });
    load();
    setStatus("all sites enabled");
});

load();
