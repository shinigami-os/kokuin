import QtQuick
import TheLine.Ui
import qs.services

// The whole boot on one time axis: a ruler (the kernel starts at 0, what is before it is the firmware and the
// bootloader), the milestones as ticks on it, and one bar per stage under it. Stages overlap: services keep starting
// while the login screen comes up. A stage with no end was still running, or its end cannot be seen (an open bar).
Item {
    id: axis

    signal stageClicked(string stage)

    readonly property real labelW: Theme.u(110)
    readonly property real tailW: Theme.u(84)
    readonly property real plotW: Math.max(10, width - labelW - tailW)
    readonly property real from: Boot.startNs
    readonly property real span: Math.max(1, Boot.endNs - Boot.startNs)
    readonly property real rowH: Theme.u(28)
    readonly property real rulerH: Theme.u(36)

    implicitHeight: rulerH + Boot.stages.length * rowH + Theme.u(4)

    function at(ns) {
        return labelW + (ns - from) / span * plotW;
    }

    // ruler steps: the first that leaves at most ~10 ticks
    readonly property real step: {
        const choices = [1e7, 5e7, 1e8, 5e8, 1e9, 2e9, 5e9, 1e10, 3e10, 6e10, 1.2e11, 3e11, 6e11, 1.8e12, 3.6e12];
        return choices.find(c => span / c <= 10) ?? 3.6e12;
    }
    readonly property var ticks: {
        const out = [];
        for (let t = Math.ceil(from / step) * step; t <= from + span; t += step)
            out.push(t);
        return out;
    }

    // the ruler
    Rectangle {
        x: axis.labelW
        y: axis.rulerH - 1
        width: axis.plotW
        height: 1
        color: Theme.borderStrong
    }
    Repeater {
        model: axis.ticks

        Item {
            id: tick

            required property real modelData

            x: axis.at(modelData)
            y: 0
            height: axis.rulerH

            Rectangle {
                y: axis.rulerH - Theme.u(8)
                width: 1
                height: Theme.u(8)
                color: Theme.borderStrong
            }
            Text {
                x: -width / 2
                y: axis.rulerH - Theme.u(26)
                text: tick.modelData === 0 ? "kernel" : Fmt.time(tick.modelData)
                color: tick.modelData === 0 ? Theme.accentSoft : Theme.faint
                font.family: Theme.fontMono
                font.pixelSize: Theme.u(10)
            }
        }
    }
    // the milestones, ticks on the ruler; the kernel's start is the marker
    Repeater {
        model: Boot.milestones

        Rectangle {
            required property var modelData

            x: axis.at(modelData.t_ns) - (modelData.kind === "kernel_start" ? Theme.u(7) : 0)
            y: axis.rulerH - (modelData.kind === "kernel_start" ? 2 : Theme.u(14))
            width: modelData.kind === "kernel_start" ? Theme.u(14) : 1
            height: modelData.kind === "kernel_start" ? 3 : Theme.u(14)
            color: Theme.accent
            opacity: modelData.kind === "kernel_start" ? 1 : 0.55
        }
    }

    // the stages
    Column {
        y: axis.rulerH + Theme.u(4)
        width: parent.width

        Repeater {
            model: Boot.stages

            Item {
                id: row

                required property var modelData
                readonly property bool hasStart: modelData.start_ns !== undefined
                readonly property bool hasEnd: modelData.end_ns !== undefined
                readonly property bool timed: hasStart || hasEnd
                readonly property real x0: axis.at(hasStart ? modelData.start_ns : Boot.startNs)
                readonly property real x1: axis.at(hasEnd ? modelData.end_ns : Boot.endNs)
                readonly property bool open: hasStart && !hasEnd

                width: axis.width
                height: axis.rowH

                Rectangle {
                    anchors.fill: parent
                    color: hover.hovered ? Theme.row : "transparent"
                }
                Text {
                    x: Theme.u(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Fmt.words(row.modelData.stage)
                    color: hover.hovered ? Theme.text : Theme.read
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(14)
                }
                Rectangle {
                    visible: row.timed
                    x: row.x0
                    y: Theme.u(7)
                    width: Math.max(2, row.x1 - row.x0)
                    height: row.height - Theme.u(14)
                    color: Theme.accentTint
                    border.width: 1
                    border.color: hover.hovered ? Theme.accent : Theme.borderStrong
                }
                // an open end
                Rectangle {
                    visible: row.open
                    x: row.x1 - Theme.u(10)
                    y: Theme.u(7)
                    width: Theme.u(10)
                    height: row.height - Theme.u(14)
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.accentTint }
                        GradientStop { position: 1; color: Theme.bg }
                    }
                }
                Text {
                    x: axis.labelW + axis.plotW + Theme.u(10)
                    anchors.verticalCenter: parent.verticalCenter
                    text: !row.timed ? "not timed" : row.open ? "still going" : row.hasStart ? Fmt.length(row.modelData.end_ns - row.modelData.start_ns) : "ends " + Fmt.time(row.modelData.end_ns)
                    color: Theme.muted
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.u(11)
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: axis.stageClicked(row.modelData.stage)
                }
            }
        }
    }
}
