let styleEl = null;
let appliedVersion = null;

function matchCond(cond, href) {
    const url = new URL(href);
    for (const part of cond.split(",")) {
        const s = part.trim();
        const m = s.match(/^([a-z-]+)\((.*)\)$/s);
        if (!m) continue;
        const kind = m[1];
        const arg = m[2].trim().replace(/^"|"$/g, "");
        let ok = false;
        switch (kind) {
            case "domain": {
                const host = url.hostname;
                ok = host === arg || host.endsWith("." + arg);
                break;
            }
            case "url-prefix":
                ok = href.startsWith(arg);
                break;
            case "url":
                ok = href === arg;
                break;
            case "regexp":
                try {
                    ok = new RegExp(arg).test(href);
                } catch (e) {
                    ok = false;
                }
                break;
            default:
                ok = false;
        }
        if (ok) return true;
    }
    return false;
}

function setCss(text) {
    if (!styleEl) {
        styleEl = document.createElement("style");
        styleEl.id = "pwnbox-styles";
        (document.head || document.documentElement).appendChild(styleEl);
    }
    styleEl.textContent = text;
}

function clearCss() {
    if (styleEl) {
        styleEl.remove();
        styleEl = null;
    }
}

async function computeAndApply() {
    const got = await browser.storage.local.get([
        "sections",
        "enabled",
        "flatBorders",
        "disabled",
        "border",
        "outline",
        "font",
    ]);
    if (got.enabled === false) {
        clearCss();
        return;
    }
    const disabled = got.disabled || [];
    let out = "";
    for (const s of got.sections || []) {
        if (disabled.includes(s.name)) continue;
        for (const b of s.blocks || []) {
            if (matchCond(b.cond, location.href)) out += b.css + "\n";
        }
    }
    if (got.flatBorders !== false && got.border && got.outline) {
        out += `* { border-color: ${got.border} !important; outline-color: ${got.outline} !important; }\n`;
    }
    if (got.font) {
        out += `* { font-family: ${JSON.stringify(got.font)}, monospace !important; }\n`;
    }
    if (out) setCss(out);
    else clearCss();
}

function applyFromBackground(reply) {
    if (!reply || !reply.sections) return;
    appliedVersion = reply.version;
    const sections = reply.sections;
    const originalGet = () =>
        browser.storage.local
            .get([
                "enabled",
                "flatBorders",
                "disabled",
                "border",
                "outline",
                "font",
            ])
            .then((got) => {
                if (got.enabled === false) {
                    clearCss();
                    return;
                }
                const disabled = got.disabled || [];
                let out = "";
                for (const s of sections) {
                    if (disabled.includes(s.name)) continue;
                    for (const b of s.blocks || []) {
                        if (matchCond(b.cond, location.href))
                            out += b.css + "\n";
                    }
                }
                if (got.flatBorders !== false && got.border && got.outline) {
                    out += `* { border-color: ${got.border} !important; outline-color: ${got.outline} !important; }\n`;
                }
                if (got.font) {
                    out += `* { font-family: ${JSON.stringify(got.font)}, monospace !important; }\n`;
                }
                if (out) setCss(out);
                else clearCss();
            });
    originalGet();
}

computeAndApply();
browser.runtime
    .sendMessage("pwnbox-need-blocks")
    .then(applyFromBackground)
    .catch(() => {});
setInterval(() => {
    browser.runtime
        .sendMessage("pwnbox-need-blocks")
        .then((reply) => {
            if (reply && reply.version && reply.version !== appliedVersion) {
                applyFromBackground(reply);
            }
        })
        .catch(() => {});
}, 30000);

browser.storage.onChanged.addListener((changes) => {
    if (
        changes.sections ||
        changes.enabled ||
        changes.flatBorders ||
        changes.disabled ||
        changes.border ||
        changes.outline
    ) {
        computeAndApply();
    }
});
