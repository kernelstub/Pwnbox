import QtQuick
import Quickshell.Io
import "Theme.js" as Theme

Item {
    id: root
    implicitWidth: 20
    implicitHeight: 16

    Text {
        anchors.centerIn: parent
        text: Theme.iconPower
        color: hover.hovered ? Theme.fg : Theme.fgDim
        font.family: Theme.fontIcons
        font.pixelSize: 13
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const centre = root.mapToItem(null, root.width / 2, 0).x;
            proc.command = [ "sh", "-c", "qs ipc call powermenu toggleAt " + Math.round(centre) + " || wlogout" ];
            proc.startDetached();
        }
    }

    Process {
        id: proc
    }
}
