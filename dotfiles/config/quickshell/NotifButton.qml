import QtQuick
import Quickshell
import Quickshell.Io
import "Theme.js" as Theme

Item {
    id: root
    property bool dnd: false
    property int count: 0
    property bool panelOpen: false

    implicitWidth: 22
    implicitHeight: 16

    Text {
        anchors.centerIn: parent
        text: root.dnd ? Theme.iconBellSlash : Theme.iconBell
        color: (root.count > 0 && !root.dnd) || root.panelOpen ? Theme.fg : Theme.fgDim
        font.family: Theme.fontIcons
        font.pixelSize: 13
    }

    Rectangle {
        visible: root.count > 0 && !root.panelOpen
        width: 12
        height: 12
        radius: 6
        color: Theme.fg
        anchors {
            top: parent.top
            right: parent.right
            rightMargin: -5
            topMargin: -3
        }

        Text {
            anchors.centerIn: parent
            text: Math.min(root.count, 9)
            color: Theme.bg
            font.family: Theme.fontFamily
            font.pixelSize: 7
            font.weight: Font.Bold
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const centre = root.mapToItem(null, root.width / 2, 0).x;
            proc.command = [ "sh", "-c", "qs ipc call notifcenter toggleAt " + Math.round(centre) ];
            proc.startDetached();
        }
    }

    Process {
        id: proc
    }
}
