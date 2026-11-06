import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property var mainScreen
    required property var popups
    property bool dnd: false
    signal popupClosed(var notif)

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
            model: root.popups

            delegate: Item {
                id: wrapper
                required property var modelData
                width: 360
                height: popup.visible ? popup.implicitHeight + 8 : 0

                NotificationPopup {
                    id: popup
                    notif: wrapper.modelData
                    autoExpire: true
                    onExpired: {
                        popup.popped = false;
                        root.popupClosed(wrapper.modelData);
                    }
                    onDismissed: root.popupClosed(wrapper.modelData)
                }
            }
        }
    }
}
