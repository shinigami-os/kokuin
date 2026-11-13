import QtQuick
import TheLine.Ui
import qs.services

// The pages, as the settings app's spine: a number left of a vertical line, a short tick across it, the name; the
// current one has the accent marker on the line and a line running from its name to the panel (`reach`).
Item {
    id: spine

    property real reach: width
    readonly property real lineX: Theme.u(52)
    readonly property real rowH: Theme.u(36)

    Rectangle {
        x: spine.lineX
        width: 1
        height: parent.height
        color: Theme.borderStrong
    }

    Column {
        y: Theme.u(24)
        width: parent.width

        Repeater {
            model: Nav.pages

            Item {
                id: step

                required property var modelData
                required property int index
                readonly property bool now: index === Nav.index
                readonly property bool unavailable: modelData.needsBoot && !Boot.has

                width: spine.width
                height: spine.rowH

                Text {
                    x: Theme.u(18)
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(step.index + 1).padStart(2, "0")
                    color: step.now ? Theme.accentSoft : Theme.faint
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.u(11)
                }
                Rectangle {
                    x: spine.lineX - Theme.u(3)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.u(7)
                    height: 1
                    color: Theme.borderStrong
                }
                Rectangle {
                    x: spine.lineX - 1
                    y: Theme.u(7)
                    width: 3
                    height: parent.height - Theme.u(14)
                    color: Theme.accent
                    opacity: step.now ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Anim.base; easing.type: Anim.easing }
                    }
                }
                Text {
                    id: label
                    x: spine.lineX + Theme.u(18)
                    anchors.verticalCenter: parent.verticalCenter
                    text: step.modelData.name
                    color: step.now ? Theme.text : hover.hovered ? Theme.text : step.unavailable ? Theme.faint : Theme.muted
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(step.now ? 16 : 15)

                    Behavior on color {
                        ColorAnimation { duration: Anim.hover }
                    }
                }
                Rectangle {
                    x: label.x + label.implicitWidth + Theme.u(14)
                    anchors.verticalCenter: parent.verticalCenter
                    width: step.now ? Math.max(0, spine.reach - x) : 0
                    height: 1
                    color: Theme.borderStrong

                    Behavior on width {
                        NumberAnimation { duration: Anim.panel; easing.type: Anim.easing }
                    }
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: Nav.index = step.index
                }
            }
        }
    }
}
