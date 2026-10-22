import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import "Theme.js" as Theme

PanelWindow {
    id: center
    property bool open: false
    property string section: "quick"
    property var homeScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property bool dnd: false
    property var notifModel: null
    property var stats: ({})
    property string pendingSsid: ""
    property bool recording: false
    property string scale: "100"
    property string monitors: ""
    property var captureMonitors: []
    property string pendingCapture: ""
    property int captureDelay: 0
    readonly property var monitorOutputs: captureMonitors ? captureMonitors.filter(function (m) { return !m.disabled }) : []
    property string stateBarstyle: ""
    property string stateFontUi: ""
    property string stateAppFont: ""
    property string stateFontUiSize: ""
    property string stateAppFontSize: ""
    property string stateRadius: ""
    property string stateUiRadius: ""
    property string stateBlur: ""
    property string stateOpacity: ""
    property string stateAnim: ""
    property string stateBorders: ""
    property string stateShadows: ""
    property string stateCustom: ""
    property string stateWallpaper: ""
    property string homeDir: ""
    property string netInfo: ""
    property var clipItems: []
    signal dndToggled(bool value)
    signal openChangedTo(bool value)

    readonly property var batt: UPower.displayDevice
    readonly property bool batteryPresent: batt !== null && batt.isLaptopBattery
    readonly property int batteryState: batteryPresent ? batt.state : UPowerDeviceState.Unknown
    readonly property bool batteryCharging: batteryState === UPowerDeviceState.Charging || batteryState === UPowerDeviceState.PendingCharge
    readonly property bool batteryFull: batteryState === UPowerDeviceState.FullyCharged
    readonly property bool batteryPlugged: batteryCharging || batteryFull
    readonly property string batteryIcon: batteryCharging ? Theme.iconCharging
        : batteryFull ? Theme.iconBattery
        : (batt && batt.percentage > 0.5 ? Theme.iconBattery : Theme.iconBatteryHalf)
    readonly property string batteryLabel: batteryCharging ? "Charging"
        : batteryFull ? "Fully charged"
        : "Battery"
    readonly property string batteryText: Math.round((batt ? batt.percentage : 0) * 100) + "%"
    readonly property real batteryFraction: batt ? (batt.percentage || 0) : 0

    property int brightCur: 0
    property int brightMax: 0
    readonly property bool brightAvailable: brightMax > 0
    readonly property real brightFraction: brightMax > 0 ? Math.min(1, brightCur / brightMax) : 0

    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool wifiAvailable: Networking.wifiHardwareEnabled
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btAvailable: btAdapter !== null
    readonly property bool btOn: btAdapter !== null && btAdapter.enabled

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property real defaultSinkVolume: (defaultSink && defaultSink.audio) ? defaultSink.audio.volume : 0
    readonly property bool defaultSinkMuted: (defaultSink && defaultSink.audio) ? defaultSink.audio.muted : false

    readonly property var player: {
        const list = Mpris.players.values;
        if (!list || list.length === 0)
            return null;
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying)
                return list[i];
        }
        return list[0] || null;
    }
    readonly property bool mediaActive: player !== null && player !== undefined
        && (player.trackTitle || "").length > 0

    readonly property var navItems: [
        { key: "quick", label: "Quick Settings", glyph: Theme.iconSettings },
        { key: "power", label: "Power", glyph: Theme.iconBattery },
        { key: "network", label: "Network", glyph: Theme.iconWifi },
        { key: "bluetooth", label: "Bluetooth", glyph: Theme.iconBluetooth },
        { key: "volume", label: "Volume", glyph: Theme.iconVolume },
        { key: "display", label: "Display", glyph: Theme.iconDisplay },
        { key: "theme", label: "Theme", glyph: Theme.iconPalette || "\uf1fc" },
        { key: "system", label: "System", glyph: Theme.iconCpu },
        { key: "clipboard", label: "Clipboard", glyph: Theme.iconClipboard || "\uf0ea" },
        { key: "calendar", label: "Calendar", glyph: Theme.iconCalendar },
        { key: "media", label: "Now Playing", glyph: Theme.iconMusic },
        { key: "capture", label: "Capture", glyph: Theme.iconCrop || "\uf125" },
        { key: "notifications", label: "Notifications", glyph: Theme.iconBell },
        { key: "session", label: "Session", glyph: Theme.iconPower }
    ]

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Process {
        id: proc
        command: ["sh", "-c", "$HOME/.scripts/status"]
        stdout: StdioCollector {
            onStreamFinished: center.stats = parseStats(this.text)
        }
    }
    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | head -1 | awk -F, '{print $3, $5}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/);
                if (p.length >= 2) {
                    center.brightCur = parseInt(p[0]) || 0;
                    center.brightMax = parseInt(p[1]) || 0;
                }
            }
        }
    }
    Process {
        id: brightSet
        command: ["true"]
    }
    Process {
        id: runner
        command: ["true"]
    }

    Timer {
        id: captureTimer
        interval: center.captureDelay > 0 ? center.captureDelay
            : (center.stateAnim === "off" ? 80 : 350)
        onTriggered: {
            if (center.pendingCapture === "")
                return;
            runner.command = ["sh", "-c", center.pendingCapture];
            runner.startDetached();
            center.pendingCapture = "";
            center.captureDelay = 0;
        }
    }

    Process {
        id: audioProc
        command: ["true"]
    }

    Process {
        id: monitorProc
        command: ["sh", "-c", "hyprctl monitors -j | jq -r '.[] | [.name, (.width|tostring) + \"x\" + (.height|tostring) + \"@\" + (.refreshRate|tostring) + \"Hz\", (.scale|tostring) + \"x\"] | join(\"  \")'"]
        stdout: StdioCollector {
            onStreamFinished: center.monitors = this.text.trim()
        }
    }

    Process {
        id: captureMonitorProc
        command: ["sh", "-c", "hyprctl monitors -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    center.captureMonitors = JSON.parse(this.text.trim());
                } catch (e) {
                    center.captureMonitors = [];
                }
            }
        }
    }

    Process {
        id: themeStateProc
        command: ["sh", "-c", "d=\"$HOME/.cache/pwnbox/theme\"; for f in barstyle font-ui font-app font-size-ui font-size-app radius-window radius-ui blur opacity animations borders shadows custom-theme wallpaper; do printf '%s=%s\\n' \"$f\" \"$(cat \"$d/$f\" 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                const lines = this.text.trim().split(/\n/);
                for (let i = 0; i < lines.length; i++) {
                    const eq = lines[i].indexOf("=");
                    if (eq > 0)
                        out[lines[i].slice(0, eq)] = lines[i].slice(eq + 1);
                }
                center.stateBarstyle = out.barstyle || "";
                center.stateFontUi = out["font-ui"] || "";
                center.stateAppFont = out["font-app"] || "";
                center.stateFontUiSize = out["font-size-ui"] || "";
                center.stateAppFontSize = out["font-size-app"] || "";
                center.stateRadius = out["radius-window"] || "";
                center.stateUiRadius = out["radius-ui"] || "";
                center.stateBlur = out.blur || "";
                center.stateOpacity = out.opacity || "";
                center.stateAnim = out.animations || "";
                center.stateBorders = out.borders || "";
                center.stateShadows = out.shadows || "";
                center.stateCustom = out["custom-theme"] || "";
                center.stateWallpaper = out.wallpaper || "";
            }
        }
    }

    Process {
        id: homeProc
        command: ["sh", "-c", "printf '%s' \"$HOME\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: center.homeDir = this.text.trim()
        }
    }

    Process {
        id: netProc
        command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,FREQ,BSSID dev wifi list 2>/dev/null | grep '^\\*' | head -1; ip -4 -o addr show 2>/dev/null | grep 'scope global' | head -1; ip route 2>/dev/null | grep '^default' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split(/\n/);
                const out = [];
                if (lines[0]) {
                    const p = lines[0].split(":");
                    if (p.length >= 6) {
                        out.push("SSID: " + (p[1] || "?"));
                        out.push("Signal: " + (p[2] || "?") + "%");
                        out.push("Security: " + (p[3] || "?"));
                        out.push("Frequency: " + (p[4] || "?"));
                        out.push("BSSID: " + (p[5] || "?"));
                    }
                }
                if (lines[1]) {
                    const m = lines[1].match(/inet ([0-9.]+)/);
                    if (m) out.push("IP: " + m[1]);
                }
                if (lines[2]) {
                    const m = lines[2].match(/via ([0-9.]+)/);
                    if (m) out.push("Gateway: " + m[1]);
                }
                center.netInfo = out.join("\n");
            }
        }
    }

    Process {
        id: clipRead
        command: ["sh", "-c", "cliphist list 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const items = [];
                const lines = this.text.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (!line.trim()) continue;
                    const tab = line.indexOf("\t");
                    const id = tab > 0 ? line.slice(0, tab) : line.trim();
                    const preview = tab > 0 ? line.slice(tab + 1) : "";
                    items.push({ id: id, preview: preview });
                }
                items.sort((a, b) => (parseInt(b.id) || 0) - (parseInt(a.id) || 0));
                center.clipItems = items;
            }
        }
    }

    Process {
        id: clipProc
        command: ["true"]
        onExited: clipRead.running = true
    }
    Process {
        id: clipEditProc
        command: ["true"]
        onExited: clipRead.running = true
    }
    Process {
        id: scaleProc
        command: ["true"]
    }
    Process {
        id: scaleRead
        command: ["sh", "-c", "cat \"$HOME/.cache/pwnbox/theme/scale\" 2>/dev/null || echo 100"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = this.text.trim();
                if (s.length > 0)
                    center.scale = s;
            }
        }
    }
    Process {
        id: recCheck
        command: ["sh", "-c", "test -f \"${XDG_RUNTIME_DIR:-/tmp}/pwnbox-record.pid\""]
        onExited: {
            if (center.open)
                center.recording = exitCode === 0;
        }
    }

    Timer {
        interval: 2000
        running: center.open
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            proc.running = true;
            brightProc.running = true;
            themeStateProc.running = true;
            netProc.running = true;
            center.recording = false;
            recCheck.running = true;
            captureMonitorProc.running = true;
        }
    }

    onSectionChanged: {
        if (section === "display") {
            scaleRead.running = true;
            monitorProc.running = true;
        }
        if (section === "clipboard")
            clipRead.running = true;
        if (section === "capture")
            captureMonitorProc.running = true;
    }

    function parseStats(text) {
        const out = {};
        const parts = text.trim().split(/\s+/);
        for (let i = 0; i < parts.length; i++) {
            const eq = parts[i].indexOf("=");
            if (eq > 0)
                out[parts[i].slice(0, eq)] = parts[i].slice(eq + 1);
        }
        return out;
    }

    function rgba(hex, alpha) {
        const r = parseInt(hex.slice(1, 3), 16) / 255;
        const g = parseInt(hex.slice(3, 5), 16) / 255;
        const b = parseInt(hex.slice(5, 7), 16) / 255;
        return Qt.rgba(r, g, b, alpha);
    }

    function setBrightness(v) {
        const target = Math.max(1, Math.round(v * center.brightMax));
        center.brightCur = target;
        brightSet.command = ["sh", "-c", "brightnessctl set " + target];
        brightSet.startDetached();
    }

    function setScale(pct) {
        center.scale = String(pct);
        scaleProc.command = ["sh", "-c", "$HOME/.scripts/pwnbox-theme setscale " + pct];
        scaleProc.startDetached();
    }

    function setDefaultAudio(node) {
        if (!node || node.id === undefined || node.id === null)
            return;
        audioProc.command = ["sh", "-c", "wpctl set-default " + node.id];
        audioProc.startDetached();
    }

    function setVolume(v) {
        if (defaultSink && defaultSink.audio) {
            defaultSink.audio.volume = v;
            if (defaultSink.audio.muted)
                defaultSink.audio.muted = false;
        }
    }

    function clipCopy(id) {
        clipProc.command = ["sh", "-c", "cliphist decode " + id + " | wl-copy"];
        clipProc.startDetached();
    }

    function clipDelete(id, preview) {
        const line = String(id) + "\t" + (preview || "");
        clipEditProc.command = [
            "sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "sh", line
        ];
        clipEditProc.running = true;
    }

    function clipClearAll() {
        clipEditProc.command = ["cliphist", "wipe"];
        clipEditProc.running = true;
    }

    function run(cmd) {
        center.open = false;
        openChangedTo(false);
        runner.command = ["sh", "-c", cmd];
        runner.startDetached();
    }

    function runCapture(cmd, delay) {
        center.pendingCapture = cmd;
        center.captureDelay = delay === undefined ? 0 : delay;
        center.open = false;
        openChangedTo(false);
        captureTimer.restart();
    }

    function clearAll() {
        if (!center.notifModel)
            return;
        const values = center.notifModel.values;
        for (let i = values.length - 1; i >= 0; i--) {
            if (values[i] && values[i].dismiss)
                values[i].dismiss();
        }
    }

    function close() {
        open = false;
        openChangedTo(false);
    }
    function toggleSection(s) {
        if (open && section === s) {
            close();
        } else {
            section = s;
            open = true;
            openChangedTo(true);
        }
    }

    IpcHandler {
        target: "controlcenter"
        function toggle() {
            if (center.open)
                center.close();
            else {
                center.open = true;
                center.openChangedTo(true);
            }
        }
        function open(s: string) {
            center.section = s;
            center.open = true;
            center.openChangedTo(true);
        }
        function close() { center.close(); }
    }
    IpcHandler {
        target: "calendar"
        function toggle() { center.toggleSection("calendar"); }
        function toggleAt(x: int) { center.toggleSection("calendar"); }
        function close() { center.close(); }
    }
    IpcHandler {
        target: "systempanel"
        function toggle() { center.toggleSection("system"); }
        function toggleAt(x: int) { center.toggleSection("system"); }
        function close() { center.close(); }
    }
    IpcHandler {
        target: "networkpanel"
        function toggle() { center.toggleSection("network"); }
        function toggleAt(x: int) { center.toggleSection("network"); }
        function close() { center.close(); }
    }
    IpcHandler {
        target: "bluetoothpanel"
        function toggle() { center.toggleSection("bluetooth"); }
        function toggleAt(x: int) { center.toggleSection("bluetooth"); }
        function close() { center.close(); }
    }
    IpcHandler {
        target: "mixer"
        function toggle() { center.toggleSection("volume"); }
        function toggleAt(x: int) { center.toggleSection("volume"); }
        function close() { center.close(); }
    }
    IpcHandler {
        target: "powermenu"
        function toggle() { center.toggleSection("session"); }
        function toggleAt(x: int) { center.toggleSection("session"); }
        function close() { center.close(); }
    }
    IpcHandler {
        target: "screenshot"
        function toggle() { center.toggleSection("capture"); }
        function toggleAt(x: int) { center.toggleSection("capture"); }
        function close() { center.close(); }
    }
    IpcHandler {
        target: "notifcenter"
        function toggle() { center.toggleSection("notifications"); }
        function toggleAt(x: int) { center.toggleSection("notifications"); }
        function close() { center.close(); }
        function getCount(): int {
            return center.notifModel ? center.notifModel.values.length : 0;
        }
        function isDnd(): bool {
            return center.dnd;
        }
    }

    visible: open
    screen: homeScreen
    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    implicitWidth: Math.min(1240, homeScreen ? homeScreen.width - 80 : 1240)
    implicitHeight: Math.min(820, homeScreen ? homeScreen.height - 80 : 820)

    HyprlandFocusGrab {
        windows: [center]
        active: center.open
        onCleared: if (center.open) center.close()
    }

    Shortcut {
        sequence: "Escape"
        enabled: center.open
        onActivated: center.close()
    }

    component SectionTitle: Text {
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 0.6
        topPadding: 8
    }

    component ToggleRow: Rectangle {
        id: tw
        required property string label
        required property string glyph
        required property bool active
        property bool available: true
        signal toggled()

        width: parent.width
        height: 36
        radius: Theme.radius - 2
        color: twMouse.containsMouse ? Theme.bgAltA : "transparent"
        Behavior on color { ColorAnimation { duration: 130 } }
        opacity: available ? 1.0 : 0.5

        Text {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text: tw.glyph
            color: tw.active ? Theme.fg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 13
        }
        Text {
            anchors { left: parent.left; leftMargin: 32; verticalCenter: parent.verticalCenter }
            text: tw.label
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
        Text {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            text: !tw.available ? "unavailable" : tw.active ? "on" : "off"
            color: tw.active ? Theme.fg : Theme.fgFaint
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.letterSpacing: 0.5
        }
        MouseArea {
            id: twMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: tw.available
            cursorShape: Qt.PointingHandCursor
            onClicked: tw.toggled()
        }
    }

    component ActionRow: Rectangle {
        id: ar
        required property string label
        required property string glyph
        property bool danger: false
        property string value: ""
        signal activated()

        width: parent.width
        height: 38
        radius: Theme.radius - 2
        color: arMouse.containsMouse ? Theme.bgAltA : "transparent"
        Behavior on color { ColorAnimation { duration: 130 } }

        Text {
            id: arIcon
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            text: ar.glyph
            color: ar.danger ? Theme.red : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 13
        }
        Text {
            anchors { left: arIcon.right; leftMargin: 12; right: parent.right; rightMargin: 120; verticalCenter: parent.verticalCenter }
            text: ar.label
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
        }
        Text {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            text: ar.value
            color: Theme.fgFaint
            font.family: Theme.fontFamily
            font.pixelSize: 10
            visible: ar.value.length > 0
        }
        MouseArea {
            id: arMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ar.activated()
        }
    }

    component StatRow: Item {
        id: sr
        required property string label
        required property string value
        required property string glyph
        required property real fraction

        width: parent.width
        height: 26

        Text {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: sr.glyph
            color: Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 11
        }
        Text {
            anchors { left: parent.left; leftMargin: 26; verticalCenter: parent.verticalCenter }
            text: sr.label
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        Text {
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            text: sr.value
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        Rectangle {
            anchors { left: parent.left; leftMargin: 26; right: parent.right; rightMargin: 4; bottom: parent.bottom }
            height: 4
            radius: 2
            color: Theme.brdr
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, sr.fraction))
                height: parent.height
                radius: parent.radius
                color: Theme.fg
            }
        }
    }

    component InfoRow: Item {
        id: ir
        required property string label
        required property string value
        required property string glyph

        width: parent.width
        height: 22

        Text {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: ir.glyph
            color: Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 11
        }
        Text {
            anchors { left: parent.left; leftMargin: 26; verticalCenter: parent.verticalCenter }
            text: ir.label
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        Text {
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            text: ir.value
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    component NodeRow: Rectangle {
        id: row
        required property var node
        required property string glyph

        readonly property bool hasAudio: node && node.audio !== null && node.audio !== undefined
        readonly property real vol: hasAudio ? node.audio.volume : 0
        readonly property bool muted: hasAudio ? node.audio.muted : false
        readonly property bool isDefault: node === Pipewire.defaultAudioSink || node === Pipewire.defaultAudioSource
        readonly property bool isStream: node ? (node.isStream === true) : false
        readonly property string label: node ? (node.description || node.name || "device") : "device"

        width: parent.width
        implicitHeight: 38
        radius: Theme.radius - 2
        color: "transparent"

        Text {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: row.glyph
            color: row.isDefault ? Theme.fg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 12
            width: 16
        }
        Text {
            anchors {
                left: parent.left; leftMargin: 26; right: parent.right; rightMargin: 46
                verticalCenter: parent.verticalCenter
            }
            text: row.label
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 10
            elide: Text.ElideRight
        }
        Text {
            anchors { right: parent.right; rightMargin: 44; verticalCenter: parent.verticalCenter }
            text: Theme.iconCheck
            color: Theme.fg
            font.family: Theme.fontIcons
            font.pixelSize: 10
            visible: row.isDefault
        }
        Text {
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            text: row.muted ? "mute" : Math.round(row.vol * 100) + "%"
            color: row.muted ? Theme.fg : Theme.fgFaint
            font.family: Theme.fontFamily
            font.pixelSize: 9
            width: 36
            horizontalAlignment: Text.AlignRight
        }
        SliderBar {
            anchors {
                left: parent.left; leftMargin: 26; right: parent.right; rightMargin: 46
                bottom: parent.bottom; bottomMargin: 4
            }
            value: row.muted ? 0 : row.vol
            enabled: row.hasAudio && !row.muted
            onMoved: v => {
                if (row.hasAudio) {
                    row.node.audio.volume = v;
                    if (row.muted)
                        row.node.audio.muted = false;
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {
                if (row.isStream) {
                    if (row.hasAudio)
                        row.node.audio.muted = !row.node.audio.muted;
                } else {
                    center.setDefaultAudio(row.node);
                }
            }
        }
    }

    component ScaleButton: Rectangle {
        id: sb
        required property string label
        property bool active: false
        signal clicked()

        implicitWidth: 110
        implicitHeight: 42
        radius: Theme.radius - 2
        color: sb.active ? Theme.accent : (sbMouse.containsMouse ? Theme.bgAltA : Theme.bgA)
        Behavior on color { ColorAnimation { duration: 130 } }
        border.color: Theme.brdr
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: sb.label
            color: sb.active ? Theme.fg : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: sb.active ? Font.Bold : Font.Normal
        }
        MouseArea {
            id: sbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: sb.clicked()
        }
    }

    component NavItem: Rectangle {
        id: nav
        required property string label
        required property string glyph
        required property bool active
        signal clicked()

        width: parent.width
        height: 44
        radius: Theme.radius - 2
        color: nav.active ? Theme.accent : (navMouse.containsMouse ? Theme.bgAltA : "transparent")
        Behavior on color { ColorAnimation { duration: 130 } }

        Text {
            anchors.centerIn: parent
            text: nav.glyph
            color: nav.active ? Theme.fg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 17
        }
        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.clicked()
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radius + 6
        color: Theme.bgA
        border.color: Theme.brdr
        border.width: 2

        Row {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Column {
                width: 64
                height: parent.height
                spacing: 8

                Item {
                    width: parent.width
                    height: 48

                    Text {
                        anchors.centerIn: parent
                        text: "PWNBOX"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.brdr
                }

                Flickable {
                    width: parent.width
                    height: parent.height - 48 - 1 - 8
                    contentHeight: navCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: navCol
                        width: parent.width
                        spacing: 4
                        Repeater {
                            model: center.navItems
                            delegate: NavItem {
                                required property var modelData
                                label: modelData.label
                                glyph: modelData.glyph
                                active: center.section === modelData.key
                                onClicked: center.section = modelData.key
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                height: parent.height
                color: Theme.brdr
            }

            Item {
                width: parent.width - 64 - 14 - 1 - 14
                height: parent.height

                Flickable {
                    id: quickPage
                    visible: center.section === "quick"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: quickCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: quickCol
                        width: parent.width
                        spacing: 14

                        Row {
                            width: parent.width
                            spacing: 16

                            Image {
                                width: 72
                                height: 72
                                source: center.homeDir ? "file://" + center.homeDir + "/.config/fastfetch/pwnbox.png" : ""
                                sourceSize.width: 144
                                sourceSize.height: 144
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                            }

                            Column {
                                width: parent.width - 72 - 16
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: center.stats.hostname || "pwnbox"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 17
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: center.stats.distro || ""
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: "Kernel " + (center.stats.kernel || "")
                                    color: Theme.fgFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.brdr
                        }

                        SectionTitle { text: "Connectivity" }
                        Flow {
                            width: parent.width
                            spacing: 10
                            QuickToggle {
                                label: "Wi-Fi"
                                glyph: center.wifiOn ? Theme.iconWifi : Theme.iconWifiOff
                                active: center.wifiOn
                                available: center.wifiAvailable
                                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                            }
                            QuickToggle {
                                label: "Bluetooth"
                                glyph: Theme.iconBluetooth
                                active: center.btOn
                                available: center.btAvailable
                                onToggled: if (center.btAdapter)
                                    center.btAdapter.enabled = !center.btAdapter.enabled
                            }
                        }

                        SectionTitle { text: "System" }
                        Flow {
                            width: parent.width
                            spacing: 10
                            QuickToggle {
                                label: "DND"
                                glyph: center.dnd ? Theme.iconBellSlash : Theme.iconBell
                                active: center.dnd
                                onToggled: center.dndToggled(!center.dnd)
                            }
                            QuickToggle {
                                label: "Screenshot"
                                glyph: Theme.iconCrop || "\uf125"
                                active: false
                                onToggled: center.runCapture("$HOME/.scripts/pwnbox-screenshot clipboard")
                            }
                            QuickToggle {
                                label: "Record"
                                glyph: Theme.iconRecord
                                active: center.recording
                                onToggled: center.section = "capture"
                            }
                            QuickToggle {
                                label: "Clipboard"
                                glyph: Theme.iconClipboard || "\uf0ea"
                                active: false
                                onToggled: center.run("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy")
                            }
                            QuickToggle {
                                label: "Lock"
                                glyph: Theme.iconLock
                                active: false
                                onToggled: center.run("hyprlock")
                            }
                        }

                        SectionTitle { text: "Applications" }
                        Flow {
                            width: parent.width
                            spacing: 10
                            QuickToggle {
                                label: "Launcher"
                                glyph: Theme.iconLauncher
                                active: false
                                onToggled: center.run("rofi -show drun")
                            }
                            QuickToggle {
                                label: "Terminal"
                                glyph: Theme.iconTerminal || "\uf120"
                                active: false
                                onToggled: center.run("kitty")
                            }
                            QuickToggle {
                                label: "Files"
                                glyph: Theme.iconFolder || "\uf07b"
                                active: false
                                onToggled: center.run("nautilus")
                            }
                            QuickToggle {
                                label: "Monitor"
                                glyph: Theme.iconCpu
                                active: false
                                onToggled: center.run("kitty htop")
                            }
                            QuickToggle {
                                label: "Display"
                                glyph: Theme.iconDisplay
                                active: false
                                onToggled: center.section = "display"
                            }
                            QuickToggle {
                                label: "Settings"
                                glyph: Theme.iconSettings || "\uf013"
                                active: false
                                onToggled: center.run("gnome-control-center")
                            }
                        }

                        SectionTitle { text: "Appearance" }
                        Flow {
                            width: parent.width
                            spacing: 10
                            QuickToggle {
                                label: "Wallpaper"
                                glyph: Theme.iconSun
                                active: false
                                onToggled: center.run("$HOME/.scripts/pwnbox-theme pick")
                            }
                            QuickToggle {
                                label: "Theme"
                                glyph: Theme.iconPalette || "\uf1fc"
                                active: false
                                onToggled: center.section = "theme"
                            }
                        }

                        SectionTitle { text: "Sound" }
                        Item {
                            width: parent.width
                            height: 32
                            Text {
                                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                text: center.defaultSinkMuted ? Theme.iconMute : Theme.iconVolume
                                color: center.defaultSinkMuted ? Theme.fg : Theme.fgDim
                                font.family: Theme.fontIcons
                                font.pixelSize: 14
                            }
                            SliderBar {
                                anchors {
                                    left: parent.left; leftMargin: 28; right: parent.right; rightMargin: 48
                                    verticalCenter: parent.verticalCenter
                                }
                                value: center.defaultSinkMuted ? 0 : center.defaultSinkVolume
                                onMoved: v => center.setVolume(v)
                            }
                            Text {
                                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                                text: center.defaultSinkMuted ? "mute" : Math.round(center.defaultSinkVolume * 100) + "%"
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                Flickable {
                    id: powerPage
                    visible: center.section === "power"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: powerCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: powerCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Power"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        Rectangle {
                            width: parent.width
                            height: 92
                            radius: Theme.radius
                            color: Theme.bgAltA
                            border.color: Theme.brdr
                            border.width: 1
                            visible: center.batteryPresent

                            Text {
                                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                                text: center.batteryIcon
                                color: center.batteryPlugged ? Theme.fg : Theme.fgDim
                                font.family: Theme.fontIcons
                                font.pixelSize: 30
                            }
                            Column {
                                anchors { left: parent.left; leftMargin: 72; verticalCenter: parent.verticalCenter }
                                spacing: 4
                                Text {
                                    text: center.batteryLabel
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                }
                                Text {
                                    text: center.batteryText
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }
                            }
                            Rectangle {
                                anchors { right: parent.right; rightMargin: 18; left: parent.left; leftMargin: 72; bottom: parent.bottom; bottomMargin: 16 }
                                height: 6
                                radius: 3
                                color: Theme.brdr
                                Rectangle {
                                    width: parent.width * center.batteryFraction
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.fg
                                }
                            }
                        }

                        SectionTitle { text: "Brightness" }
                        Item {
                            width: parent.width
                            height: 34
                            Text {
                                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                                text: Theme.iconSun
                                color: Theme.fgDim
                                font.family: Theme.fontIcons
                                font.pixelSize: 14
                            }
                            SliderBar {
                                anchors {
                                    left: parent.left; leftMargin: 28; right: parent.right; rightMargin: 48
                                    verticalCenter: parent.verticalCenter
                                }
                                value: center.brightFraction
                                onMoved: v => center.setBrightness(v)
                            }
                            Text {
                                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                                text: Math.round(center.brightFraction * 100) + "%"
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                Flickable {
                    id: networkPage
                    visible: center.section === "network"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: networkCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: networkCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Network"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        SectionTitle { text: "Connection" }
                        Rectangle {
                            width: parent.width
                            implicitHeight: connCol.implicitHeight + 20
                            radius: Theme.radius
                            color: Theme.bgAltA
                            border.color: Theme.brdr
                            border.width: 1

                            Column {
                                id: connCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                spacing: 4

                                Text {
                                    width: parent.width
                                    text: center.netInfo.length > 0 ? center.netInfo : "No active connection"
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    lineHeight: 1.4
                                }
                            }
                        }

                        ToggleRow {
                            label: "Wi-Fi"
                            glyph: center.wifiOn ? Theme.iconWifi : Theme.iconWifiOff
                            active: center.wifiOn
                            available: center.wifiAvailable
                            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                        }

                        Repeater {
                            model: Networking.devices
                            delegate: Column {
                                id: devSection
                                required property var modelData
                                width: parent.width
                                spacing: 2
                                property var device: devSection.modelData
                                readonly property bool isWifi: device.type === DeviceType.Wifi
                                readonly property bool isWired: device.type === DeviceType.Wired
                                visible: isWifi || isWired

                                Text {
                                    text: devSection.isWired ? "Ethernet" : "Networks"
                                    color: Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.letterSpacing: 0.5
                                    leftPadding: 4
                                    visible: devSection.isWifi
                                    height: visible ? 18 : 0
                                }

                                Row {
                                    visible: devSection.isWired
                                    width: parent.width
                                    spacing: 8
                                    leftPadding: 4
                                    Text {
                                        text: Theme.iconEthernet || "\udb80\ude00"
                                        color: devSection.device.hasLink ? Theme.fg : Theme.fgFaint
                                        font.family: Theme.fontIcons
                                        font.pixelSize: 11
                                    }
                                    Text {
                                        text: devSection.device.address || "no address"
                                        color: devSection.device.hasLink ? Theme.fg : Theme.fgFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                Repeater {
                                    visible: devSection.isWifi
                                    model: devSection.device.networks
                                    delegate: Column {
                                        id: netCol
                                        required property var modelData
                                        width: parent.width
                                        spacing: 0
                                        property var network: netCol.modelData
                                        readonly property bool isConnected: network.connected
                                        readonly property bool isConnecting: network.state === ConnectionState.Connecting
                                        readonly property bool isKnown: network.known
                                        readonly property bool hasPsk: network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Unknown
                                        readonly property bool expanded: center.pendingSsid === network.name

                                        Rectangle {
                                            width: parent.width
                                            implicitHeight: 34
                                            radius: Theme.radius - 2
                                            color: rowMouse.containsMouse ? Theme.bgAltA : "transparent"

                                            Row {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 8
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: netCol.network.name || "?"
                                                    color: Theme.fg
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                    width: parent.width - 100
                                                }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: netCol.hasPsk ? Theme.iconLock : ""
                                                    color: Theme.fgFaint
                                                    font.family: Theme.fontIcons
                                                    font.pixelSize: 9
                                                    visible: text.length > 0
                                                }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: Math.round(network.signalStrength || 0) + "%"
                                                    color: Theme.fgFaint
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 9
                                                }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: netCol.isConnected ? Theme.iconCheck
                                                        : netCol.isConnecting ? Theme.iconRefresh : ""
                                                    color: Theme.fg
                                                    font.family: Theme.fontIcons
                                                    font.pixelSize: 11
                                                    visible: text.length > 0
                                                }
                                            }

                                            MouseArea {
                                                id: rowMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (netCol.isConnected) {
                                                        netCol.network.disconnect();
                                                    } else if (netCol.isKnown) {
                                                        netCol.network.connect();
                                                    } else if (netCol.expanded) {
                                                        center.pendingSsid = "";
                                                    } else {
                                                        center.pendingSsid = netCol.network.name;
                                                    }
                                                }
                                            }
                                        }

                                        Item {
                                            visible: netCol.expanded
                                            width: parent.width
                                            implicitHeight: 42
                                            TextInput {
                                                id: pwdField
                                                anchors {
                                                    left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 70
                                                    verticalCenter: parent.verticalCenter
                                                }
                                                color: Theme.fg
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 11
                                                echoMode: TextInput.Password
                                                passwordCharacter: "•"
                                                selectByMouse: true
                                                Text {
                                                    anchors.fill: parent
                                                    visible: !pwdField.text && !pwdField.activeFocus
                                                    text: "password"
                                                    color: Theme.fgFaint
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 11
                                                }
                                            }
                                            Rectangle {
                                                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                                implicitWidth: 50
                                                height: 26
                                                radius: Theme.radius - 3
                                                color: Theme.accent
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Join"
                                                    color: Theme.fg
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 10
                                                    font.weight: Font.Medium
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        netCol.network.connectWithPsk(pwdField.text);
                                                        center.pendingSsid = "";
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Flickable {
                    id: btPage
                    visible: center.section === "bluetooth"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: btCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: btCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Bluetooth"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        ToggleRow {
                            label: "Bluetooth"
                            glyph: Theme.iconBluetooth
                            active: center.btOn
                            available: center.btAvailable
                            onToggled: if (center.btAdapter)
                                center.btAdapter.enabled = !center.btAdapter.enabled
                        }

                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: Theme.radius - 2
                            color: scanMouse.containsMouse ? Theme.bgAltA : "transparent"
                            visible: center.btOn && center.btAvailable
                            Text {
                                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                text: (center.btAdapter && center.btAdapter.discovering) ? Theme.iconRefresh : Theme.iconBluetooth
                                color: (center.btAdapter && center.btAdapter.discovering) ? Theme.fg : Theme.fgDim
                                font.family: Theme.fontIcons
                                font.pixelSize: 11
                            }
                            Text {
                                anchors { left: parent.left; leftMargin: 32; verticalCenter: parent.verticalCenter }
                                text: (center.btAdapter && center.btAdapter.discovering) ? "Scanning..." : "Scan for devices"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: scanMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (center.btAdapter) {
                                    center.btAdapter.discovering = true;
                                    if (center.btAdapter.pairable)
                                        center.btAdapter.pairable = true;
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "No devices"
                            color: Theme.fgFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            visible: center.btOn && center.btAvailable
                                && (!center.btAdapter || center.btAdapter.devices.values.length === 0)
                            topPadding: 6
                            bottomPadding: 6
                        }

                        Repeater {
                            visible: center.btOn && center.btAvailable
                            model: center.btAdapter ? center.btAdapter.devices : 0
                            delegate: Rectangle {
                                id: btRow
                                required property var modelData
                                width: parent.width
                                implicitHeight: 34
                                radius: Theme.radius - 2
                                color: btMouse.containsMouse ? Theme.bgAltA : "transparent"
                                readonly property var device: btRow.modelData
                                readonly property bool isConnected: device.connected
                                readonly property bool isConnecting: device.state === BluetoothDeviceState.Connecting
                                readonly property bool isPaired: device.paired || device.bonded
                                readonly property bool isPairing: device.pairing

                                Text {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    text: Theme.iconBluetooth
                                    color: btRow.isConnected ? Theme.fg : Theme.fgDim
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 11
                                }
                                Text {
                                    anchors {
                                        left: parent.left; leftMargin: 32; right: parent.right; rightMargin: 66
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: btRow.device.name || btRow.device.address || "device"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                    text: btRow.isConnected ? "connected"
                                        : btRow.isConnecting ? "connecting"
                                        : btRow.isPairing ? "pairing"
                                        : btRow.isPaired ? "paired" : "pair"
                                    color: btRow.isConnected ? Theme.fg
                                        : (btRow.isConnecting || btRow.isPairing) ? Theme.fg : Theme.fgFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.letterSpacing: 0.3
                                }
                                MouseArea {
                                    id: btMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (btRow.isConnected) {
                                            btRow.device.disconnect();
                                        } else if (btRow.isPaired) {
                                            btRow.device.connect();
                                        } else if (!btRow.isPairing) {
                                            btRow.device.pair();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Flickable {
                    id: volumePage
                    visible: center.section === "volume"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: volumeCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: volumeCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Volume"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        SectionTitle { text: "Applications" }
                        Repeater {
                            model: Pipewire.nodes
                            delegate: NodeRow {
                                required property var modelData
                                visible: modelData.isStream && modelData.audio !== null && modelData.audio !== undefined
                                height: visible ? implicitHeight : 0
                                node: modelData
                                glyph: Theme.iconHeadphones
                            }
                        }

                        SectionTitle { text: "Output" }
                        Repeater {
                            model: Pipewire.nodes
                            delegate: NodeRow {
                                required property var modelData
                                visible: modelData.isSink
                                height: visible ? implicitHeight : 0
                                node: modelData
                                glyph: Theme.iconSpeaker
                            }
                        }

                        SectionTitle { text: "Input" }
                        Repeater {
                            model: Pipewire.nodes
                            delegate: NodeRow {
                                required property var modelData
                                visible: !modelData.isSink && !modelData.isStream
                                    && (modelData.type & PwNodeType.Source) !== 0
                                    && modelData.audio !== null && modelData.audio !== undefined
                                height: visible ? implicitHeight : 0
                                node: modelData
                                glyph: Theme.iconMic
                            }
                        }
                    }
                }

                Flickable {
                    id: displayPage
                    visible: center.section === "display"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: displayCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: displayCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Display"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        SectionTitle { text: "Monitors" }
                        Text {
                            width: parent.width
                            text: center.monitors ? center.monitors : "No monitors detected"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }

                        SectionTitle { text: "Scale" }
                        Text {
                            width: parent.width
                            text: "Applies to every monitor, keeping its resolution and refresh rate."
                            color: Theme.fgFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                        }

                        Flow {
                            width: parent.width
                            spacing: 10
                            Repeater {
                                model: [ "50", "75", "100", "125", "150", "175", "200" ]
                                delegate: ScaleButton {
                                    required property string modelData
                                    label: modelData + "%"
                                    active: center.scale === modelData
                                    onClicked: center.setScale(parseInt(modelData))
                                }
                            }
                        }
                    }
                }

                Flickable {
                    id: themePage
                    visible: center.section === "theme"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: themeCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: themeCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Theme"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        SectionTitle { text: "Appearance" }
                        ActionRow {
                            label: "Wallpaper (Pywal)"
                            glyph: Theme.iconSun
                            value: center.stateWallpaper ? center.stateWallpaper.split("/").pop() : "Pywal"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme pick")
                        }
                        ActionRow {
                            label: "Custom theme"
                            glyph: Theme.iconPalette || "\uf1fc"
                            value: center.stateCustom || "None"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme custom")
                        }
                        ActionRow {
                            label: "Bar style"
                            glyph: Theme.iconLauncher
                            value: center.stateBarstyle || "side"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme barstyle")
                        }

                        SectionTitle { text: "Shape" }
                        ActionRow {
                            label: "Window corner radius"
                            glyph: Theme.iconDisplay
                            value: (center.stateRadius || "9") + "px"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme radius")
                        }
                        ActionRow {
                            label: "Window borders"
                            glyph: Theme.iconWindow
                            value: center.stateBorders === "off" ? "Off" : "On"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme windowborders")
                        }
                        ActionRow {
                            label: "UI corner radius"
                            glyph: Theme.iconSettings
                            value: (center.stateUiRadius || "9") + "px"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme uiradius")
                        }

                        SectionTitle { text: "Fonts" }
                        ActionRow {
                            label: "System font"
                            glyph: Theme.iconPencil
                            value: center.stateFontUi || "IoskeleyMono Nerd Font"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme uifont")
                        }
                        ActionRow {
                            label: "Application font"
                            glyph: Theme.iconPencil
                            value: center.stateAppFont || "IoskeleyMono Nerd Font"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme appfont")
                        }
                        ActionRow {
                            label: "System font size"
                            glyph: Theme.iconPencil
                            value: (center.stateFontUiSize || "9") + "px"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme uifontsize")
                        }
                        ActionRow {
                            label: "Application font size"
                            glyph: Theme.iconPencil
                            value: (center.stateAppFontSize || "9") + "px"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme appfontsize")
                        }

                        SectionTitle { text: "Effects" }
                        ActionRow {
                            label: "Window shadows"
                            glyph: Theme.iconMoon
                            value: center.stateShadows === "off" ? "Off" : "On"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme shadows")
                        }
                        ActionRow {
                            label: "Blur"
                            glyph: Theme.iconSun
                            value: center.stateBlur === "off" ? "Off" : "On"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme blur")
                        }
                        ActionRow {
                            label: "Transparency"
                            glyph: Theme.iconSun
                            value: (center.stateOpacity || "100") + "%"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme transparency")
                        }
                        ActionRow {
                            label: "Animations"
                            glyph: Theme.iconRefresh
                            value: center.stateAnim === "off" ? "Off" : "On"
                            onActivated: center.run("$HOME/.scripts/pwnbox-theme animations")
                        }
                    }
                }

                Flickable {
                    id: systemPage
                    visible: center.section === "system"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: systemCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: systemCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "System"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        StatRow {
                            label: "CPU"
                            glyph: Theme.iconCpu
                            value: (center.stats.cpu || "0") + "%"
                            fraction: (center.stats.cpu || 0) / 100
                        }
                        StatRow {
                            label: "Memory"
                            glyph: Theme.iconMemory
                            value: (center.stats.mem_used || "0") + " / " + (center.stats.mem_total || "0")
                            fraction: (center.stats.mem || 0) / 100
                        }
                        StatRow {
                            label: "Swap"
                            glyph: Theme.iconSwap
                            value: (center.stats.swap_used || "0") + " / " + (center.stats.swap_total || "0")
                            fraction: (center.stats.swap || 0) / 100
                            visible: (center.stats.swap_total || "0B") !== "0B"
                            height: visible ? 26 : 0
                        }
                        StatRow {
                            label: "Disk"
                            glyph: Theme.iconDisk
                            value: (center.stats.disk_used || "0") + " / " + (center.stats.disk_total || "0")
                            fraction: (center.stats.disk || 0) / 100
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.brdr
                        }

                        InfoRow {
                            label: "Uptime"
                            glyph: Theme.iconClock
                            value: center.stats.uptime || "N/A"
                        }
                        InfoRow {
                            label: "Load"
                            glyph: Theme.iconCpu
                            value: center.stats.load || "0.00"
                        }
                        InfoRow {
                            label: "Hostname"
                            glyph: Theme.iconSettings
                            value: center.stats.hostname || "N/A"
                        }
                        InfoRow {
                            label: "System"
                            glyph: Theme.iconLauncher
                            value: center.stats.distro || "N/A"
                        }
                        InfoRow {
                            label: "Kernel"
                            glyph: Theme.iconSettings
                            value: center.stats.kernel || "N/A"
                        }
                        InfoRow {
                            label: "Download"
                            glyph: Theme.iconDownload
                            value: center.stats.down || "0B/s"
                        }
                        InfoRow {
                            label: "Upload"
                            glyph: Theme.iconUpload
                            value: center.stats.up || "0B/s"
                        }
                    }
                }

                Flickable {
                    id: clipboardPage
                    visible: center.section === "clipboard"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: clipCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: clipCol
                        width: parent.width
                        spacing: 6

                        Text {
                            text: "Clipboard"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        SectionTitle { text: "History" }

                        ActionRow {
                            label: "Clear all"
                            glyph: Theme.iconTrash || "\uf1f8"
                            danger: true
                            visible: center.clipItems.length > 0
                            height: visible ? 38 : 0
                            onActivated: center.clipClearAll()
                        }

                        Text {
                            visible: center.clipItems.length === 0
                            text: "Nothing copied yet"
                            color: Theme.fgFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            topPadding: 6
                        }

                        Repeater {
                            model: center.clipItems
                            delegate: Rectangle {
                                id: clipRow
                                required property var modelData

                                width: clipCol.width
                                height: 40
                                radius: Theme.radius - 2
                                color: clipMouse.containsMouse ? Theme.bgAltA : "transparent"
                                Behavior on color { ColorAnimation { duration: 130 } }

                                MouseArea {
                                    id: clipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: center.clipCopy(clipRow.modelData.id)
                                }
                                Item {
                                    id: clipContent
                                    anchors {
                                        left: parent.left
                                        right: clipActions.left
                                        top: parent.top
                                        bottom: parent.bottom
                                    }

                                    Text {
                                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                        text: Theme.iconClipboard || "\uf0ea"
                                        color: Theme.fgDim
                                        font.family: Theme.fontIcons
                                        font.pixelSize: 12
                                    }
                                    Text {
                                        id: clipPreview
                                        anchors {
                                            left: parent.left; leftMargin: 34
                                            right: parent.right; rightMargin: 8
                                            verticalCenter: parent.verticalCenter
                                        }
                                        text: clipRow.modelData.preview || "(empty)"
                                        color: Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                                Row {
                                    id: clipActions
                                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                                    spacing: 2

                                    Rectangle {
                                        id: clipCopyBtn
                                        width: 26
                                        height: 26
                                        radius: 6
                                        color: clipCopyMouse.containsMouse ? Theme.bgA : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: Theme.iconCopy || "\uf0c5"
                                            color: clipCopyMouse.containsMouse ? Theme.fg : Theme.fgFaint
                                            font.family: Theme.fontIcons
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            id: clipCopyMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: center.clipCopy(clipRow.modelData.id)
                                        }
                                    }

                                    Rectangle {
                                        id: clipDel
                                        width: 26
                                        height: 26
                                        radius: 6
                                        color: clipDelMouse.containsMouse ? Theme.bgA : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: Theme.iconTrash || "\uf1f8"
                                            color: clipDelMouse.containsMouse ? Theme.red : Theme.fgFaint
                                            font.family: Theme.fontIcons
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            id: clipDelMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: center.clipDelete(clipRow.modelData.id, clipRow.modelData.preview)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Flickable {
                    id: calendarPage
                    visible: center.section === "calendar"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: calCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: calCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Calendar"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        Text {
                            text: Qt.formatDateTime(clock.date, "dddd, d MMMM  ·  HH:mm")
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }

                        Calendar {
                            width: parent.width
                            implicitWidth: parent.width
                            today: clock.date
                        }
                    }
                }

                Item {
                    id: mediaPage
                    visible: center.section === "media"
                    anchors.fill: parent
                    anchors.margins: 22

                    Media {
                        anchors.fill: parent
                    }
                }

                Flickable {
                    id: capturePage
                    visible: center.section === "capture"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: captureCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: captureCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Capture"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        SectionTitle { text: "Screenshot" }
                        ActionRow {
                            label: "Area"
                            glyph: Theme.iconCrop || "\uf125"
                            onActivated: center.runCapture("$HOME/.scripts/pwnbox-screenshot area")
                        }
                        ActionRow {
                            label: "Full screen"
                            value: "all screens"
                            glyph: Theme.iconDisplay
                            onActivated: center.runCapture("$HOME/.scripts/pwnbox-screenshot full")
                        }
                        Repeater {
                            model: center.monitorOutputs
                            delegate: ActionRow {
                                required property var modelData
                                label: "Full screen — " + modelData.name
                                value: modelData.width + "x" + modelData.height
                                glyph: Theme.iconDisplay
                                onActivated: center.runCapture("$HOME/.scripts/pwnbox-screenshot full " + modelData.name, 500)
                            }
                        }
                        ActionRow {
                            label: "Active window"
                            glyph: Theme.iconWindow || "\uf2d0"
                            onActivated: center.runCapture("$HOME/.scripts/pwnbox-screenshot window")
                        }
                        ActionRow {
                            label: "Annotate"
                            glyph: Theme.iconPencil
                            onActivated: center.runCapture("$HOME/.scripts/pwnbox-screenshot edit")
                        }

                        SectionTitle { text: "Recording" }
                        ActionRow {
                            label: "Record area"
                            glyph: Theme.iconCrop || "\uf125"
                            visible: !center.recording
                            height: visible ? 38 : 0
                            onActivated: center.runCapture("$HOME/.scripts/pwnbox-record area")
                        }
                        ActionRow {
                            label: "Record full screen"
                            value: "all screens"
                            glyph: Theme.iconDisplay
                            visible: !center.recording
                            height: visible ? 38 : 0
                            onActivated: center.runCapture("$HOME/.scripts/pwnbox-record full")
                        }
                        Repeater {
                            model: center.monitorOutputs
                            delegate: ActionRow {
                                required property var modelData
                                label: "Record — " + modelData.name
                                value: modelData.width + "x" + modelData.height
                                glyph: Theme.iconDisplay
                                visible: !center.recording
                                height: visible ? 38 : 0
                                onActivated: center.runCapture("$HOME/.scripts/pwnbox-record full " + modelData.name)
                            }
                        }
                        ActionRow {
                            label: "Stop recording"
                            glyph: Theme.iconStop || "\uf04d"
                            danger: true
                            visible: center.recording
                            height: visible ? 38 : 0
                            onActivated: center.run("$HOME/.scripts/pwnbox-record stop")
                        }
                    }
                }

                Flickable {
                    id: notifPage
                    visible: center.section === "notifications"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: notifCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: notifCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Notifications"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        ToggleRow {
                            label: "Do not disturb"
                            glyph: center.dnd ? Theme.iconBellSlash : Theme.iconBell
                            active: center.dnd
                            onToggled: center.dndToggled(!center.dnd)
                        }

                        Rectangle {
                            width: parent.width
                            height: 30
                            radius: Theme.radius - 2
                            color: clearMouse.containsMouse ? Theme.bgAltA : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: clearMouse.containsMouse ? Theme.fg : Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: center.clearAll()
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "Nothing here"
                            color: Theme.fgFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            visible: !center.notifModel || center.notifModel.values.length === 0
                            topPadding: 8
                            bottomPadding: 8
                        }

                        Repeater {
                            model: center.notifModel ? center.notifModel.values : 0
                            delegate: Rectangle {
                                id: item
                                required property var modelData
                                width: parent.width
                                implicitHeight: body.implicitHeight + 20
                                radius: Theme.radius - 2
                                color: itemMouse.containsMouse ? Theme.bgAltA : "transparent"
                                readonly property var notif: item.modelData
                                readonly property bool valid: notif !== null && notif !== undefined
                                readonly property color accentColor: item.valid
                                    ? (notif.urgency === NotificationUrgency.Critical ? Theme.red : Theme.accent)
                                    : Theme.accent
                                visible: item.valid

                                Row {
                                    id: body
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                    spacing: 10

                                    Rectangle {
                                        width: 34
                                        height: 34
                                        radius: Theme.radius - 3
                                        color: Theme.bgA
                                        Text {
                                            anchors.centerIn: parent
                                            text: Theme.iconBell
                                            color: item.accentColor
                                            font.family: Theme.fontIcons
                                            font.pixelSize: 13
                                        }
                                    }

                                    Column {
                                        width: body.width - 34 - body.spacing - 26
                                        spacing: 3
                                        Text {
                                            width: parent.width
                                            text: item.notif.summary
                                            color: Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            width: parent.width
                                            text: item.notif.body
                                            color: Theme.fgDim
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                            visible: text.length > 0
                                        }
                                    }
                                }

                                Text {
                                    anchors { right: parent.right; rightMargin: 6; top: parent.top; topMargin: 6 }
                                    text: Theme.iconClose
                                    color: closeNotifMouse.containsMouse ? Theme.fg : Theme.fgFaint
                                    font.family: Theme.fontIcons
                                    font.pixelSize: 11
                                    MouseArea {
                                        id: closeNotifMouse
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: item.notif.dismiss()
                                    }
                                }

                                MouseArea {
                                    id: itemMouse
                                    anchors.fill: parent
                                    z: -1
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }

                Flickable {
                    id: sessionPage
                    visible: center.section === "session"
                    anchors.fill: parent
                    anchors.margins: 22
                    contentHeight: sessionCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: sessionCol
                        width: parent.width
                        spacing: 14

                        Text {
                            text: "Session"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        ActionRow {
                            label: "Lock"
                            glyph: Theme.iconLock
                            onActivated: center.run("hyprlock")
                        }
                        ActionRow {
                            label: "Log out"
                            glyph: Theme.iconLogout
                            onActivated: center.run("hyprctl dispatch exit")
                        }
                        ActionRow {
                            label: "Suspend"
                            glyph: Theme.iconSuspend
                            onActivated: center.run("systemctl suspend")
                        }
                        ActionRow {
                            label: "Reboot"
                            glyph: Theme.iconReboot
                            onActivated: center.run("systemctl reboot")
                        }
                        ActionRow {
                            label: "Shut down"
                            glyph: Theme.iconShutdown
                            danger: true
                            onActivated: center.run("systemctl poweroff")
                        }
                    }
                }
            }
        }
    }
}
