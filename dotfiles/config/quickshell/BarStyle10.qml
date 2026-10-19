import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    component Pill: Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 30
        radius: Theme.radius
        color: Theme.bgA
        border.color: Theme.brdr
        border.width: 2
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
        spacing: 10

        Pill {
            implicitWidth: workspaces.implicitWidth + 26
            Row { id: workspaces; anchors.centerIn: parent; spacing: 7
                Workspaces {} }
        }
        Pill {
            implicitWidth: clock.implicitWidth + 26
            Row { id: clock; anchors.centerIn: parent; Clock {} }
        }
        Pill {
            implicitWidth: statsRow.implicitWidth + 26
            Row { id: statsRow; anchors.centerIn: parent; spacing: 12
                Stats {}
                BatteryWidget {} }
        }
        Pill {
            implicitWidth: powerRow.implicitWidth + 26
            Row { id: powerRow; anchors.centerIn: parent; spacing: 12
                VolumeWidget {}
                Indicators { dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen }
                PowerButton {} }
        }
    }
}
