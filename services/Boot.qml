pragma Singleton

import QtQuick
import Quickshell

// The boot being looked at: one boot record, read by `kokuin-cli show … --json`. What the pages show is worked out
// here from that record (the chain, the slowest steps, how long it all took), the way the CLI's own summary does.
Singleton {
    id: root

    property string ref: ""           // the CLI's BOOT: "" the current boot, "last", "-2", an id, a file or a folder
    property string name: "This boot"
    property var record: null
    property bool loading: false
    property string error: ""
    property bool asRoot: false       // this record was read as root (more of it is there)

    readonly property bool has: record !== null
    readonly property var info: record?.boot ?? ({ os: {}, kernel: {}, machine: {} })
    readonly property var stages: record ? record.stages.slice().sort((a, b) => (a.start_ns ?? a.end_ns ?? -1e15) - (b.start_ns ?? b.end_ns ?? -1e15)) : []
    readonly property var milestones: record?.milestones ?? []
    readonly property var events: record?.events ?? []
    readonly property var processes: record?.processes ?? []
    readonly property var sources: record?.sources ?? []

    // the whole boot on one axis: from its first moment to its last
    readonly property real startNs: {
        let t = 0;
        for (const s of stages)
            t = Math.min(t, s.start_ns ?? s.end_ns ?? 0);
        for (const m of milestones)
            t = Math.min(t, m.t_ns);
        return t;
    }
    readonly property real endNs: {
        let t = 1e9;
        for (const s of stages)
            t = Math.max(t, s.end_ns ?? s.start_ns ?? 0);
        for (const m of milestones)
            t = Math.max(t, m.t_ns);
        for (const e of events)
            if (e.t_ns !== undefined)
                t = Math.max(t, e.t_ns + (e.dur_ns ?? 0));
        return t;
    }

    // when it was ready to use (the session milestone), if it was seen
    readonly property var ready: milestones.find(m => m.kind === "session_ready") ?? null
    readonly property var chain: record ? chainOf(record) : []
    readonly property var slowest: slowestOf(e => e.kind !== "initcall")
    readonly property var slowestInit: slowestOf(e => e.kind === "initcall")
    readonly property var sourcesSeen: events.reduce((acc, e) => {
        if (acc.indexOf(e.source) < 0)
            acc.push(e.source);
        return acc;
    }, []).sort()
    readonly property var kindsSeen: events.reduce((acc, e) => {
        if (acc.indexOf(e.kind) < 0)
            acc.push(e.kind);
        return acc;
    }, []).sort()

    function open(boot, label) {
        ref = boot;
        name = label ?? (boot === "" ? "This boot" : boot);
        loading = true;
        error = "";
        asRoot = false;
        Cli.json(["show"].concat(boot === "" ? [] : [boot]).concat(["--json"]), (ok, data, msg) => {
            loading = false;
            if (ref !== boot)
                return;
            if (ok)
                record = data;
            else
                error = msg;
        });
    }

    function reload() {
        open(ref, name);
    }

    // Everything of this boot, which only root can read: captured once as root, then read as a file.
    function readAsRoot() {
        const dir = Quickshell.env("XDG_RUNTIME_DIR") + "/kokuin";
        const file = dir + "/this-boot.json";
        loading = true;
        error = "";
        Cli.root_sh("mkdir -p \"$(dirname \"$2\")\" && \"$1\" capture -o \"$2\" && chown \"$3\" \"$2\"", [file, Quickshell.env("USER")], (ok, text, msg) => {
            if (!ok) {
                loading = false;
                error = msg;
                return;
            }
            open(file, "This boot, read as root");
            asRoot = true;
        });
    }

    function milestone(kind) {
        return milestones.find(m => m.kind === kind) ?? null;
    }

    function process(id) {
        return processes.find(p => p.id === id) ?? null;
    }

    function chainOf(r) {
        const b = r.boot;
        const out = [b.machine.firmware === "uefi" ? "UEFI" : b.machine.firmware === "bios" ? "BIOS" : "Firmware"];
        if (b.bootloader)
            out.push(b.bootloader.name ?? b.bootloader.id);
        out.push("Linux " + b.kernel.release);
        if (r.stages.some(s => s.stage === "initramfs"))
            out.push("initramfs");
        if (b.init)
            out.push(b.init.name ?? b.init.id);
        for (const kind of ["display_manager_start", "compositor_start"]) {
            const m = r.milestones.find(x => x.kind === kind);
            const ev = m?.event !== undefined ? r.events.find(e => e.id === m.event) : null;
            const proc = ev?.process !== undefined ? r.processes.find(p => p.id === ev.process) : null;
            if (proc)
                out.push(proc.comm);
        }
        return out;
    }

    function slowestOf(keep) {
        return events.filter(e => (e.dur_ns ?? 0) > 0 && keep(e)).sort((a, b) => b.dur_ns - a.dur_ns).slice(0, 10);
    }
}
