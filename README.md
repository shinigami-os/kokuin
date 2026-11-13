# kokuin

A window on how a Linux machine boots, from the power button to a usable desktop. It is the graphical face of
[kokuin-cli](https://github.com/shinigami-os/kokuin-cli): everything it shows comes from that CLI, and every function
of the CLI is here, for those who prefer not to use a terminal.

| Page | What it does | CLI |
|---|---|---|
| Overview | the chain firmware → bootloader → kernel → init → desktop, the stages on one time axis | `show` |
| Timeline | every event, filtered by stage, source, kind or text | `timeline` |
| Boots | the current boot, recorded boots, a saved record or raw folder; save this boot | `show`, `list`, `capture` |
| Compare | what changed between two boots | `diff` |
| Explain | what each step is, in plain words | `explain` |
| Recorder | record every boot, deep boot, the EFI probe, with a preview of each change | `status`, `enable`, `disable`, `deep`, `probe` |

What needs root runs through `pkexec`; each change can be previewed first (`--dry-run`).

## Run

Needs [Quickshell](https://quickshell.org) and The Line's UI kit (`TheLine.Ui`, from
[the-line-ui](https://github.com/Kira-Linux/the-line-ui)) and `kokuin-cli` in the PATH.

    KOKUIN_CLI=/path/to/kokuin-cli qs -p .

Alt+1…6 or Alt+←→ change page, F5 reads the boot again, Ctrl+Q leaves. `KOKUIN_REDUCE_MOTION=1` turns the motion off.

## License

GPL-2.0-only, like kokuin-cli.
