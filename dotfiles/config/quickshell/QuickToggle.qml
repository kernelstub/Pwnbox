import QtQuick
import "Theme.js" as Theme

Rectangle {
    id: root
    property string label: ""
    property string glyph: ""
    property bool active: false
    property bool available: true
    signal toggled()

    implicitWidth: 104
    implicitHeight: 66
    radius: Theme.radius
    color: !root.available ? "transparent"
         : root.active ? Theme.accent
         : (hover.hovered ? Theme.bgAltA : Theme.bgA)
    border.color: root.active ? Theme.brdr : Theme.brdr
    border.width: 1
    opacity: root.available ? 1.0 : 0.4
    scale: hover.hovered ? 1.04 : 1.0

    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 11
        }
        text: root.glyph
        color: root.active ? Theme.fg : Theme.fgDim
        font.family: Theme.fontIcons
        font.pixelSize: 17
    }

    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 8
        }
        text: root.label
        color: root.active ? Theme.fg : Theme.fgDim
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.weight: Font.Medium
    }

    HoverHandler {
        id: hover
        enabled: root.available
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
