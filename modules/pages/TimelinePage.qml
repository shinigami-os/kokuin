import QtQuick
import TheLine.Ui
import qs.modules.parts
import qs.services

// Everything that happened, in order (`kokuin-cli timeline`): filtered by stage, kind, source and a search, and next
// to the selected event its details and why it happens.
PageFrame {
    id: page

    title: "Timeline"
    sub: Boot.has ? shown.length + " of " + Boot.events.length + " events" + (Filter.any ? " (filtered)" : "") + ". The time is on the boot clock: 0 is the start of the kernel." : "Everything that happened during the boot, in order."
    hint: "↑↓ move   enter explain   / search   x hide raw   esc clear filters"

    readonly property var stageNames: ["firmware", "bootloader", "kernel", "initramfs", "init", "services", "graphical", "session", "runtime"]
    readonly property var regex: {
        try {
            return Filter.grep !== "" ? new RegExp(Filter.grep, "i") : null;
        } catch (e) {
            return null;
        }
    }
    readonly property bool badRegex: Filter.grep !== "" && regex === null
    readonly property var shown: Boot.events.filter(e => Filter.passes(e, regex))
    property int sel: 0
    readonly property var current: shown[sel] ?? null

    function select(i) {
        sel = Math.max(0, Math.min(shown.length - 1, i));
        list.positionViewAtIndex(sel, ListView.Contain);
    }

    // coming from another page to one event
    function goToEvent() {
        if (Nav.eventId < 0)
            return;
        let i = shown.findIndex(e => e.id === Nav.eventId);
        if (i < 0) {
            Filter.clear();
            i = Boot.events.findIndex(e => e.id === Nav.eventId);
        }
        Nav.eventId = -1;
        if (i >= 0)
            Qt.callLater(() => select(i));
    }
    Component.onCompleted: {
        Kb.load();
        goToEvent();
    }
    onShownChanged: if (sel >= shown.length)
        sel = Math.max(0, shown.length - 1)

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
            select(sel + 1);
        } else if (event.key === Qt.Key_Up) {
            select(sel - 1);
        } else if (event.key === Qt.Key_PageDown) {
            select(sel + 12);
        } else if (event.key === Qt.Key_PageUp) {
            select(sel - 12);
        } else if (event.key === Qt.Key_Home) {
            select(0);
        } else if (event.key === Qt.Key_End) {
            select(shown.length - 1);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            Nav.explain(current?.explain_id);
        } else if (event.text === "/") {
            search.forceActive();
        } else if (event.text === "x") {
            Filter.hideRaw = !Filter.hideRaw;
        } else if (event.key === Qt.Key_Escape) {
            Filter.clear();
        } else {
            return;
        }
        event.accepted = true;
    }

    Empty {
        anchors.fill: parent
        visible: !Boot.has
    }

    Item {
        anchors.fill: parent
        visible: Boot.has

        // the filters
        Column {
            id: filters
            width: parent.width
            spacing: Theme.u(8)

            Row {
                spacing: Theme.u(12)

                Field {
                    id: search
                    width: Theme.u(320)
                    height: Theme.u(40)
                    placeholder: "search a title or a message (a regular expression)"
                    invalid: page.badRegex
                    text: Filter.grep
                    onTextChanged: Filter.grep = text
                    onAccepted: page.forceActiveFocus()
                }
                Tag {
                    anchors.verticalCenter: parent.verticalCenter
                    label: "hide raw kernel lines"
                    selectable: true
                    lit: Filter.hideRaw
                    onClicked: Filter.hideRaw = !Filter.hideRaw
                }
                Tag {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Filter.any
                    label: "clear filters"
                    selectable: true
                    onClicked: Filter.clear()
                }
            }

            Flow {
                width: parent.width
                spacing: Theme.u(6)

                Label {
                    name: "stage"
                    width: Theme.u(54)
                    height: Theme.u(22)
                    verticalAlignment: Text.AlignVCenter
                }
                Repeater {
                    model: page.stageNames.filter(s => Boot.stages.some(x => x.stage === s) || Boot.events.some(e => e.stage === s))

                    Tag {
                        required property string modelData

                        label: modelData
                        selectable: true
                        lit: Filter.stages.indexOf(modelData) >= 0
                        onClicked: Filter.stages = Filter.toggle(Filter.stages, modelData)
                    }
                }
            }
            Flow {
                width: parent.width
                spacing: Theme.u(6)

                Label {
                    name: "kind"
                    width: Theme.u(54)
                    height: Theme.u(22)
                    verticalAlignment: Text.AlignVCenter
                }
                Repeater {
                    model: Boot.kindsSeen

                    Tag {
                        required property string modelData

                        label: modelData
                        selectable: true
                        lit: Filter.kinds.indexOf(modelData) >= 0
                        onClicked: Filter.kinds = Filter.toggle(Filter.kinds, modelData)
                    }
                }
            }
            Flow {
                width: parent.width
                spacing: Theme.u(6)

                Label {
                    name: "source"
                    width: Theme.u(54)
                    height: Theme.u(22)
                    verticalAlignment: Text.AlignVCenter
                }
                Repeater {
                    model: Boot.sourcesSeen

                    Tag {
                        required property string modelData

                        label: modelData
                        selectable: true
                        lit: Filter.sources.indexOf(modelData) >= 0
                        onClicked: Filter.sources = Filter.toggle(Filter.sources, modelData)
                    }
                }
            }
        }

        // the events
        ListView {
            id: list
            y: filters.height + Theme.u(14)
            width: parent.width * 0.58
            height: parent.height - y
            clip: true
            model: page.shown
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: page.sel

            Text {
                visible: page.shown.length === 0
                text: "No event matches."
                color: Theme.muted
                font.family: Theme.fontUi
                font.pixelSize: Theme.u(15)
            }

            delegate: Rectangle {
                id: ev

                required property var modelData
                required property int index
                readonly property bool on: index === page.sel

                width: list.width
                height: Theme.u(32)
                color: on || evHover.hovered ? Theme.row : "transparent"

                Rectangle {
                    width: 2
                    height: parent.height
                    color: Theme.accent
                    opacity: ev.on ? 1 : 0
                }
                Text {
                    x: Theme.u(12)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.u(78)
                    text: ev.modelData.t_ns !== undefined ? Fmt.time(ev.modelData.t_ns) : "—"
                    color: ev.modelData.confidence === "exact" ? Theme.read : Theme.faint
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.u(12)
                }
                Text {
                    x: Theme.u(96)
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.u(96) - Theme.u(78)
                    text: ev.modelData.title
                    elide: Text.ElideRight
                    color: ev.modelData.explain_id ? Theme.text : Theme.muted
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(14)
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.u(12)
                    anchors.verticalCenter: parent.verticalCenter
                    text: ev.modelData.dur_ns ? Fmt.length(ev.modelData.dur_ns) : ""
                    color: Theme.accentSoft
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.u(12)
                }
                HoverHandler {
                    id: evHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    onTapped: page.select(ev.index)
                }
            }
        }

        // the selected one
        Flickable {
            id: detail
            x: list.width + Theme.u(18)
            y: list.y
            width: parent.width - x
            height: list.height
            clip: true
            contentHeight: info.implicitHeight + Theme.u(10)
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: info
                width: detail.width - Theme.u(8)
                spacing: Theme.u(12)
                visible: page.current !== null

                Text {
                    width: parent.width
                    text: page.current?.title ?? ""
                    wrapMode: Text.WordWrap
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(18)
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u(6)

                    Tag { label: page.current?.stage ?? "" }
                    Tag { label: page.current?.kind ?? "" }
                    Tag { label: page.current?.source ?? "" }
                    Tag { label: page.current?.confidence ?? "" }
                    Tag {
                        visible: (page.current?.level ?? "") !== ""
                        label: page.current?.level ?? ""
                    }
                }
                Text {
                    text: (page.current?.t_ns !== undefined ? Fmt.time(page.current.t_ns) : "no clock: placed by order") + (page.current?.dur_ns ? "   ·   lasted " + Fmt.length(page.current.dur_ns) : "")
                    color: Theme.read
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.u(13)
                }
                Text {
                    visible: (page.current?.message ?? "") !== ""
                    width: parent.width
                    text: page.current?.message ?? ""
                    wrapMode: Text.WrapAnywhere
                    color: Theme.muted
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.u(12)
                }
                Column {
                    width: parent.width
                    spacing: Theme.u(2)
                    visible: Object.keys(page.current?.data ?? {}).length > 0

                    Label {
                        name: "data"
                        bottomPadding: Theme.u(4)
                    }
                    Repeater {
                        model: Object.keys(page.current?.data ?? {})

                        Text {
                            required property string modelData

                            width: info.width
                            text: modelData + "  " + JSON.stringify(page.current.data[modelData])
                            wrapMode: Text.WrapAnywhere
                            color: Theme.muted
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.u(11)
                        }
                    }
                }
                Column {
                    width: parent.width
                    spacing: Theme.u(4)
                    visible: page.current?.process !== undefined && Boot.process(page.current.process) !== null

                    Label {
                        name: "program"
                        bottomPadding: Theme.u(4)
                    }
                    Text {
                        width: parent.width
                        readonly property var proc: Boot.process(page.current?.process) ?? ({})
                        text: (proc.comm ?? "") + (proc.pid !== undefined ? "  ·  pid " + proc.pid : "") + (proc.cmdline ? "\n" + proc.cmdline.join(" ") : "")
                        wrapMode: Text.WrapAnywhere
                        color: Theme.muted
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.u(11)
                    }
                }
                Btn {
                    visible: (page.current?.explain_id ?? "") !== "" && Kb.has(page.current?.explain_id)
                    label: "Why this happens"
                    key: "↵"
                    primary: true
                    onClicked: Nav.explain(page.current.explain_id)
                }
            }
        }
    }
}
