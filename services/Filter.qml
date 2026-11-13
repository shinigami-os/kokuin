pragma Singleton

import QtQuick

// What the timeline is narrowed to (the CLI's `timeline --stage --source --kind --grep`).
QtObject {
    property var stages: []
    property var sources: []
    property var kinds: []
    property string grep: ""
    property bool hideRaw: false     // the kernel lines nothing explains

    readonly property bool any: stages.length > 0 || sources.length > 0 || kinds.length > 0 || grep !== "" || hideRaw

    function toggle(list, value) {
        const i = list.indexOf(value);
        const out = list.slice();
        if (i >= 0)
            out.splice(i, 1);
        else
            out.push(value);
        return out;
    }

    function clear() {
        stages = [];
        sources = [];
        kinds = [];
        grep = "";
        hideRaw = false;
    }

    function only(stage) {
        clear();
        stages = [stage];
    }

    // does this event pass? (an unreadable expression filters nothing)
    function passes(e, re) {
        if (stages.length && stages.indexOf(e.stage) < 0)
            return false;
        if (sources.length && sources.indexOf(e.source) < 0)
            return false;
        if (kinds.length && kinds.indexOf(e.kind) < 0)
            return false;
        if (hideRaw && e.kind === "log" && !e.explain_id)
            return false;
        if (re && !re.test(e.title + "\n" + (e.message ?? "")))
            return false;
        return true;
    }
}
