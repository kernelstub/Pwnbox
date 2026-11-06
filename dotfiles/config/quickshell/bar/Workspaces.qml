import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../Theme.js" as Theme

Item {
    id: root
    property bool vertical: false
    property int deskCount: 10
    // dots | squares | numbers | roman (anything else falls back to dots)
    property string indicator: "dots"

    readonly property var romanDigits: [ "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" ]
    readonly property bool showText: root.indicator === "numbers" || root.indicator === "roman"
    readonly property bool showSquares: root.indicator === "squares"
    readonly property bool showDots: !root.showText && !root.showSquares

    readonly property real dotSize: 8
    readonly property real cell: root.showText ? 24 : root.dotSize
    readonly property real cellSpacing: 6
    readonly property real extent: root.cell * root.deskCount + root.cellSpacing * (root.deskCount - 1)
    implicitWidth: vertical ? root.cell : root.extent
    implicitHeight: vertical ? root.extent : root.cell

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

    function deskLabel(deskId) {
        return root.indicator === "roman" ? root.romanDigits[deskId - 1] : String(deskId);
    }

    Repeater {
        model: root.deskCount

        delegate: Item {
            id: cellItem
            required property int index

            readonly property int deskId: index + 1
            readonly property bool focused: deskId === root.activeDesk()
            readonly property bool hasWindows: root.occupiedDesk(deskId)
            readonly property color ink: cellItem.focused ? Theme.fg
                                       : (cellItem.hasWindows ? Theme.fgDim : Theme.fgFaint)

            x: root.vertical ? 0 : cellItem.index * (root.cell + root.cellSpacing)
            y: root.vertical ? cellItem.index * (root.cell + root.cellSpacing) : 0
            width: root.cell
            height: root.cell

            Rectangle {
                visible: root.showDots
                anchors.centerIn: parent
                width: root.dotSize
                height: root.dotSize
                radius: width / 2
                color: cellItem.ink
                scale: cellItem.focused ? 1.35 : 1.0

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Rectangle {
                visible: root.showSquares
                anchors.centerIn: parent
                width: root.dotSize
                height: root.dotSize
                radius: 2
                color: cellItem.ink
                scale: cellItem.focused ? 1.35 : 1.0

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                visible: root.showText
                anchors.centerIn: parent
                text: root.deskLabel(cellItem.deskId)
                color: cellItem.ink
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: cellItem.focused ? Font.Bold : Font.Normal

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    proc.command = [ "sh", "-c", "$HOME/.scripts/pwnbox-vdesk " + cellItem.deskId ];
                    proc.startDetached();
                }
            }
        }
    }

    Process {
        id: proc
    }
}
