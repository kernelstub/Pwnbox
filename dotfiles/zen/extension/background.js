const BASE = "http://localhost:8311/";
let currentVersion = null;
let pending = null;

const DEFAULTS = { enabled: true, flatBorders: true, disabled: [] };

async function initDefaults() {
    const got = await browser.storage.local.get([
        "enabled",
        "flatBorders",
        "disabled",
    ]);
    const set = {};
    if (got.enabled === undefined) set.enabled = DEFAULTS.enabled;
    if (got.flatBorders === undefined) set.flatBorders = DEFAULTS.flatBorders;
    if (got.disabled === undefined) set.disabled = DEFAULTS.disabled;
    if (Object.keys(set).length) await browser.storage.local.set(set);
}

function parseBlocks(css) {
    const blocks = [];
    const re = /@-moz-document\s+([^{]+)\{/g;
    const positions = [];
    let m;
    while ((m = re.exec(css)) !== null) {
        positions.push({ cond: m[1].trim(), start: re.lastIndex });
    }
    for (const p of positions) {
        let depth = 1;
        let k = p.start;
        while (k < css.length && depth > 0) {
            if (css[k] === "{") depth++;
            else if (css[k] === "}") depth--;
            k++;
        }
        blocks.push({ cond: p.cond, css: css.slice(p.start, k - 1) });
    }
    return blocks;
}

function parseSections(css) {
    const sections = [];
    const re = /\/\* ==UserStyle==[\s\S]*?==\/UserStyle== \*\//g;
    const positions = [];
    let m;
    while ((m = re.exec(css)) !== null) positions.push(m.index + m[0].length);
    positions.push(css.length);
    for (let i = 0; i < positions.length - 1; i++) {
        const chunk = css.slice(positions[i], positions[i + 1]);
        const nameMatch = chunk.match(/@name\s+([^\n]+)/);
        const name = nameMatch ? nameMatch[1].trim() : "style-" + i;
        sections.push({ name, blocks: parseBlocks(chunk) });
    }
    return sections;
}

async function check() {
    let lastError = "";
    try {
        const res = await fetch(BASE + "version.txt", { cache: "no-store" });
        if (!res.ok) throw new Error("version.txt HTTP " + res.status);
        const version = (await res.text()).trim();
        if (version !== currentVersion) {
            const cssRes = await fetch(BASE + "pwnbox-all.user.css", {
                cache: "no-store",
            });
            if (!cssRes.ok) throw new Error("css HTTP " + cssRes.status);
            const css = await cssRes.text();
            const sections = parseSections(css);
            await browser.storage.local.set({
                sections,
                sites: sections.map((s) => s.name),
                version,
            });
            currentVersion = version;
        }
        const themeRes = await fetch(BASE + "theme.json", {
            cache: "no-store",
        });
        if (themeRes.ok) {
            const theme = await themeRes.json();
            const got = await browser.storage.local.get([
                "border",
                "outline",
                "font",
            ]);
            if (
                got.border !== theme.border ||
                got.outline !== theme.outline ||
                got.font !== theme.font
            ) {
                await browser.storage.local.set({
                    border: theme.border,
                    outline: theme.outline,
                    font: theme.font,
                });
            }
        }
    } catch (e) {
        lastError = String(e && e.message ? e.message : e);
        throw e;
    } finally {
        browser.storage.local
            .set({ lastChecked: Date.now(), lastError })
            .catch(() => {});
    }
}

function ensure() {
    if (!pending) {
        pending = check()
            .catch(() => {})
            .finally(() => {
                pending = null;
            });
    }
    return pending;
}

initDefaults().then(ensure);
setInterval(ensure, 30000);

browser.runtime.onMessage.addListener((msg, sender, reply) => {
    if (msg === "pwnbox-need-blocks") {
        ensure()
            .then(() =>
                browser.storage.local.get([
                    "sections",
                    "lastChecked",
                    "lastError",
                ]),
            )
            .then(({ sections, lastChecked, lastError }) =>
                reply({
                    sections: sections || [],
                    version: currentVersion,
                    lastChecked,
                    lastError,
                }),
            );
        return true;
    }
    if (msg === "pwnbox-refresh") {
        pending = null;
        ensure()
            .then(() => browser.storage.local.get(["version"]))
            .then(({ version }) => reply(version || ""));
        return true;
    }
});
