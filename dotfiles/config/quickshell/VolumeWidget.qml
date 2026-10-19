import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "Theme.js" as Theme

Item {
    id: root
    property bool vertical: false

    implicitWidth: vertical ? col.implicitWidth : row.implicitWidth
    implicitHeight: vertical ? col.implicitHeight : row.implicitHeight

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const centre = root.mapToItem(null, root.width / 2, 0).x;
            toggle.command = [ "sh", "-c", "qs ipc call mixer toggleAt " + Math.round(centre) ];
            toggle.startDetached();
        }
    }

    Process {
        id: toggle
    }

    Row {
        id: row
        visible: !root.vertical
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted ? Theme.iconMute : Theme.iconVolume
            color: root.muted ? Theme.fg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 15
        }
    }

    Column {
        id: col
        visible: root.vertical
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.muted ? Theme.iconMute : Theme.iconVolume
            color: root.muted ? Theme.fg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: 15
        }
    }
}
