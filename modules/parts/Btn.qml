import QtQuick
import TheLine.Ui

// A button: 1 px border, its label, an optional key cap. `primary` is the one that does the thing (the accent); `danger`
// is for what removes or changes the system (coral).
Rectangle {
    id: btn

    property string label
    property string key
    property bool primary: false
    property bool danger: false
    property bool enabled: true
    signal clicked

    readonly property color tone: danger ? Theme.error : primary ? Theme.accent : Theme.text

    implicitWidth: row.implicitWidth + Theme.u(32)
    implicitHeight: Theme.u(40)
    color: primary && hover.hovered && enabled ? Theme.accentTint : "transparent"
    border.width: 1
    border.color: !enabled ? Theme.border : hover.hovered ? btn.tone : (primary || danger ? btn.tone : Theme.borderStrong)
    opacity: enabled ? 1 : 0.45

    Behavior on color {
        ColorAnimation { duration: Anim.hover }
    }
    Behavior on border.color {
        ColorAnimation { duration: Anim.hover }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.u(10)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: btn.label
            color: btn.tone
            font.family: Theme.fontUi
            font.pixelSize: Theme.u(14)
            font.weight: btn.primary ? Font.DemiBold : Font.Medium
        }
        KeyCap {
            visible: btn.key !== ""
            anchors.verticalCenter: parent.verticalCenter
            label: btn.key
        }
    }

    HoverHandler {
        id: hover
        cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        onTapped: if (btn.enabled)
            btn.clicked()
    }
}
