import QtQuick
import TheLine.Ui
import qs.modules.parts
import qs.services

// Whether kokuin records boots, and what it can read on this machine (`kokuin-cli status`). The commands that change
// the system (enable, disable, deep, the EFI probe) are shown first with `--dry-run`, then done as root.
PageFrame {
    id: page

    title: "Recorder"
    sub: "Record the next boots to see every program and every kernel step. Nothing changes until you press an action, and each one can be previewed."
    hint: "r read again"

    Component.onCompleted: Recorder.refresh(false)

    Keys.onPressed: event => {
        if (event.text === "r") {
            Recorder.refresh(false);
            event.accepted = true;
        }
    }

    component Action: Column {
        id: act

        property string name
        property string about
        property var args
        property string verb
        property bool danger: false
        property bool enabled: true

        width: parent ? parent.width : 0
        spacing: Theme.u(8)

        Text {
            text: act.name
            color: Theme.text
            font.family: Theme.fontUi
            font.pixelSize: Theme.u(16)
        }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: act.about
            color: Theme.muted
            font.family: Theme.fontUi
            font.pixelSize: Theme.u(13)
        }
        Row {
            spacing: Theme.u(12)

            Btn {
                label: "Preview"
                enabled: act.enabled && !Recorder.busy
                onClicked: Recorder.change(act.args, act.verb, true)
            }
            Btn {
                label: act.name
                danger: act.danger
                primary: !act.danger
                enabled: act.enabled && !Recorder.busy
                onClicked: Recorder.change(act.args, act.verb, false)
            }
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
            spacing: Theme.u(28)

            Column {
                width: parent.width
                spacing: Theme.u(10)

                Label { name: "State" }
                Text {
                    visible: Recorder.error !== ""
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: Recorder.error
                    color: Theme.error
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(14)
                }
                Repeater {
                    model: Recorder.recorder ? [
                        { k: "Recorder", v: Recorder.recorder.installed ? (Recorder.recorder.enabled ? "recording every boot" : "installed, off") : "not installed" },
                        { k: "Boots recorded", v: String(Recorder.recorder.boots_recorded) },
                        { k: "Deep boot", v: Recorder.recorder.deep_armed ? "armed for the next boot" : "not armed" },
                        { k: "EFI probe", v: Recorder.recorder.probe_armed ? "armed for the next boot" : Recorder.recorder.probe_entry ? "installed" : "not installed" },
                        { k: "Running as", v: Recorder.status.root ? "root" : "a normal user" }
                    ] : []

                    InfoRow {
                        required property var modelData

                        label: modelData.k
                        value: modelData.v
                    }
                }
                Row {
                    spacing: Theme.u(12)

                    Btn {
                        label: Recorder.loading ? "Reading…" : "Read again"
                        onClicked: Recorder.refresh(false)
                    }
                    Btn {
                        label: "Read as root"
                        onClicked: Recorder.refresh(true)
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.u(20)

                Label { name: "Actions" }
                Action {
                    name: "Record every boot"
                    about: "Adds kokuin-init to the kernel command line, so each boot is recorded from the start."
                    args: ["enable"]
                    verb: "recording every boot"
                }
                Action {
                    name: "Stop recording"
                    about: "Takes kokuin-init off the kernel command line. Records already made are kept."
                    args: ["disable"]
                    verb: "stopping the recorder"
                    danger: true
                }
                Action {
                    name: "Deep boot"
                    about: "Records the next boot only, with kernel tracing: the time of each kernel init function and every program, even the shortest. It disarms itself afterwards."
                    args: ["deep"]
                    verb: "arming a deep boot"
                }
                Action {
                    name: "Cancel deep boot"
                    about: "Disarms a deep boot that has not happened yet."
                    args: ["deep", "--cancel"]
                    verb: "cancelling the deep boot"
                    enabled: Recorder.recorder?.deep_armed ?? false
                }
            }

            Column {
                width: parent.width
                spacing: Theme.u(20)

                Label { name: "EFI probe" }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Times the firmware and the bootloader for one boot, by running before the bootloader. It adds a boot entry on the EFI system partition that the firmware never starts by itself."
                    color: Theme.muted
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(13)
                }
                Action {
                    name: "Install the probe"
                    about: "Puts the probe on the EFI system partition, with a boot entry of its own."
                    args: ["probe", "install"]
                    verb: "installing the probe"
                }
                Action {
                    name: "Arm the probe"
                    about: "Makes the next boot, and only it, go through the probe."
                    args: ["probe", "arm"]
                    verb: "arming the probe"
                }
                Action {
                    name: "Disarm the probe"
                    about: "Undoes arming before you reboot."
                    args: ["probe", "disarm"]
                    verb: "disarming the probe"
                }
                Action {
                    name: "Remove the probe"
                    about: "Removes the probe and its boot entry."
                    args: ["probe", "remove"]
                    verb: "removing the probe"
                    danger: true
                }
            }

            Column {
                width: parent.width
                spacing: Theme.u(10)
                visible: Recorder.busy || Recorder.output !== ""

                Label { name: "Result" }
                Text {
                    visible: Recorder.busy
                    text: Recorder.doing
                    color: Theme.muted
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(14)
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WrapAnywhere
                    text: Recorder.output
                    color: Recorder.outputIsError ? Theme.error : Theme.text
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.u(12)
                }
            }

            Column {
                width: parent.width
                spacing: Theme.u(10)

                Label { name: "What kokuin can read here" }
                Repeater {
                    model: Recorder.sources

                    ListRow {
                        required property var modelData

                        width: col.width
                        label: modelData.title
                        detail: modelData.report.status
                        sub: modelData.report.reason ?? ""
                        onClicked: Nav.explain(modelData.report.explain_id)
                    }
                }
            }
        }
    }
}
