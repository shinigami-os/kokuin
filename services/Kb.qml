pragma Singleton

import QtQuick
import Quickshell

// The explanations (`kokuin-cli explain`): the list, and an article when it is wanted.
Singleton {
    id: root

    property var list: []         // [{ id, title, summary }]
    property bool loaded: false
    property var articles: ({})   // id -> { id, title, summary, related, references, body }
    property string error: ""

    function load() {
        if (loaded)
            return;
        Cli.json(["explain", "--json"], (ok, data, msg) => {
            if (ok) {
                list = data;
                loaded = true;
            } else {
                error = msg;
            }
        });
    }

    function title(id) {
        return list.find(a => a.id === id)?.title ?? id;
    }

    function has(id) {
        return list.some(a => a.id === id);
    }

    // done(article | null)
    function get(id, done) {
        if (articles[id]) {
            done(articles[id]);
            return;
        }
        Cli.json(["explain", id, "--json"], (ok, data) => {
            if (ok) {
                const all = articles;
                all[id] = data;
                articles = all;
            }
            done(ok ? data : null);
        });
    }
}
