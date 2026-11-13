pragma Singleton

import QtQuick

// Which page is open, and what to open it on.
QtObject {
    readonly property var pages: [
        { id: "overview", name: "Overview", needsBoot: true },
        { id: "timeline", name: "Timeline", needsBoot: true },
        { id: "boots", name: "Boots", needsBoot: false },
        { id: "compare", name: "Compare", needsBoot: false },
        { id: "explain", name: "Explain", needsBoot: false },
        { id: "recorder", name: "Recorder", needsBoot: false }
    ]

    property int index: 0
    readonly property string current: pages[index].id

    // an explanation to open on (set by whatever links to one)
    property string explainId: ""
    // an event to open the timeline on
    property int eventId: -1

    function go(id) {
        const i = pages.findIndex(p => p.id === id);
        if (i >= 0)
            index = i;
    }

    function explain(id) {
        if (!id)
            return;
        explainId = id;
        go("explain");
    }

    function event(id) {
        eventId = id;
        go("timeline");
    }

    function step(by) {
        index = (index + by + pages.length) % pages.length;
    }
}
