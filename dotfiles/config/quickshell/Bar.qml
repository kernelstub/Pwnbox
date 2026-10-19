import QtQuick
import Quickshell
import Quickshell.Wayland
import "Theme.js" as Theme
import "BarStyles.js" as BarStyles

PanelWindow {
    id: bar
    required property ShellScreen modelData
    required property string barStyle
    property bool dnd: false
    property int notifCount: 0
    property bool notifOpen: false

    screen: modelData

    readonly property var sd: BarStyles.geometry(barStyle, Theme.barHeight, Theme.bgA)

    anchors {
        top: sd.top
        bottom: sd.bottom
        left: sd.left
        right: sd.right
    }
    implicitWidth: sd.width || 0
    implicitHeight: sd.height || 0
    color: sd.color
    exclusiveZone: sd.exclusive

    surfaceFormat.opaque: false

    Loader {
        anchors.fill: parent
        source: "BarStyle" + bar.sd.file + ".qml"
    }
}
