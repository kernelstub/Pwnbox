import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    component Pill: Rectangle {
        width: 40
        radius: Theme.radius
        color: Theme.bgA
        border.color: Theme.brdr
        border.width: 2
    }

    component Sep: Rectangle {
        implicitWidth: 22
        implicitHeight: 1
        color: Theme.brdr
    }

    Pill {
        anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
        height: wsCol.height + 16
        Column {
            id: wsCol
            anchors.centerIn: parent
            spacing: 6
            Workspaces { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    Pill {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        height: clockCol.height + 16
        Column {
            id: clockCol
            anchors.centerIn: parent
            Clock { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    Pill {
        anchors { bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
        height: sysCol.height + 16
        Column {
            id: sysCol
            anchors.centerIn: parent
            spacing: 8
            Stats { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
            BatteryWidget { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
            Sep { anchors.horizontalCenter: parent.horizontalCenter }
            VolumeWidget { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
            Indicators { vertical: true; dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen; anchors.horizontalCenter: parent.horizontalCenter }
            PowerButton { anchors.horizontalCenter: parent.horizontalCenter }
        }
    }
}
