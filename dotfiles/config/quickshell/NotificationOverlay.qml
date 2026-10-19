import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var mainScreen
    required property var server
    property bool dnd: false

    screen: root.mainScreen
    visible: !root.dnd

    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 3
        right: 8
    }

    color: "transparent"
    surfaceFormat.opaque: false
    exclusiveZone: 0
    implicitWidth: 372
    implicitHeight: Math.min(column.implicitHeight, 640)
    mask: Region { item: column }

    Column {
        id: column
        anchors {
            bottom: parent.bottom
            right: parent.right
        }
        width: 360
        spacing: 0

        Repeater {
            model: root.server.trackedNotifications.values

            delegate: Item {
                id: wrapper
                width: 360
                height: popup.visible ? popup.implicitHeight + 8 : 0

                NotificationPopup {
                    id: popup
                    notif: modelData
                    autoExpire: true
                    onExpired: popup.popped = false
                }
            }
        }
    }
}
