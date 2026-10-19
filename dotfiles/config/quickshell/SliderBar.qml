import QtQuick
import "Theme.js" as Theme

Rectangle {
    id: root
    property real value: 0
    property color fillColor: Theme.fg
    property real handleSize: 12
    signal moved(real value)

    property real dragValue: value
    property bool dragging: false

    height: 6
    radius: 3
    color: Theme.brdr

    Rectangle {
        id: fill
        width: parent.width * (root.dragging ? root.dragValue : root.value)
        height: parent.height
        radius: parent.radius
        color: root.fillColor
    }

    Rectangle {
        id: handle
        visible: root.dragging
        width: root.handleSize
        height: root.handleSize
        radius: root.handleSize / 2
        color: Theme.fg
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width * (root.dragging ? root.dragValue : root.value) - width / 2
    }

    function setFromX(x) {
        root.dragValue = Math.max(0, Math.min(1, x / root.width));
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            mouse.accepted = true;
            root.dragging = true;
            root.setFromX(mouse.x);
        }
        onPositionChanged: if (root.dragging) root.setFromX(mouse.x)
        onReleased: {
            root.dragging = false;
            root.moved(root.dragValue);
        }
    }
}
