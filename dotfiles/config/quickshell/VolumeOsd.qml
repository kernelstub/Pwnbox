import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "Theme.js" as Theme

Scope {
    id: root
    property bool shown: false
    property var mainScreen: null

    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

        function onVolumeChanged() {
            root.shown = true;
            hideTimer.restart();
        }
        function onMutedChanged() {
            root.shown = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.shown = false
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            screen: root.mainScreen
            anchors {
                bottom: true
                left: true
                right: true
            }
            margins.bottom: 120
            exclusiveZone: 0
            implicitWidth: 420
            implicitHeight: 46
            color: "transparent"
            surfaceFormat.opaque: false
            mask: Region {}

            Rectangle {
                anchors.centerIn: parent
                width: 420
                height: 46
                radius: Theme.radius
                color: Theme.bgA
                border.color: Theme.accent
                border.width: 2

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.muted) ? Theme.iconMute : Theme.iconVolume
                        color: Theme.fgDim
                        font.family: Theme.fontIcons
                        font.pixelSize: 12
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 280
                        height: 8
                        radius: 4
                        color: Theme.accent

                        Rectangle {
                            width: parent.width * Math.min(1, Math.max(0, Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0))
                            height: parent.height
                            radius: 4
                            color: Theme.fg
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round((Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0) * 100) + "%"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
