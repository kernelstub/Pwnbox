import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    component Sep: Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 1
        implicitHeight: 14
        color: Theme.brdr
    }

    RowLayout {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 8
        Workspaces { Layout.alignment: Qt.AlignVCenter }
    }

    RowLayout {
        anchors.centerIn: parent
        Clock {}
    }

    RowLayout {
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 10
        Stats { Layout.alignment: Qt.AlignVCenter }
        BatteryWidget { Layout.alignment: Qt.AlignVCenter }
        Sep {}
        VolumeWidget { Layout.alignment: Qt.AlignVCenter }
        Indicators { dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen; Layout.alignment: Qt.AlignVCenter }
        PowerButton { Layout.alignment: Qt.AlignVCenter }
    }
}
