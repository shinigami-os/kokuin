import QtQuick
import TheLine.Ui
import qs.modules.parts
import qs.services

// Two boots side by side (`kokuin-cli diff`): what got slower or faster, milestone by milestone, stage by stage, step
// by step, and the programs that ran in only one of them. A boot is `last`, `-2`, the start of an id, a file or a folder.
PageFrame {
    id: page

    title: "Compare"
    sub: "What changed between two boots: later (+) or earlier (−) in the second one."
    hint: "tab switch field   enter compare"

    property var result: null
    property string error: ""
    property bool loading: false

    Component.onCompleted: {
        if (!Boots.loaded)
            Boots.refresh(false);
    }

    function compare() {
        if (loading)
            return;
        loading = true;
        error = "";
        Cli.json(["diff", a.text.trim() === "" ? "-2" : a.text.trim(), b.text.trim() === "" ? "last" : b.text.trim(), "--json"], (ok, data, msg) => {
            loading = false;
            if (ok)
                result = data;
            else
                error = msg;
        });
    }

    // what to pick a boot from: the newest few, by name
    readonly property var picks: ["last", "-2", "-3"].concat(Boots.list.slice(0, 4).map(x => Fmt.shortId(x.boot_id)))

    component Change: Rectangle {
        id: change

        property string label
        property var a
        property var b
        property var delta
        property bool times: true

        width: parent ? parent.width : 0
        height: Theme.u(32)
        color: hover.hovered ? Theme.row : "transparent"

        Text {
            x: Theme.u(16)
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Theme.u(340)
            text: change.label
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.fontUi
            font.pixelSize: Theme.u(14)
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.u(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u(18)

            Text {
                width: Theme.u(80)
                horizontalAlignment: Text.AlignRight
                text: change.times ? Fmt.time(change.a) : Fmt.length(change.a)
                color: Theme.muted
                font.family: Theme.fontMono
                font.pixelSize: Theme.u(12)
            }
            Text {
                width: Theme.u(80)
                horizontalAlignment: Text.AlignRight
                text: change.times ? Fmt.time(change.b) : Fmt.length(change.b)
                color: Theme.read
                font.family: Theme.fontMono
                font.pixelSize: Theme.u(12)
            }
            Text {
                width: Theme.u(90)
                horizontalAlignment: Text.AlignRight
                text: Fmt.delta(change.delta)
                color: change.delta > 0 ? Theme.error : change.delta < 0 ? Theme.ok : Theme.muted
                font.family: Theme.fontMono
                font.pixelSize: Theme.u(12)
                font.weight: Font.DemiBold
            }
        }
        HoverHandler {
            id: hover
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: col.implicitHeight + Theme.u(20)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: flick.width - Theme.u(12)
            spacing: Theme.u(24)

            Column {
                width: parent.width
                spacing: Theme.u(10)

                Row {
                    spacing: Theme.u(12)

                    Field {
                        id: a
                        width: Theme.u(260)
                        height: Theme.u(44)
                        prompt: "A"
                        placeholder: "-2"
                        KeyNavigation.tab: b
                        onAccepted: page.compare()
                    }
                    Field {
                        id: b
                        width: Theme.u(260)
                        height: Theme.u(44)
                        prompt: "B"
                        placeholder: "last"
                        KeyNavigation.tab: a
                        onAccepted: page.compare()
                    }
                    Btn {
                        label: page.loading ? "Comparing…" : "Compare"
                        primary: true
                        enabled: !page.loading
                        onClicked: page.compare()
                    }
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u(6)

                    Text {
                        height: Theme.u(22)
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: Theme.u(8)
                        text: "fill A with"
                        color: Theme.faint
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.u(11)
                    }
                    Repeater {
                        model: page.picks

                        Tag {
                            required property string modelData

                            label: modelData
                            selectable: true
                            onClicked: a.text = modelData
                        }
                    }
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u(6)

                    Text {
                        height: Theme.u(22)
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: Theme.u(8)
                        text: "fill B with"
                        color: Theme.faint
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.u(11)
                    }
                    Repeater {
                        model: page.picks

                        Tag {
                            required property string modelData

                            label: modelData
                            selectable: true
                            onClicked: b.text = modelData
                        }
                    }
                }
                Text {
                    visible: page.error !== ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: page.error
                    color: Theme.error
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(14)
                }
                Text {
                    visible: page.result === null && page.error === "" && !page.loading
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Leave A and B empty to compare the last two recorded boots. Two boots need to be recorded, or saved as records: see the Boots page."
                    color: Theme.muted
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(14)
                }
            }

            Column {
                width: parent.width
                spacing: Theme.u(24)
                visible: page.result !== null

                Row {
                    spacing: Theme.u(40)

                    Repeater {
                        model: page.result ? [{ name: "A", side: page.result.a }, { name: "B", side: page.result.b }] : []

                        Column {
                            required property var modelData

                            spacing: Theme.u(2)

                            Text {
                                text: modelData.name + "  ·  " + Fmt.when(modelData.side.started_at)
                                color: Theme.text
                                font.family: Theme.fontUi
                                font.pixelSize: Theme.u(16)
                            }
                            Text {
                                text: "Linux " + modelData.side.kernel_release + "  ·  " + Fmt.words(modelData.side.method) + "  ·  " + Fmt.shortId(modelData.side.boot_id)
                                color: Theme.muted
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.u(11)
                            }
                        }
                    }
                }

                Repeater {
                    model: page.result ? [
                        { name: "Milestones", rows: page.result.milestones.map(c => ({ label: Fmt.words(c.kind), a: c.a_ns, b: c.b_ns, d: c.delta_ns })), times: true },
                        { name: "Stages", rows: page.result.stages.map(c => ({ label: Fmt.words(c.stage), a: c.a_ns, b: c.b_ns, d: c.delta_ns })), times: false },
                        { name: "Steps that changed", rows: page.result.steps.map(c => ({ label: c.title, a: c.a_ns, b: c.b_ns, d: c.delta_ns })), times: false }
                    ] : []

                    Column {
                        id: group

                        required property var modelData

                        width: col.width
                        visible: modelData.rows.length > 0

                        Label {
                            name: group.modelData.name
                            bottomPadding: Theme.u(8)
                        }
                        Repeater {
                            model: group.modelData.rows

                            Change {
                                required property var modelData

                                label: modelData.label
                                a: modelData.a
                                b: modelData.b
                                delta: modelData.d
                                times: group.modelData.times
                            }
                        }
                    }
                }

                Repeater {
                    model: page.result ? [
                        { name: "Only in B", list: page.result.new_programs },
                        { name: "Only in A", list: page.result.gone_programs }
                    ] : []

                    Column {
                        id: progs

                        required property var modelData

                        width: col.width
                        visible: modelData.list.length > 0
                        spacing: Theme.u(8)

                        Label { name: progs.modelData.name + " (programs)" }
                        Flow {
                            width: parent.width
                            spacing: Theme.u(6)

                            Repeater {
                                model: progs.modelData.list

                                Tag {
                                    required property string modelData

                                    label: modelData
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
