import QtQuick
import Quickshell
import Quickshell.Io
import "Theme.js" as Theme

Item {
    id: root
    property bool vertical: false
    property bool minimal: false

    implicitWidth: vertical ? vItem.implicitWidth : hItem.implicitWidth
    implicitHeight: vertical ? vItem.implicitHeight : hItem.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        id: hItem
        visible: !root.vertical
        anchors.fill: parent
        implicitWidth: hlabel.implicitWidth + 10
        implicitHeight: hlabel.implicitHeight + 4

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius - 2
            color: hover.containsMouse ? Theme.bgAltA : "transparent"
            z: -1
        }

        Text {
            id: hlabel
            anchors.centerIn: parent
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
        }
    }

    Item {
        id: vItem
        visible: root.vertical
        anchors.fill: parent
        implicitWidth: vcol.implicitWidth + 10
        implicitHeight: vcol.implicitHeight + 4

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius - 2
            color: hover.containsMouse ? Theme.bgAltA : "transparent"
            z: -1
        }

        Column {
            id: vcol
            anchors.centerIn: parent
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.Medium
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !root.minimal
                text: Qt.formatDateTime(clock.date, "ddd dd")
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const centre = root.mapToItem(null, root.width / 2, 0).x;
            toggle.command = [ "sh", "-c", "qs ipc call calendar toggleAt " + Math.round(centre) ];
            toggle.startDetached();
        }
    }

    Process {
        id: toggle
    }
}
