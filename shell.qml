//@ pragma AppId kokuin
//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import TheLine.Ui
import Quickshell
import qs.modules.parts
import qs.services

// kokuin: a window on how a Linux machine boots, from the power button to a usable desktop. It reads everything from
// kokuin-cli (the boot recorder and explainer it is the face of): the app shows what the CLI finds, and runs its
// commands for you. Laid out like The Line's settings app: the pages on a spine, the current one in its panel.
//   Alt+1…6 or Alt+←→ change page · F5 reads the boot again · Ctrl+Q leaves
// KOKUIN_CLI=/path/to/kokuin-cli picks the CLI to use; KOKUIN_REDUCE_MOTION=1 turns the motion off.
ShellRoot {
    Binding { target: Theme; property: "accent"; value: Accent.accent }
    Binding { target: Anim; property: "reduce"; value: Quickshell.env("KOKUIN_REDUCE_MOTION") === "1" }

    FloatingWindow {
        id: win

        title: "Kokuin"
        implicitWidth: 1100
        implicitHeight: 700
        minimumSize: Qt.size(820, 520)
        color: Theme.surface
        visible: true

        Item {
            id: stage
            anchors.fill: parent
            focus: true

            Binding {
                target: Theme
                property: "scale"
                value: Math.max(0.7, Math.min(1.4, stage.height / 800, stage.width / 1280) * 0.82)
            }

            Component.onCompleted: Boot.open("", "This boot")

            Keys.onPressed: event => {
                const alt = (event.modifiers & Qt.AltModifier) !== 0;
                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Q) {
                    Qt.quit();
                } else if (event.key === Qt.Key_F5) {
                    Boot.reload();
                } else if (alt && event.key >= Qt.Key_1 && event.key <= Qt.Key_9 && event.key - Qt.Key_1 < Nav.pages.length) {
                    Nav.index = event.key - Qt.Key_1;
                } else if (alt && event.key === Qt.Key_Right) {
                    Nav.step(1);
                } else if (alt && event.key === Qt.Key_Left) {
                    Nav.step(-1);
                } else {
                    return;
                }
                event.accepted = true;
            }

            // the header: a mark, the app's name, the boot being read; the line under it
            Item {
                id: header
                width: parent.width
                height: Theme.u(56)

                Rectangle {
                    x: Theme.u(28)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.u(14)
                    height: 3
                    color: Theme.accent
                }
                Text {
                    x: Theme.u(54)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "KOKUIN"
                    color: Theme.muted
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(12)
                    font.weight: Font.DemiBold
                    font.letterSpacing: Theme.u(2)
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.u(28)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Cli.running > 0 || Boot.loading ? "reading…" : Boot.has ? Boot.name + "  ·  " + Fmt.when(Boot.info.started_at) : Cli.found ? "no boot open" : "kokuin-cli not found"
                    color: Cli.running > 0 || Boot.loading ? Theme.accentSoft : Cli.found ? Theme.faint : Theme.error
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.u(12)
                }
                Rectangle {
                    y: parent.height - 1
                    width: parent.width
                    height: 1
                    color: Theme.borderStrong
                }
            }

            Spine {
                id: spine
                y: header.height
                width: Theme.u(240)
                height: parent.height - header.height
                reach: panel.x
            }

            Rectangle {
                id: panel
                x: spine.width + Theme.u(14)
                y: header.height + Theme.u(24)
                width: parent.width - x - Theme.u(28)
                height: parent.height - y - Theme.u(52)
                color: Theme.panel
                border.width: 1
                border.color: Theme.border
                clip: true

                Loader {
                    id: loader
                    anchors.fill: parent
                    anchors.margins: Theme.u(32)
                    source: "modules/pages/" + Nav.current.charAt(0).toUpperCase() + Nav.current.slice(1) + "Page.qml"
                    onLoaded: item.forceActiveFocus()
                }
            }

            // what the keys do here
            Text {
                x: panel.x
                y: panel.y + panel.height + Theme.u(16)
                text: (loader.item?.hint ?? "") + (loader.item?.hint ? "   " : "") + "alt+←→ page"
                color: Theme.muted
                font.family: Theme.fontMono
                font.pixelSize: Theme.u(12)
            }
        }
    }
}
