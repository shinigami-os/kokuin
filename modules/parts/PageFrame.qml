import QtQuick
import TheLine.Ui
import qs.services

// A page inside its panel: the title with the page's number after it, a line saying what it is, then the body. The
// parts arrive one after another, each fading in with a 4 px slide.
FocusScope {
    id: page

    property string title
    property string sub
    property string hint: ""
    default property alias body: bodyHost.data

    property real el: 0
    NumberAnimation on el {
        from: 0
        to: Anim.itemStart + Anim.stagger * 2 + Anim.base
        duration: Anim.d(Anim.itemStart + Anim.stagger * 2 + Anim.base)
    }
    function prog(delay) {
        return Anim.out((el - delay) / Anim.base);
    }

    Row {
        id: head
        y: (1 - opacity) * Theme.u(4)
        spacing: Theme.u(14)
        opacity: page.prog(0)

        Text {
            id: titleText
            text: page.title
            color: Theme.text
            font.family: Theme.fontUi
            font.pixelSize: Theme.u(30)
        }
        Text {
            anchors.baseline: titleText.baseline
            text: String(Nav.index + 1).padStart(2, "0")
            color: Theme.accentSoft
            font.family: Theme.fontMono
            font.pixelSize: Theme.u(13)
        }
    }

    Text {
        id: subText
        y: head.height + Theme.u(8) + (1 - opacity) * Theme.u(4)
        width: page.width
        text: page.sub
        visible: text !== ""
        wrapMode: Text.WordWrap
        color: Theme.read
        font.family: Theme.fontUi
        font.pixelSize: Theme.u(15)
        opacity: page.prog(Anim.itemStart)
    }

    Item {
        id: bodyHost
        y: (subText.visible ? subText.y + subText.height : head.height) + Theme.u(22) + (1 - opacity) * Theme.u(4)
        width: page.width
        height: page.height - y
        opacity: page.prog(Anim.itemStart + Anim.stagger * 2)
    }
}
