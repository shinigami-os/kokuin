import QtQuick
import TheLine.Ui
import qs.modules.parts
import qs.services

// The boot in one screen (`kokuin-cli show`): what it ran on, the chain from the firmware to the desktop, the stages
// on one time axis, the milestones, the slowest steps, and what each data source could give.
PageFrame {
    id: page

    title: "Overview"
    sub: Boot.has ? "How long each part of the boot took, and what ran. Click a stage or a step to see what happened in it." : "The boot, from the power button to a usable desktop."
    hint: "↑↓ scroll   F5 read again"

    Component.onCompleted: Kb.load()

    Empty {
        anchors.fill: parent
        visible: !Boot.has
    }

    Flickable {
        id: flick
        anchors.fill: parent
        visible: Boot.has
        contentHeight: col.implicitHeight + Theme.u(20)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Keys.onUpPressed: contentY = Math.max(0, contentY - 60)
        Keys.onDownPressed: contentY = Math.min(Math.max(0, contentHeight - height), contentY + 60)

        Column {
            id: col
            width: flick.width - Theme.u(12)
            spacing: Theme.u(26)

            // the chain
            Item {
                width: parent.width
                height: chainFlow.implicitHeight

                Flow {
                    id: chainFlow
                    width: parent.width
                    spacing: Theme.u(8)

                    Repeater {
                        model: Boot.chain

                        Row {
                            id: link

                            required property string modelData
                            required property int index

                            spacing: Theme.u(8)

                            Text {
                                visible: link.index > 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: "→"
                                color: Theme.faint
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.u(14)
                            }
                            Rectangle {
                                width: chainText.implicitWidth + Theme.u(22)
                                height: Theme.u(32)
                                color: link.index === Boot.chain.length - 1 ? Theme.accentTint : "transparent"
                                border.width: 1
                                border.color: link.index === Boot.chain.length - 1 ? Theme.accent : Theme.borderStrong

                                Text {
                                    id: chainText
                                    anchors.centerIn: parent
                                    text: link.modelData
                                    color: Theme.text
                                    font.family: Theme.fontUi
                                    font.pixelSize: Theme.u(15)
                                }
                            }
                        }
                    }
                }
            }

            // how long
            Flow {
                width: parent.width
                spacing: Theme.u(40)

                Column {
                    spacing: Theme.u(2)
                    Text {
                        text: Boot.ready ? Fmt.length(Boot.ready.t_ns - Boot.startNs) : "—"
                        color: Theme.text
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.u(40)
                        font.weight: Font.Light
                    }
                    Text {
                        text: Boot.ready ? "from the first moment seen to a usable desktop" : "the desktop was not seen to be ready"
                        color: Theme.muted
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.u(11)
                    }
                }
                Column {
                    spacing: Theme.u(2)
                    visible: Boot.milestone("kernel_start") !== null && Boot.ready !== null
                    Text {
                        text: Boot.ready ? Fmt.length(Boot.ready.t_ns) : "—"
                        color: Theme.read
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.u(40)
                        font.weight: Font.Light
                    }
                    Text {
                        text: "from the kernel's start"
                        color: Theme.muted
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.u(11)
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.u(10)

                Label { name: "Stages" }
                StageAxis {
                    width: parent.width
                    onStageClicked: stage => {
                        Filter.only(stage);
                        Nav.go("timeline");
                    }
                }
            }

            Column {
                width: parent.width

                Label {
                    name: "The system"
                    bottomPadding: Theme.u(8)
                }
                InfoRow { label: "system"; value: Boot.info.os?.pretty_name ?? Boot.info.os?.name ?? "unknown" }
                InfoRow { label: "kernel"; value: "Linux " + Boot.info.kernel.release; explainId: "kernel.kmsg" }
                InfoRow {
                    label: "machine"
                    value: [Boot.info.machine.dmi?.sys_vendor, Boot.info.machine.dmi?.product_name].filter(x => x).join(" ") || (Boot.info.machine.arch ?? "")
                    explainId: "firmware.dmi"
                }
                InfoRow {
                    label: "firmware"
                    value: Boot.info.machine.firmware === "uefi" ? "UEFI" + (Boot.info.machine.uefi?.vendor ? " · " + Boot.info.machine.uefi.vendor : "") + (Boot.info.machine.uefi?.secure_boot !== undefined ? " · Secure Boot " + (Boot.info.machine.uefi.secure_boot ? "on" : "off") : "") : Boot.info.machine.firmware === "bios" ? "BIOS" : "unknown"
                    explainId: Boot.info.machine.firmware === "uefi" ? "firmware.uefi" : "firmware.bios"
                }
                InfoRow {
                    visible: Boot.info.bootloader !== undefined
                    height: visible ? Theme.u(34) : 0
                    label: "bootloader"
                    value: (Boot.info.bootloader?.name ?? Boot.info.bootloader?.id ?? "") + (Boot.info.bootloader?.version ? " " + Boot.info.bootloader.version : "")
                    explainId: Boot.info.bootloader?.explain_id ?? ""
                }
                InfoRow {
                    visible: Boot.info.init !== undefined
                    height: visible ? Theme.u(34) : 0
                    label: "init"
                    value: (Boot.info.init?.name ?? Boot.info.init?.id ?? "") + (Boot.info.init?.version ? " " + Boot.info.init.version : "")
                    explainId: Boot.info.init?.explain_id ?? ""
                }
                InfoRow {
                    label: "recorded"
                    value: Fmt.words(Boot.record?.capture?.method) + (Boot.record?.capture?.end_reason ? " · ended: " + Fmt.words(Boot.record?.capture?.end_reason).toLowerCase() : "")
                    explainId: "init.kokuin"
                }
            }

            Column {
                width: parent.width

                Label {
                    name: "Milestones"
                    bottomPadding: Theme.u(8)
                }
                Repeater {
                    model: Boot.milestones

                    Rectangle {
                        id: ms

                        required property var modelData

                        width: parent.width
                        height: Theme.u(32)
                        color: msHover.hovered && modelData.event !== undefined ? Theme.row : "transparent"

                        Text {
                            x: Theme.u(16)
                            anchors.verticalCenter: parent.verticalCenter
                            text: Fmt.words(ms.modelData.kind)
                            color: Theme.text
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.u(15)
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.u(16)
                            anchors.verticalCenter: parent.verticalCenter
                            text: Fmt.time(ms.modelData.t_ns) + (ms.modelData.confidence !== "exact" ? "  ·  " + ms.modelData.confidence : "")
                            color: Theme.muted
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.u(12)
                        }
                        HoverHandler {
                            id: msHover
                            cursorShape: ms.modelData.event !== undefined ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                        TapHandler {
                            onTapped: if (ms.modelData.event !== undefined)
                                Nav.event(ms.modelData.event)
                        }
                    }
                }
            }

            Repeater {
                model: [
                    { name: "Slowest steps", list: Boot.slowest, empty: "No step duration was measured in this record." },
                    { name: "Slowest kernel init functions", list: Boot.slowestInit, empty: "" }
                ]

                Column {
                    id: steps

                    required property var modelData

                    width: col.width
                    visible: modelData.list.length > 0 || modelData.empty !== ""

                    Label {
                        name: steps.modelData.name
                        bottomPadding: Theme.u(8)
                    }
                    Text {
                        visible: steps.modelData.list.length === 0
                        leftPadding: Theme.u(16)
                        text: steps.modelData.empty
                        color: Theme.muted
                        font.family: Theme.fontUi
                        font.pixelSize: Theme.u(14)
                    }
                    Repeater {
                        model: steps.modelData.list

                        Rectangle {
                            id: stepRow

                            required property var modelData

                            width: steps.width
                            height: Theme.u(34)
                            color: stepHover.hovered ? Theme.row : "transparent"

                            Rectangle {
                                width: 2
                                height: parent.height
                                color: Theme.accent
                                opacity: stepHover.hovered ? 1 : 0
                            }
                            Text {
                                x: Theme.u(16)
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - Theme.u(260)
                                text: stepRow.modelData.title
                                elide: Text.ElideRight
                                color: Theme.text
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.u(15)
                            }
                            Tag {
                                x: parent.width - Theme.u(240)
                                anchors.verticalCenter: parent.verticalCenter
                                label: stepRow.modelData.stage
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.u(16)
                                anchors.verticalCenter: parent.verticalCenter
                                text: Fmt.length(stepRow.modelData.dur_ns)
                                color: Theme.accentSoft
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.u(13)
                            }
                            HoverHandler {
                                id: stepHover
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: Nav.event(stepRow.modelData.id)
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width

                Label {
                    name: "What could be read"
                    bottomPadding: Theme.u(8)
                }
                Repeater {
                    model: Boot.sources

                    InfoRow {
                        required property var modelData

                        label: modelData.id
                        value: Fmt.words(modelData.status) + (modelData.reason ? " · " + modelData.reason : "")
                        valueColor: modelData.status === "ok" ? Theme.text : modelData.status === "partial" ? Theme.read : Theme.muted
                        explainId: modelData.explain_id ?? ""
                    }
                }
            }
        }
    }
}
