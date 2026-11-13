pragma Singleton

import QtQuick
import Quickshell

// The recorded boots (`kokuin-cli list --json`), newest first.
Singleton {
    id: root

    property var list: []         // [{ boot_id, current, started_at, dir, method, end_reason, session_ready_ns }]
    property bool loading: false
    property string error: ""
    property bool loaded: false

    function refresh(asRoot) {
        loading = true;
        error = "";
        Cli.json(["list", "--json"], (ok, data, msg) => {
            loading = false;
            loaded = true;
            if (ok)
                list = data.slice().reverse();
            else
                error = msg;
        }, asRoot);
    }
}
