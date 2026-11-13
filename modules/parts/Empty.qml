import QtQuick
import TheLine.Ui
import qs.services

// A page that needs a boot, when there is none: why, and what to do.
Item {
    id: empty

    Column {
        width: Math.min(parent.width, Theme.u(560))
        spacing: Theme.u(16)

        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: Boot.loading ? "Reading the boot…" : Boot.error !== "" ? Boot.error : "No boot is open."
            color: Boot.error !== "" ? Theme.error : Theme.read
            font.family: Theme.fontUi
            font.pixelSize: Theme.u(16)
        }
        Text {
            width: parent.width
            wrapMode: Text.WordWrap
            visible: !Boot.loading
            text: Cli.found ? "kokuin reads the boot with kokuin-cli. Without root it sees less (the TPM log and part of the kernel log are root's): read it again as root, or open a recorded boot or a saved record."
                : "kokuin-cli was not found. Install it, or set KOKUIN_CLI to its path."
            color: Theme.muted
            font.family: Theme.fontUi
            font.pixelSize: Theme.u(14)
        }
        Row {
            spacing: Theme.u(12)
            visible: !Boot.loading && Cli.found

            Btn {
                label: "Read this boot"
                primary: true
                onClicked: Boot.open("", "This boot")
            }
            Btn {
                label: "Read it as root"
                onClicked: Boot.readAsRoot()
            }
            Btn {
                label: "Recorded boots"
                onClicked: Nav.go("boots")
            }
        }
    }
}
