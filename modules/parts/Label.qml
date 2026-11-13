import QtQuick
import TheLine.Ui

// A group's name: small, uppercase, spaced (like the settings app's).
Text {
    property string name

    text: name.toUpperCase()
    font.family: Theme.fontUi
    font.pixelSize: Theme.u(11)
    font.weight: Font.DemiBold
    font.letterSpacing: Theme.u(2)
    color: Theme.muted

}
