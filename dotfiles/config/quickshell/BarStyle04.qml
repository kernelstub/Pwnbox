import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    Rectangle {
        id: pill
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: content.implicitWidth + 40
        height: 38
        radius: Theme.radius
        color: Theme.bgA
        border.color: Theme.brdr
        border.width: 2

        component Div: Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 1
            implicitHeight: 16
            color: Theme.brdr
        }

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 14
            Workspaces { Layout.alignment: Qt.AlignVCenter }
            Div {}
            Clock { Layout.alignment: Qt.AlignVCenter }
            Div {}
            Stats { Layout.alignment: Qt.AlignVCenter }
            BatteryWidget { Layout.alignment: Qt.AlignVCenter }
            Div {}
            VolumeWidget { Layout.alignment: Qt.AlignVCenter }
            Indicators { dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen; Layout.alignment: Qt.AlignVCenter }
            PowerButton { Layout.alignment: Qt.AlignVCenter }
        }
    }
}
