import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "Theme.js" as Theme

Item {
    id: root
    property bool vertical: false
    property int deskCount: 10

    readonly property real dotSize: 8
    readonly property real dotSpacing: 6
    readonly property real extent: dotSize * root.deskCount + dotSpacing * (root.deskCount - 1)
    implicitWidth: vertical ? dotSize : extent
    implicitHeight: vertical ? extent : dotSize

    readonly property int monitorCount: Math.max(Hyprland.monitors.values.length, 1)

    function deskOf(wsId) {
        return Math.ceil(wsId / root.monitorCount);
    }

    function activeDesk() {
        const focused = Hyprland.focusedWorkspace;
        return focused ? root.deskOf(focused.id) : 1;
    }

    function occupiedDesk(desk) {
        const range = [ (desk - 1) * root.monitorCount + 1, desk * root.monitorCount ];
        const wins = Hyprland.toplevels.values;
        for (let i = 0; i < wins.length; i++) {
            const ws = wins[i].workspace;
            if (ws && ws.id >= range[0] && ws.id <= range[1])
                return true;
        }
        return false;
    }

    Repeater {
        model: root.deskCount

        delegate: Rectangle {
            id: ball
            required property int index

            readonly property int deskId: index + 1
            readonly property bool focused: deskId === root.activeDesk()
            readonly property bool hasWindows: root.occupiedDesk(deskId)

            x: root.vertical ? 0 : ball.index * (root.dotSize + root.dotSpacing)
            y: root.vertical ? ball.index * (root.dotSize + root.dotSpacing) : 0
            width: root.dotSize
            height: root.dotSize
            radius: root.dotSize / 2
            color: ball.focused ? Theme.fg
                                : (ball.hasWindows ? Theme.fgDim : Theme.fgFaint)
            scale: ball.focused ? 1.35 : 1.0

            Behavior on color {
                ColorAnimation { duration: 120 }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    proc.command = [ "sh", "-c", "$HOME/.scripts/pwnbox-vdesk " + ball.deskId ];
                    proc.startDetached();
                }
            }
        }
    }

    Process {
        id: proc
    }
}
