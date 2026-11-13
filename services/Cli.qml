pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The only place that talks to kokuin-cli. Every function of the app is one of its commands; `--json` where the CLI
// has it, its text where it does not (enable, disable, deep, probe, capture). Nothing here parses boots: that is the
// CLI's job, the app only shows what it says. What needs root runs through pkexec (The Line's polkit dialog, or the
// desktop's own agent, asks for the password).
Singleton {
    id: root

    property string bin: ""            // the CLI's absolute path, "" when it was not found
    property string version: ""
    property bool probed: false
    readonly property bool found: bin !== ""
    property var waiting: []           // calls made before the CLI was looked for
    property int running: 0            // jobs in flight, for a busy line

    // KOKUIN_CLI, else the PATH, else where `cargo install` puts it
    Process {
        id: finder
        command: ["sh", "-c", "for p in \"$KOKUIN_CLI\" \"$(command -v kokuin-cli)\" \"$HOME/.cargo/bin/kokuin-cli\" /usr/local/bin/kokuin-cli; do [ -n \"$p\" ] && [ -x \"$p\" ] && { echo \"$p\"; exit 0; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.bin = text.trim();
                root.probed = true;
                const queued = root.waiting;
                root.waiting = [];
                queued.forEach(f => f());
                if (root.bin !== "")
                    root.run(["--version"], (code, out) => root.version = out.trim().replace(/^kokuin-cli\s*/, ""));
            }
        }
    }
    Component.onCompleted: finder.running = true

    Component {
        id: jobComp

        Process {
            id: job

            property var done
            property string out: ""
            property string err: ""
            property int status: -1
            property int pending: 3        // stdout, stderr and the exit

            function part() {
                if (--pending > 0)
                    return;
                root.running--;
                done(status, out, err);
                job.destroy();
            }

            stdout: StdioCollector {
                onStreamFinished: {
                    job.out = text;
                    job.part();
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    job.err = text;
                    job.part();
                }
            }
            onExited: code => {
                job.status = code;
                job.part();
            }
        }
    }

    // done(exitCode, stdout, stderr)
    function run(args, done, asRoot) {
        if (!probed && args[0] !== "--version") {
            waiting.push(() => run(args, done, asRoot));
            return;
        }
        if (!found && args[0] !== "--version") {
            done(127, "", "kokuin-cli was not found: install it, or set KOKUIN_CLI to its path");
            return;
        }
        running++;
        const p = jobComp.createObject(root, { command: asRoot ? ["pkexec", bin].concat(args) : [bin].concat(args), done: done });
        p.running = true;
    }

    // A small root script around the CLI (a capture that hands its files to the user): $1 is the CLI, then `args`.
    function root_sh(script, args, done) {
        running++;
        const p = jobComp.createObject(root, { command: ["pkexec", "sh", "-c", script, "sh", bin].concat(args), done: (code, out, err) => done(code === 0, out.trim(), code === 0 ? "" : reason(code, err || out)) });
        p.running = true;
    }

    // done(ok, data, message): the JSON the command printed, or why there is none
    function json(args, done, asRoot) {
        run(args, (code, out, err) => {
            if (code !== 0) {
                done(false, null, reason(code, err));
                return;
            }
            try {
                done(true, JSON.parse(out), "");
            } catch (e) {
                done(false, null, "kokuin-cli printed something that is not JSON");
            }
        }, asRoot);
    }

    // done(ok, text, message): a command that prints text
    function text(args, done, asRoot) {
        run(args, (code, out, err) => done(code === 0, out.trim(), code === 0 ? "" : reason(code, err || out)), asRoot);
    }

    function reason(code, err) {
        if (code === 126 || code === 127 && err === "")
            return "Not done: the password was cancelled or refused";
        const line = err.trim().split("\n").filter(l => l !== "").pop();
        return line ? line.replace(/^error:\s*/i, "") : "kokuin-cli stopped (exit " + code + ")";
    }
}
