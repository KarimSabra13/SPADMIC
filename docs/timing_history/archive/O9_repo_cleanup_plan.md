# O9 Repo Cleanup Plan

Requested inventory command was run:

```bash
git ls-files results MPTDC/lab_snapshots docs/timing_closure | sort > docs/timing_closure/O9_tracked_generated_files_before_cleanup.txt
```

The inventory currently contains 7,077 tracked paths. A dry-run clean was also
checked with `git clean -nd`. It would remove active untracked O9 files and
local `.agents/.codex` metadata, so no deletion was performed in this source
change.

## Keep

- O7/O8 summary references until O9 is complete.
- Current O8/O9 server scripts and SDC overlays.
- Timing analysis tools and decode tables.
- Analog handoff files, including screenshot-derived RO references.
- Final O9 characterization and synthesis summaries once produced.

## Remove Or Stop Tracking Later

- Superseded giant raw logs with no summary value.
- Failed experimental snapshots that are not referenced by iteration docs.
- Temporary scratch scripts and campaign byproducts.
- Waveforms and simulator transient files.

## Deferred

Actual deletion is deferred to a separate cleanup commit after O9 characterization
and final synthesis results are present. Do not use `git clean -fdx` blindly.
