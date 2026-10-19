import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    component Island: Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 30
        radius: Theme.radius
        color: Theme.bgA
        border.color: Theme.brdr
        border.width: 2
    }

    RowLayout {
        anchors { left: parent.left; leftMargin: 10; bottom: parent.bottom; bottomMargin: 10 }
        Island {
            implicitWidth: workspaces.implicitWidth + 26
            Row { id: workspaces; anchors.centerIn: parent; spacing: 7
                Workspaces {} }
        }
    }

    RowLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        Island {
            implicitWidth: clock.implicitWidth + 26
            Row { id: clock; anchors.centerIn: parent; Clock {} }
        }
    }

    RowLayout {
        anchors { right: parent.right; rightMargin: 10; bottom: parent.bottom; bottomMargin: 10 }
        spacing: 10
        Island {
            implicitWidth: systemRow.implicitWidth + 26
            Row { id: systemRow; anchors.centerIn: parent; spacing: 12
                Stats {}
                BatteryWidget {} }
        }
        Island {
            implicitWidth: powerRow.implicitWidth + 26
            Row { id: powerRow; anchors.centerIn: parent; spacing: 8
                VolumeWidget {}
                Indicators { dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen }
                PowerButton {} }
        }
    }
}
