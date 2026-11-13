pragma Singleton

import QtQuick
import Quickshell

// What kokuin can read here and whether it records boots (`kokuin-cli status --json`), and the commands that change
// that: enable and disable, deep, the EFI probe. Each can be shown first (`--dry-run`), then done as root.
Singleton {
    id: root

    property var status: null
    property bool loading: false
    property string error: ""
    property bool asRoot: false

    // the log of what the last command said
    property string output: ""
    property bool outputIsError: false
    property bool busy: false
    property string doing: ""

    readonly property var recorder: status?.recorder ?? null
    readonly property var sources: status?.sources ?? []

    function refresh(asRootToo) {
        loading = true;
        error = "";
        asRoot = asRootToo === true;
        Cli.json(["status", "--json"], (ok, data, msg) => {
            loading = false;
            if (ok)
                status = data;
            else
                error = msg;
        }, asRoot);
    }

    // args like ["enable"], ["deep", "--cancel"], ["probe", "arm"]; dry: only say what would change
    function change(args, label, dry) {
        if (busy)
            return;
        busy = true;
        doing = (dry ? "Looking at what " : "") + label + (dry ? " would change…" : "…");
        output = "";
        Cli.text(args.concat(dry ? ["--dry-run"] : []), (ok, text, msg) => {
            busy = false;
            outputIsError = !ok;
            output = ok ? text : msg;
            if (!dry && ok)
                refresh(asRoot);
        }, true);
    }
}
