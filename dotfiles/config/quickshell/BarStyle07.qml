import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    component Pill: Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 8
        height: 30
        radius: Theme.radius
        color: Theme.bgA
        border.color: Theme.brdr
        border.width: 2
    }

    Pill {
        id: wsPill
        anchors.left: parent.left
        anchors.leftMargin: 10
        implicitWidth: wsRow.implicitWidth + 26
        Row { id: wsRow; anchors.centerIn: parent; spacing: 7
            Workspaces {} }
    }

    Pill {
        id: infoPill
        anchors.right: parent.right
        anchors.rightMargin: 10
        implicitWidth: infoRow.implicitWidth + 26
        Row { id: infoRow; anchors.centerIn: parent; spacing: 12
            Clock {}
            Stats {}
            BatteryWidget {}
            VolumeWidget {}
            Indicators { dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen }
            PowerButton {}
        }
    }
}
