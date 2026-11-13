import QtQuick
import TheLine.Ui

// A small outlined word: a stage, a kind, a source.
Rectangle {
    property string label
    property bool lit: false
    property bool selectable: false
    signal clicked

    implicitWidth: text.implicitWidth + Theme.u(14)
    implicitHeight: Theme.u(22)
    color: lit ? Theme.accentTint : "transparent"
    border.width: 1
    border.color: lit ? Theme.accent : hover.hovered && selectable ? Theme.borderStrong : Theme.border

    Behavior on border.color {
        ColorAnimation { duration: Anim.hover }
    }

    Text {
        id: text
        anchors.centerIn: parent
        text: parent.label
        color: parent.lit ? Theme.text : Theme.muted
        font.family: Theme.fontMono
        font.pixelSize: Theme.u(11)
    }
    HoverHandler {
        id: hover
        cursorShape: parent.selectable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        onTapped: if (parent.selectable)
            parent.clicked()
    }
}
