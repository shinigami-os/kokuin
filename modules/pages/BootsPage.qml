import QtQuick
import Quickshell
import TheLine.Ui
import qs.modules.parts
import qs.services

// Which boot to look at, and keeping one: the current boot (`show`), a recorded one (`list`), a saved record or a
// raw snapshot (`show FILE`), and `capture` to save the current boot as a record, with the raw data if wanted.
PageFrame {
    id: page

    title: "Boots"
    sub: "Open the boot you are in, one that was recorded, or a record saved by someone else. Save this boot to read it later or elsewhere."
    hint: "↑↓ move   enter open   r read the list again"

    property int sel: 0
    property string saveMessage: ""
    property bool saveFailed: false
    property bool saveAsRoot: false
    property bool saveRaw: false
    property bool saving: false

    Component.onCompleted: {
        if (!Boots.loaded)
            Boots.refresh(false);
    }

    function openBoot(i) {
        const b = Boots.list[i];
        if (!b)
            return;
        Boot.open(b.boot_id, Fmt.when(b.started_at));
        Nav.go("overview");
    }

    function save() {
        if (saving || fileField.text.trim() === "")
            return;
        saving = true;
        saveMessage = "";
        const file = fileField.text.trim();
        const raw = saveRaw ? rawField.text.trim() : "";
        const done = (ok, text, msg) => {
            saving = false;
            saveFailed = !ok;
            saveMessage = ok ? "Saved to " + file + (raw !== "" ? " (and the raw data in " + raw + ")" : "") : msg;
        };
        if (saveAsRoot) {
            Cli.root_sh("bin=$1; user=$2; out=$3; raw=$4; if [ -n \"$raw\" ]; then \"$bin\" capture -o \"$out\" --raw \"$raw\"; else \"$bin\" capture -o \"$out\"; fi && chown \"$user\" \"$out\" && { [ -z \"$raw\" ] || chown -R \"$user\" \"$raw\"; }",
                [Quickshell.env("USER"), file, raw], done);
        } else {
            Cli.text(["capture", "-o", file].concat(raw !== "" ? ["--raw", raw] : []), done);
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
            sel = Math.min(Boots.list.length - 1, sel + 1);
        } else if (event.key === Qt.Key_Up) {
            sel = Math.max(0, sel - 1);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            openBoot(sel);
        } else if (event.text === "r") {
            Boots.refresh(false);
        } else {
            return;
        }
        event.accepted = true;
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
            spacing: Theme.u(26)

            Column {
                width: parent.width
                spacing: Theme.u(12)

                Label { name: "Read" }
                Row {
                    spacing: Theme.u(12)

                    Btn {
                        label: "This boot"
                        primary: true
                        onClicked: {
                            Boot.open("", "This boot");
                            Nav.go("overview");
                        }
                    }
                    Btn {
                        label: "This boot, as root"
                        onClicked: {
                            Boot.readAsRoot();
                            Nav.go("overview");
                        }
                    }
                }
                Row {
                    spacing: Theme.u(12)

                    Field {
                        id: openField
                        width: Theme.u(560)
                        height: Theme.u(44)
                        placeholder: "a record file, or a folder saved with the raw data"
                        onAccepted: openBtn.clicked()
                    }
                    Btn {
                        id: openBtn
                        label: "Open"
                        enabled: openField.text.trim() !== ""
                        onClicked: {
                            const p = openField.text.trim();
                            Boot.open(p, p.split("/").filter(x => x).pop());
                            Nav.go("overview");
                        }
                    }
                }
            }

            Column {
                width: parent.width

                Row {
                    spacing: Theme.u(16)
                    bottomPadding: Theme.u(8)

                    Label {
                        name: "Recorded boots"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Tag {
                        anchors.verticalCenter: parent.verticalCenter
                        label: Boots.loading ? "reading…" : "read the list again"
                        selectable: true
                        onClicked: Boots.refresh(false)
                    }
                    Tag {
                        anchors.verticalCenter: parent.verticalCenter
                        label: "as root"
                        selectable: true
                        onClicked: Boots.refresh(true)
                    }
                }
                Text {
                    visible: Boots.list.length === 0
                    width: parent.width
                    leftPadding: Theme.u(16)
                    wrapMode: Text.WordWrap
                    text: Boots.error !== "" ? Boots.error : Boots.loading ? "" : "No boot was recorded. Record the next ones from the Recorder page, then reboot."
                    color: Boots.error !== "" ? Theme.error : Theme.muted
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(14)
                }
                Repeater {
                    model: Boots.list

                    ListRow {
                        required property var modelData
                        required property int index

                        label: Fmt.when(modelData.started_at)
                        detail: Fmt.shortId(modelData.boot_id) + "  ·  " + Fmt.words(modelData.method)
                        sub: (modelData.session_ready_ns !== undefined && modelData.session_ready_ns !== null ? "ready after " + Fmt.length(modelData.session_ready_ns) : "never seen ready") + (modelData.current ? "  ·  this boot" : "")
                        selected: index === page.sel
                        onClicked: {
                            page.sel = index;
                            page.openBoot(index);
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.u(12)

                Label { name: "Save this boot" }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "A record is a JSON file anyone can read. The raw data is everything kokuin read, so the record can be rebuilt later or on another machine; it holds the command line of every running program: look at it before sharing it."
                    color: Theme.muted
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(14)
                }
                Field {
                    id: fileField
                    width: Theme.u(560)
                    height: Theme.u(44)
                    placeholder: "where to save the record"
                    text: Quickshell.env("HOME") + "/boot-record.json"
                    onAccepted: page.save()
                }
                Toggle {
                    width: Theme.u(560)
                    label: "Also save the raw data"
                    sub: "a new folder"
                    on: page.saveRaw
                    onClicked: page.saveRaw = !page.saveRaw
                }
                Field {
                    id: rawField
                    visible: page.saveRaw
                    width: Theme.u(560)
                    height: Theme.u(44)
                    placeholder: "a folder that does not exist yet"
                    text: Quickshell.env("HOME") + "/boot-raw"
                    onAccepted: page.save()
                }
                Toggle {
                    width: Theme.u(560)
                    label: "As root"
                    sub: "sees the TPM log and the whole kernel log"
                    on: page.saveAsRoot
                    onClicked: page.saveAsRoot = !page.saveAsRoot
                }
                Row {
                    spacing: Theme.u(16)

                    Btn {
                        label: page.saving ? "Saving…" : "Save"
                        primary: true
                        enabled: !page.saving
                        onClicked: page.save()
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.u(520)
                        text: page.saveMessage
                        elide: Text.ElideMiddle
                        color: page.saveFailed ? Theme.error : Theme.ok
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.u(12)
                    }
                }
            }
        }
    }
}
