import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    component Block: Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 26
        radius: Theme.radius
        color: Theme.bgA
        border.color: Theme.brdr
        border.width: 2
    }

    RowLayout {
        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 8
        Block {
            implicitWidth: workspaces.implicitWidth + 24
            Row { id: workspaces; anchors.centerIn: parent; spacing: 7
                Workspaces {} }
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        Block {
            implicitWidth: clock.implicitWidth + 24
            Row { id: clock; anchors.centerIn: parent; Clock {} }
        }
    }

    RowLayout {
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 8
        Block {
            implicitWidth: systemRow.implicitWidth + 24
            Row { id: systemRow; anchors.centerIn: parent; spacing: 12
                Stats {}
                BatteryWidget {} }
        }
        Block {
            implicitWidth: powerRow.implicitWidth + 24
            Row { id: powerRow; anchors.centerIn: parent; spacing: 8
                VolumeWidget {}
                Indicators { dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen }
                PowerButton {} }
        }
    }
}
