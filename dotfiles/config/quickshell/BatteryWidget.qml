import QtQuick
import Quickshell.Services.UPower
import "Theme.js" as Theme

Item {
    id: root
    property bool vertical: false

    implicitWidth: vertical ? col.implicitWidth : row.implicitWidth
    implicitHeight: vertical ? col.implicitHeight : row.implicitHeight

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev !== null && dev.isLaptopBattery
    readonly property real pct: present ? (dev.percentage || 0) : 0
    readonly property int st: present ? dev.state : UPowerDeviceState.Unknown
    readonly property bool charging: st === UPowerDeviceState.Charging || st === UPowerDeviceState.PendingCharge
    readonly property bool full: st === UPowerDeviceState.FullyCharged
    readonly property bool plugged: charging || full
    readonly property string icon: charging ? Theme.iconCharging
        : full ? Theme.iconBattery
        : (pct > 0.5 ? Theme.iconBattery : Theme.iconBatteryHalf)
    readonly property color iconColor: plugged ? Theme.fg : Theme.fgDim

    visible: present

    Row {
        id: row
        visible: !root.vertical
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.iconColor
            font.family: Theme.fontIcons
            font.pixelSize: Theme.fontSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.pct * 100) + "%"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    Column {
        id: col
        visible: root.vertical
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: root.iconColor
            font.family: Theme.fontIcons
            font.pixelSize: Theme.fontSize + 1
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(root.pct * 100) + "%"
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
        }
    }
}
