import QtQuick
import Quickshell.Hyprland
import "Theme.js" as Theme

Item {
    id: root
    implicitWidth: Math.min(280, titleLabel.implicitWidth + 16)
    implicitHeight: 16

    readonly property var win: Hyprland.activeToplevel
    readonly property string text: win && win.title ? win.title : ""
    visible: text.length > 0

    Text {
        id: titleLabel
        anchors.centerIn: parent
        text: root.text
        color: Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        elide: Text.ElideRight
        maximumLineCount: 1
    }
}
