import QtQuick
import QtQuick.Layouts
import "Theme.js" as Theme

Item {
    anchors.fill: parent

    component Sep: Rectangle {
        implicitWidth: 26
        implicitHeight: 1
        color: Theme.brdr
    }

    ColumnLayout {
        anchors { top: parent.top; topMargin: 12; horizontalCenter: parent.horizontalCenter }
        spacing: 6
        Workspaces { vertical: true; Layout.alignment: Qt.AlignHCenter }
    }

    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        Clock { vertical: true }
    }

    ColumnLayout {
        anchors { bottom: parent.bottom; bottomMargin: 12; horizontalCenter: parent.horizontalCenter }
        spacing: 8
        Stats { vertical: true; Layout.alignment: Qt.AlignHCenter }
        BatteryWidget { vertical: true; Layout.alignment: Qt.AlignHCenter }
        Sep {}
        VolumeWidget { vertical: true; Layout.alignment: Qt.AlignHCenter }
        Indicators { vertical: true; dnd: bar.dnd; notifCount: bar.notifCount; notifOpen: bar.notifOpen; Layout.alignment: Qt.AlignHCenter }
        PowerButton { Layout.alignment: Qt.AlignHCenter }
    }
}
