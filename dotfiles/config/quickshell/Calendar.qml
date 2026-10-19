pragma ComponentBehavior: Bound

import QtQuick
import "Theme.js" as Theme

Item {
    id: cal

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    function buildCells() {
        const first = new Date(viewYear, viewMonth, 1);
        const lead = (first.getDay() + 6) % 7;
        const start = new Date(viewYear, viewMonth, 1 - lead);
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({
                label: String(d.getDate()),
                inMonth: d.getMonth() === viewMonth,
                isToday: d.getFullYear() === today.getFullYear()
                    && d.getMonth() === today.getMonth()
                    && d.getDate() === today.getDate(),
                weekend: d.getDay() === 0 || d.getDay() === 6
            });
        }
        return out;
    }
    property var cells: buildCells()

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }
    function goToday() {
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }

    implicitWidth: 252
    implicitHeight: header.height + 8 + weekdays.height + 4 + grid.height + 20

    Item {
        id: header
        width: parent.width
        height: 30

        Text {
            anchors.centerIn: parent
            text: cal.monthNames[cal.viewMonth] + "  " + cal.viewYear
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        component Nav: Rectangle {
            id: nav
            required property string glyph
            signal go()

            width: 24
            height: 24
            radius: Theme.radius - 2
            color: navMouse.containsMouse ? Theme.bgAltA : "transparent"

            Text {
                anchors.centerIn: parent
                text: nav.glyph
                color: navMouse.containsMouse ? Theme.fg : Theme.fgDim
                font.family: Theme.fontIcons
                font.pixelSize: 11
            }

            MouseArea {
                id: navMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: nav.go()
            }
        }

        Nav {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            glyph: Theme.iconChevronLeft || "\uf053"
            onGo: cal.shiftMonth(-1)
        }

        Nav {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            glyph: Theme.iconChevronRight || "\uf054"
            onGo: cal.shiftMonth(1)
        }
    }

    Row {
        id: weekdays
        anchors { top: header.bottom; topMargin: 8 }
        width: parent.width

        Repeater {
            model: cal.dayNames

            delegate: Text {
                required property string modelData

                width: parent.width / 7
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.fgFaint
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }
    }

    Grid {
        id: grid
        anchors { top: weekdays.bottom; topMargin: 4 }
        width: parent.width
        columns: 7

        Repeater {
            model: cal.cells

            delegate: Item {
                id: dayCell
                required property var modelData

                width: parent.width / 7
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: 13
                    color: dayCell.modelData.isToday ? Theme.accent
                        : (cellMouse.containsMouse && dayCell.modelData.inMonth) ? Theme.bgAltA
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.modelData.label
                        color: dayCell.modelData.isToday ? Theme.fg
                            : !dayCell.modelData.inMonth ? Theme.fgFaint
                            : dayCell.modelData.weekend ? Theme.fgDim
                            : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: dayCell.modelData.isToday ? Font.Bold : Font.Normal
                    }
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
