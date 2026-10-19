import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    component Mini: Rectangle {
        width: 34
        radius: Theme.radius - 2
        color: Theme.bgA
        border.color: Theme.brdr
        border.width: 1
    }

    Mini {
        anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
        height: wsCol.height + 10
        Column {
            id: wsCol
            anchors.centerIn: parent
            spacing: 6
            Workspaces { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    Mini {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        height: clockCol.height + 10
        Column {
            id: clockCol
            anchors.centerIn: parent
            Clock { vertical: true; minimal: true; anchors.horizontalCenter: parent.horizontalCenter }
        }
    }

    Mini {
        anchors { bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
        height: sysCol.height + 10
        Column {
            id: sysCol
            anchors.centerIn: parent
            spacing: 6
            Stats { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
            BatteryWidget { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
            VolumeWidget { vertical: true; anchors.horizontalCenter: parent.horizontalCenter }
            Indicators { vertical: true; dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen; anchors.horizontalCenter: parent.horizontalCenter }
            PowerButton { anchors.horizontalCenter: parent.horizontalCenter }
        }
    }
}
