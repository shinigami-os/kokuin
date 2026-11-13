pragma Singleton

import QtQuick

// Times, durations and the CLI's snake_case names, written for people.
QtObject {
    // nanoseconds on the boot clock: 0 is the start of the kernel, before it is negative
    function time(ns) {
        if (ns === undefined || ns === null)
            return "—";
        return (ns < 0 ? "−" : "") + length(Math.abs(ns));
    }

    function length(ns) {
        if (ns === undefined || ns === null)
            return "—";
        if (ns >= 1e9)
            return (ns / 1e9).toFixed(ns >= 1e10 ? 1 : 2) + " s";
        if (ns >= 1e6)
            return (ns / 1e6).toFixed(ns >= 1e7 ? 0 : 1) + " ms";
        return Math.round(ns / 1e3) + " µs";
    }

    // a change between two boots: "+120 ms", "−1.2 s"
    function delta(ns) {
        if (ns === undefined || ns === null)
            return "—";
        if (ns === 0)
            return "same";
        return (ns > 0 ? "+" : "−") + length(Math.abs(ns));
    }

    function words(name) {
        if (!name)
            return "";
        const s = String(name).replace(/_/g, " ");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    // "2026-11-12T08:44:58.120+01:00" -> "12 Nov 2026, 08:44"
    function when(iso) {
        if (!iso)
            return "—";
        const d = new Date(iso);
        return isNaN(d) ? String(iso) : Qt.formatDateTime(d, "d MMM yyyy, HH:mm");
    }

    function shortId(id) {
        return id ? String(id).slice(0, 8) : "";
    }

    function bytes(n) {
        if (n === undefined || n === null)
            return "—";
        if (n >= 1073741824)
            return (n / 1073741824).toFixed(1) + " GiB";
        if (n >= 1048576)
            return Math.round(n / 1048576) + " MiB";
        return Math.round(n / 1024) + " KiB";
    }
}
