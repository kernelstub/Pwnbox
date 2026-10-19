import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import QtQuick.Effects
import "Theme.js" as Theme

Item {
    id: media

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
    readonly property bool seekable: active && player.length > 0 && player.canSeek
    readonly property bool volumeSupported: active && player.volumeSupported
    readonly property real progress: (active && player.length > 0)
        ? Math.max(0, Math.min(1, player.position / player.length))
        : 0

    readonly property real artSize: Math.max(120, Math.min(width - 24, height - 320))

    Timer {
        interval: 500
        repeat: true
        running: media.active && media.playing && media.seekable
        onTriggered: if (media.player)
            media.player.positionChanged()
    }

    function fmtTime(secs) {
        const s = Math.max(0, Math.round(secs));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    Column {
        id: body
        visible: media.active
        anchors.centerIn: parent
        width: parent.width
        spacing: 16

        Item {
            id: artWrap
            anchors.horizontalCenter: parent.horizontalCenter
            width: media.artSize
            height: media.artSize

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: artMask
            }

            Rectangle {
                anchors.fill: parent
                color: Theme.bgAltA

                Text {
                    anchors.centerIn: parent
                    text: Theme.iconMusic
                    color: Theme.fgFaint
                    font.family: Theme.fontIcons
                    font.pixelSize: Math.round(artWrap.width * 0.16)
                }
            }

            Image {
                anchors.fill: parent
                source: (media.active && media.player.trackArtUrl) ? media.player.trackArtUrl : ""
                sourceSize.width: 512
                sourceSize.height: 512
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
        }

        Rectangle {
            id: artMask
            anchors.fill: artWrap
            visible: false
            radius: Theme.radius + 3
            color: "white"
            layer.enabled: true
        }

        Column {
            width: parent.width
            spacing: 4

            Text {
                width: parent.width
                text: media.active ? media.player.trackTitle : ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 17
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!media.active)
                        return "";
                    if (media.player.trackArtist && media.player.trackArtist.length > 0)
                        return media.player.trackArtist;
                    return media.player.identity || "";
                }
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        Row {
            visible: media.seekable
            width: parent.width
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (media.player && media.player.length > 0) ? media.fmtTime(media.player.position) : ""
                color: Theme.fgFaint
                font.family: Theme.fontFamily
                font.pixelSize: 10
                width: 34
            }

            SliderBar {
                width: parent.width - 34 - 34 - 20
                anchors.verticalCenter: parent.verticalCenter
                value: media.progress
                onMoved: v => {
                    if (media.player && media.player.length > 0)
                        media.player.position = v * media.player.length;
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (media.player && media.player.length > 0) ? media.fmtTime(media.player.length) : ""
                color: Theme.fgFaint
                font.family: Theme.fontFamily
                font.pixelSize: 10
                width: 34
                horizontalAlignment: Text.AlignRight
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            component Control: Item {
                id: ctrl
                required property string glyph
                property real iconSize: 17
                property real boxSize: 42
                property bool primary: false
                signal tapped()

                width: boxSize
                height: boxSize

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: ctrl.primary
                        ? (ctrlMouse.containsMouse ? Theme.bgA : Theme.bgAltA)
                        : (ctrlMouse.containsMouse ? Theme.bgA : "transparent")
                    border.color: ctrl.primary ? Theme.brdr : "transparent"
                    border.width: 1
                }

                Text {
                    anchors.centerIn: parent
                    text: ctrl.glyph
                    color: (ctrlMouse.containsMouse || ctrl.primary) ? Theme.fg : Theme.fgDim
                    font.family: Theme.fontIcons
                    font.pixelSize: ctrl.iconSize
                }

                MouseArea {
                    id: ctrlMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ctrl.tapped()
                }
            }

            Control {
                glyph: Theme.iconPrev
                onTapped: if (media.player) media.player.previous()
            }
            Control {
                glyph: media.playing ? Theme.iconPause : Theme.iconPlay
                boxSize: 54
                iconSize: 21
                primary: true
                onTapped: if (media.player) media.player.togglePlaying()
            }
            Control {
                glyph: Theme.iconNext
                onTapped: if (media.player) media.player.next()
            }
        }

        Row {
            visible: media.volumeSupported
            width: parent.width
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.iconVolume
                color: Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 12
                width: 18
            }

            SliderBar {
                width: parent.width - 18 - 36 - 20
                anchors.verticalCenter: parent.verticalCenter
                value: media.player && media.player.volume ? media.player.volume : 0
                onMoved: v => {
                    if (media.player)
                        media.player.volume = v;
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round((media.player && media.player.volume ? media.player.volume : 0) * 100) + "%"
                color: Theme.fgFaint
                font.family: Theme.fontFamily
                font.pixelSize: 10
                width: 36
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Column {
        visible: !media.active
        anchors.centerIn: parent
        spacing: 14

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Theme.iconMusic
            color: Theme.fgFaint
            font.family: Theme.fontIcons
            font.pixelSize: 46
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing playing"
            color: Theme.fgFaint
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }
}
