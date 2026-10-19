import QtQuick
import Quickshell.Io
import "Theme.js" as Theme

MouseArea {
    id: root

    property bool vertical: false
    property string cpu: "0"
    property string mem: "0"
    property string swap: "0"
    property string up: "0B"
    property string down: "0B"

    implicitWidth: vertical ? col.implicitWidth : row.implicitWidth
    implicitHeight: vertical ? col.implicitHeight : row.implicitHeight

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
        const centre = root.mapToItem(null, root.width / 2, 0).x;
        toggle.command = [ "sh", "-c", "qs ipc call systempanel toggleAt " + Math.round(centre) ];
        toggle.startDetached();
    }

    Process {
        id: proc
        command: ["sh", "-c", "$HOME/.scripts/status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                const parts = this.text.trim().split(/\s+/);
                for (let i = 0; i < parts.length; i++) {
                    const eq = parts[i].indexOf("=");
                    if (eq > 0)
                        out[parts[i].slice(0, eq)] = parts[i].slice(eq + 1);
                }
                root.cpu = out.cpu || "0";
                root.mem = out.mem || "0";
                root.swap = out.swap || "0";
                root.up = out.up || "0B/s";
                root.down = out.down || "0B/s";
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: toggle
    }

    component MetricRow: Row {
        id: metric
        required property string glyph
        required property string value
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: metric.glyph
            color: root.containsMouse ? Theme.fg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: Theme.fontSize
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: metric.value
            color: root.containsMouse ? Theme.fg : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    component MetricCol: Column {
        id: metric
        required property string glyph
        required property string value
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: metric.glyph
            color: root.containsMouse ? Theme.fg : Theme.fgDim
            font.family: Theme.fontIcons
            font.pixelSize: Theme.fontSize
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: metric.value
            color: root.containsMouse ? Theme.fg : Theme.fgDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
        }
    }

    Row {
        id: row
        visible: !root.vertical
        spacing: 8

        MetricRow {
            glyph: Theme.iconCpu
            value: root.cpu + "%"
        }
        MetricRow {
            glyph: Theme.iconMemory
            value: root.mem + "%"
        }
        MetricRow {
            glyph: Theme.iconSwap
            value: root.swap + "%"
        }
        MetricRow {
            glyph: Theme.iconUpload
            value: root.up
        }
        MetricRow {
            glyph: Theme.iconDownload
            value: root.down
        }
    }

    Column {
        id: col
        visible: root.vertical
        spacing: 4

        MetricCol {
            glyph: Theme.iconCpu
            value: root.cpu + "%"
            width: col.width
        }
        MetricCol {
            glyph: Theme.iconMemory
            value: root.mem + "%"
            width: col.width
        }
        MetricCol {
            glyph: Theme.iconSwap
            value: root.swap + "%"
            width: col.width
        }
        MetricCol {
            glyph: Theme.iconUpload
            value: root.up
            width: col.width
        }
        MetricCol {
            glyph: Theme.iconDownload
            value: root.down
            width: col.width
        }
    }
}
