import QtQuick
import TheLine.Ui
import qs.modules.parts
import qs.services

// What each step of the boot is (`kokuin-cli explain`): the list on the left, the article on the right. Every other
// page links here by an explanation id.
PageFrame {
    id: page

    title: "Explain"
    sub: "What the firmware, the bootloader, the kernel and the init do, in plain words."
    hint: "type to search   ↑↓ move   enter read"

    property var article: null
    property string openId: ""
    property int sel: 0

    readonly property var shown: {
        const q = search.text.trim().toLowerCase();
        return q === "" ? Kb.list : Kb.list.filter(a => (a.id + " " + a.title + " " + a.summary).toLowerCase().includes(q));
    }

    function read(id) {
        openId = id;
        Kb.get(id, a => {
            if (openId === id)
                article = a;
        });
    }

    Component.onCompleted: {
        Kb.load();
        if (Nav.explainId !== "") {
            read(Nav.explainId);
            Nav.explainId = "";
        }
    }
    Connections {
        target: Nav
        function onExplainIdChanged() {
            if (Nav.explainId !== "" && Nav.current === "explain") {
                page.read(Nav.explainId);
                Nav.explainId = "";
            }
        }
    }

    Row {
        anchors.fill: parent
        spacing: Theme.u(32)

        Column {
            width: Theme.u(420)
            height: parent.height
            spacing: Theme.u(12)

            Field {
                id: search
                width: parent.width
                height: Theme.u(44)
                placeholder: "search the " + Kb.list.length + " explanations"
                onTextChanged: page.sel = 0
                Keys.onDownPressed: page.sel = Math.min(page.shown.length - 1, page.sel + 1)
                Keys.onUpPressed: page.sel = Math.max(0, page.sel - 1)
                onAccepted: if (page.shown[page.sel])
                    page.read(page.shown[page.sel].id)
            }
            Text {
                visible: Kb.error !== ""
                width: parent.width
                wrapMode: Text.WordWrap
                text: Kb.error
                color: Theme.error
                font.family: Theme.fontUi
                font.pixelSize: Theme.u(14)
            }
            ListView {
                width: parent.width
                height: parent.height - Theme.u(56)
                clip: true
                model: page.shown
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: page.sel
                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: ListRow {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    label: modelData.title
                    detail: modelData.id
                    selected: modelData.id === page.openId || index === page.sel
                    onClicked: {
                        page.sel = index;
                        page.read(modelData.id);
                    }
                }
            }
        }

        Flickable {
            id: flick
            width: parent.width - Theme.u(452)
            height: parent.height
            contentHeight: art.implicitHeight + Theme.u(20)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Text {
                visible: page.article === null
                text: "Pick an explanation on the left."
                color: Theme.muted
                font.family: Theme.fontUi
                font.pixelSize: Theme.u(15)
            }

            Column {
                id: art
                visible: page.article !== null
                width: flick.width - Theme.u(12)
                spacing: Theme.u(16)

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: page.article?.title ?? ""
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(26)
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: page.article?.summary ?? ""
                    color: Theme.muted
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(15)
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    textFormat: Text.MarkdownText
                    text: page.article?.body ?? ""
                    color: Theme.text
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.u(14)
                    lineHeight: 1.3
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
                Column {
                    width: parent.width
                    spacing: Theme.u(8)
                    visible: (page.article?.related?.length ?? 0) > 0

                    Label { name: "Related" }
                    Flow {
                        width: parent.width
                        spacing: Theme.u(6)

                        Repeater {
                            model: page.article?.related ?? []

                            Tag {
                                required property string modelData

                                label: Kb.has(modelData) ? Kb.title(modelData) : modelData
                                selectable: Kb.has(modelData)
                                onClicked: page.read(modelData)
                            }
                        }
                    }
                }
                Column {
                    width: parent.width
                    spacing: Theme.u(6)
                    visible: (page.article?.references?.length ?? 0) > 0

                    Label { name: "Read more" }
                    Repeater {
                        model: page.article?.references ?? []

                        Text {
                            required property var modelData

                            width: art.width
                            wrapMode: Text.WordWrap
                            text: "<a href=\"" + modelData.url + "\">" + modelData.title + "</a>"
                            textFormat: Text.StyledText
                            linkColor: Theme.accent
                            color: Theme.accent
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.u(13)
                            onLinkActivated: link => Qt.openUrlExternally(link)
                        }
                    }
                }
            }
        }
    }
}
