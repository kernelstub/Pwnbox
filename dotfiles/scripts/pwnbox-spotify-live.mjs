#!/usr/bin/env node

import fs from "node:fs";

const userCssPath = process.argv[2];
const colorIniPath = process.argv[3];
if (!userCssPath || !colorIniPath) {
  console.error("usage: pwnbox-spotify-live.mjs <user.css> <color.ini>");
  process.exit(2);
}

function parseColorIni(text) {
  const out = {};
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith(";") || line.startsWith("#")) continue;
    if (/^\[.+\]$/.test(line)) continue;
    const eq = line.indexOf("=");
    if (eq < 0) continue;
    const k = line.slice(0, eq).trim();
    const v = line.slice(eq + 1).trim();
    if (k) out[k] = v;
  }
  return out;
}

const colors = parseColorIni(fs.readFileSync(colorIniPath, "utf8"));
const spiceKeys = [
  "main", "sidebar", "player", "card", "shadow", "selected-row",
  "button", "button-active", "button-disabled", "tab-active",
  "notification", "notification-error", "misc", "text", "subtext",
];
let root = ":root {\n";
for (const k of spiceKeys) {
  let v = colors[k];
  if (!v) continue;
  v = v.replace(/^#/, "");
  root += `  --spice-${k}: #${v} !important;\n`;
}
root += "}\n";

let userCss = "";
try {
  userCss = fs.readFileSync(userCssPath, "utf8");
} catch {

}
const css = root + "\n" + userCss;

const list = await (await fetch("http://localhost:9222/json/list")).json();
const page = list.find((t) => t.type === "page" && /spotify/i.test(t.url || ""));
if (!page) {
  console.error("pwnbox-spotify-live: no Spotify page on the debug port");
  process.exit(1);
}

const expr = `(() => {
  let s = document.getElementById('pwnbox-live');
  if (!s) { s = document.createElement('style'); s.id = 'pwnbox-live'; document.head.appendChild(s); }
  s.textContent = ${JSON.stringify(css)};
  return s.textContent.length;
})()`;

const ws = new WebSocket(page.webSocketDebuggerUrl);
const timer = setTimeout(() => {
  console.error("pwnbox-spotify-live: timeout");
  process.exit(1);
}, 6000);

ws.onopen = () =>
  ws.send(JSON.stringify({
    id: 1,
    method: "Runtime.evaluate",
    params: { expression: expr, returnByValue: true },
  }));

ws.onmessage = (event) => {
  const d = JSON.parse(event.data);
  if (d.id !== 1) return;
  clearTimeout(timer);
  if (d.result?.exceptionDetails) {
    console.error("pwnbox-spotify-live:", JSON.stringify(d.result.exceptionDetails).slice(0, 300));
    process.exit(1);
  }
  console.log("injected", d.result?.result?.value ?? "");
  process.exit(0);
};

ws.onerror = () => {
  console.error("pwnbox-spotify-live: websocket error");
  process.exit(1);
};
