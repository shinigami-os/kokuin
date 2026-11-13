pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Kira's accent colour: the one picked in The Line's settings (config.json), followed live. The default purple stays
// where The Line is not installed.
Singleton {
    id: root

    property color accent: "#9A5CFF"

    function read() {
        try {
            const c = JSON.parse(file.text()).accent;
            if (/^#[0-9a-fA-F]{6}$/.test(c))
                accent = c;
        } catch (e) {}
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/the-line/config.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.read()
    }
}
