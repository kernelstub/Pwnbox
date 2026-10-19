import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import "Theme.js" as Theme

Item {
    id: root
    property bool dnd: false
    property int notifCount: 0
    property bool notifOpen: false
    property bool vertical: false

    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool wifiAvailable: Networking.wifiHardwareEnabled
    readonly property var btAdapter: Bluetooth.defaultAdapter
    readonly property bool btOn: btAdapter !== null && btAdapter.enabled

    implicitWidth: root.vertical ? col.implicitWidth : row.implicitWidth
    implicitHeight: root.vertical ? col.implicitHeight : row.implicitHeight

    component IconBtn: Item {
        id: btn
        required property string glyph
        required property bool active
        property bool available: true
        signal tapped()

        width: 22
        height: 16

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: !btn.available ? Theme.fgFaint : (btn.active || btnMouse.containsMouse ? Theme.fg : Theme.fgDim)
            font.family: Theme.fontIcons
            font.pixelSize: 13
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            anchors.margins: -3
            enabled: btn.available
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.tapped()
        }
    }

    Row {
        id: row
        visible: !root.vertical
        spacing: 4

        IconBtn {
            glyph: root.wifiOn ? Theme.iconWifi : Theme.iconWifiOff
            active: root.wifiOn
            available: root.wifiAvailable
            onTapped: {
                const centre = mapToItem(null, width / 2, 0).x;
                proc1.command = [ "sh", "-c", "qs ipc call networkpanel toggleAt " + Math.round(centre) ];
                proc1.startDetached();
            }
        }
        IconBtn {
            glyph: Theme.iconBluetooth
            active: root.btOn
            available: root.btAdapter !== null
            onTapped: {
                const centre = mapToItem(null, width / 2, 0).x;
                proc2.command = [ "sh", "-c", "qs ipc call bluetoothpanel toggleAt " + Math.round(centre) ];
                proc2.startDetached();
            }
        }
        NotifButton {
            dnd: root.dnd
            count: root.notifCount
            panelOpen: root.notifOpen
        }
    }

    Column {
        id: col
        visible: root.vertical
        spacing: 6

        IconBtn {
            glyph: root.wifiOn ? Theme.iconWifi : Theme.iconWifiOff
            active: root.wifiOn
            available: root.wifiAvailable
            anchors.horizontalCenter: parent.horizontalCenter
            onTapped: {
                const centre = mapToItem(null, width / 2, 0).x;
                proc1.command = [ "sh", "-c", "qs ipc call networkpanel toggleAt " + Math.round(centre) ];
                proc1.startDetached();
            }
        }
        IconBtn {
            glyph: Theme.iconBluetooth
            active: root.btOn
            available: root.btAdapter !== null
            anchors.horizontalCenter: parent.horizontalCenter
            onTapped: {
                const centre = mapToItem(null, width / 2, 0).x;
                proc2.command = [ "sh", "-c", "qs ipc call bluetoothpanel toggleAt " + Math.round(centre) ];
                proc2.startDetached();
            }
        }
        NotifButton {
            dnd: root.dnd
            count: root.notifCount
            panelOpen: root.notifOpen
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    Process { id: proc1 }
    Process { id: proc2 }
}
