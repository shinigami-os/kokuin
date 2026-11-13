import QtQuick
import TheLine.Ui
import qs.services

// One fact: its name in mono at the left, its value, and — when there is an explanation of it — a click to read it.
Rectangle {
    id: row

    property string label
    property string value
    property string explainId: ""
    property color valueColor: Theme.text

    readonly property bool linked: explainId !== "" && Kb.has(explainId)

    width: parent ? parent.width : 0
    height: Theme.u(34)
    color: hover.hovered && linked ? Theme.row : "transparent"

    Behavior on color {
        ColorAnimation { duration: Anim.hover }
    }
    Rectangle {
        width: 2
        height: parent.height
        color: Theme.accent
        opacity: hover.hovered && row.linked ? 1 : 0
    }
    Text {
        x: Theme.u(16)
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.u(150)
        text: row.label
        color: Theme.muted
        font.family: Theme.fontMono
        font.pixelSize: Theme.u(12)
    }
    Text {
        x: Theme.u(176)
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - Theme.u(70)
        text: row.value
        elide: Text.ElideRight
        color: row.valueColor
        font.family: Theme.fontUi
        font.pixelSize: Theme.u(15)
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: Theme.u(16)
        anchors.verticalCenter: parent.verticalCenter
        visible: row.linked
        text: "explain"
        color: hover.hovered ? Theme.accentSoft : Theme.faint
        font.family: Theme.fontMono
        font.pixelSize: Theme.u(11)
    }
    HoverHandler {
        id: hover
        cursorShape: row.linked ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        onTapped: if (row.linked)
            Nav.explain(row.explainId)
    }
}
