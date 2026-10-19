import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    Rectangle {
        id: capsule
        anchors {
            top: parent.top; topMargin: 8
            left: parent.left; leftMargin: 10
            right: parent.right; rightMargin: 10
        }
        height: 34
        radius: Theme.radius
        color: Theme.bgA
        border.color: Theme.brdr
        border.width: 2

        component Sep: Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 1
            implicitHeight: 14
            color: Theme.brdr
        }

        RowLayout {
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 8
            Workspaces { Layout.alignment: Qt.AlignVCenter }
        }

        RowLayout {
            anchors.centerIn: parent
            Clock {}
        }

        RowLayout {
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 10
            Stats { Layout.alignment: Qt.AlignVCenter }
            BatteryWidget { Layout.alignment: Qt.AlignVCenter }
            Sep {}
            VolumeWidget { Layout.alignment: Qt.AlignVCenter }
            Indicators { dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen; Layout.alignment: Qt.AlignVCenter }
            PowerButton { Layout.alignment: Qt.AlignVCenter }
        }
    }
}
