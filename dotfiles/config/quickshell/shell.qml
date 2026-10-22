import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    property string barStyle: "islands"
    property string mainMonitor: "@MAINMONITOR@"

    property bool dnd: false
    property int notifCount: 0
    property bool notifOpen: false
    property var popupNotifications: []
    readonly property int maxPopups: 3

    readonly property var mainScreen: {
        const screens = Quickshell.screens;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === root.mainMonitor)
                return screens[i];
        for (let i = 0; i < screens.length; i++)
            if (screens[i].x === 0 && screens[i].y === 0)
                return screens[i];
        return screens.length > 0 ? screens[0] : null;
    }

    function isMainScreen(screen) {
        return root.mainScreen !== null && screen === root.mainScreen;
    }

    function addPopup(notif) {
        const next = root.popupNotifications.filter(n => n !== notif);
        next.push(notif);
        root.popupNotifications = next.slice(Math.max(0, next.length - root.maxPopups));
    }

    function removePopup(notif) {
        root.popupNotifications = root.popupNotifications.filter(n => n !== notif);
    }

    Process {
        id: styleReader
        command: ["sh", "-c", "cat \"$HOME/.cache/pwnbox/theme/barstyle\" 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const s = this.text.trim();
                if (s.length > 0)
                    root.barStyle = s;
            }
        }
    }

    IpcHandler {
        target: "barstyle"

        function set(name: string) {
            root.barStyle = name;
        }

        function get(): string {
            return root.barStyle;
        }
    }

    IpcHandler {
        target: "notif"

        function dbg(): string {
            return "tracked=" + notifServer.trackedNotifications.values.length
                + " badge=" + root.notifCount;
        }
    }

    Variants {
        model: Quickshell.screens
        Bar {
            barStyle: root.barStyle
            visible: root.isMainScreen(modelData)
            dnd: root.dnd
            notifCount: root.notifCount
            notifOpen: root.notifOpen
        }
    }

    NotificationServer {
        id: notifServer
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        bodyMarkupSupported: false
        onNotification: n => {
            n.tracked = true;
            root.addPopup(n);
            if (!root.notifOpen)
                root.notifCount += 1;
        }
    }

    Connections {
        target: notifServer.trackedNotifications
        function onValuesChanged() {
            const tracked = notifServer.trackedNotifications.values;
            root.popupNotifications = root.popupNotifications.filter(n => tracked.indexOf(n) !== -1);
        }
    }

    NotificationOverlay {
        mainScreen: root.mainScreen
        popups: root.popupNotifications
        onPopupClosed: n => root.removePopup(n)
        dnd: root.dnd
    }

    VolumeOsd {
        mainScreen: root.mainScreen
    }

    ControlCenter {
        homeScreen: root.mainScreen
        dnd: root.dnd
        notifModel: notifServer.trackedNotifications
        onDndToggled: v => root.dnd = v
        onOpenChangedTo: v => {
            root.notifOpen = v;
            if (v)
                root.notifCount = 0;
        }
    }
}
