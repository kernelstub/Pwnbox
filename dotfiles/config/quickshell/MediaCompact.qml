import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "Theme.js" as Theme

Item {
    id: root

    readonly property var player: {
        const list = Mpris.players.values;
        if (!list || list.length === 0)
            return null;
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying)
                return list[i];
        }
        return list[0] || null;
    }
    readonly property bool active: player !== null && player !== undefined
        && (player.trackTitle || "").length > 0
    readonly property bool playing: active && player.isPlaying

    visible: active
    implicitWidth: Math.min(240, art.width + col.implicitWidth + 24)
    implicitHeight: 22

    Image {
        id: art
        anchors {
            left: parent.left
            leftMargin: 3
            verticalCenter: parent.verticalCenter
        }
        width: 16
        height: 16
        source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
        sourceSize.width: 64
        sourceSize.height: 64
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
    }

    Text {
        anchors.fill: art
        visible: !art.visible
        text: Theme.iconMusic
        color: Theme.fgDim
        font.family: Theme.fontIcons
        font.pixelSize: 10
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Column {
        id: col
        anchors {
            left: art.right
            leftMargin: 6
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: 0

        Text {
            width: parent.width
            text: root.active ? root.player.trackTitle : ""
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: {
                if (!root.active)
                    return "";
                if (root.player.trackArtist && root.player.trackArtist.length > 0)
                    return root.player.trackArtist;
                return root.player.identity || "";
            }
            color: Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const centre = root.mapToItem(null, root.width / 2, 0).x;
            proc.command = [ "sh", "-c", "qs ipc call calendar toggleAt " + Math.round(centre) ];
            proc.startDetached();
        }
    }

    Process {
        id: proc
    }
}
