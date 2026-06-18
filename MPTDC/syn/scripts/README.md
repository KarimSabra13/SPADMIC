# MPTDC Genus Script Map

Author: Karim Sabra

The public synthesis interface is intentionally small. Historical experiment
labels remain in the backend only where they are needed to reproduce reports.

## Public handoff scripts

| Script | Role |
| --- | --- |
| `run_genus_axis_core_typical_closed.sh` | Canonical Genus execution entrypoint; accepts only an optional run ID. |
| `check_genus_axis_core_typical_closed_profile.sh` | Static syntax, value, target-selection, and override-rejection check. |
| `profiles/genus_axis_core_typical_closed.sh` | Repository-owned timing policy and backend compatibility adapter. |

The filenames `server_run_genus_mptdc_typical.sh`,
`server_run_genus_mptdc_timing_closure.sh`,
`server_run_genus_mptdc_final_typical.sh`, and
`server_run_genus_mptdc_axis_core_timing_close.sh` are compatibility aliases to
the canonical entrypoint.

## Internal backend

- `genus.tcl` orchestrates Genus.
- `procedures.tcl` owns reporting, fail-closed object checks, timing-path parsing,
  and mapped repair application.
- `server_run_genus_o13_phase_distribution.sh` resolves PDK/macro inputs, invokes
  Genus, classifies results, and emits readiness summaries.

The O13/ABS/REPAIR names in these files are historical trace labels. Do not use
them as new public flow names or add more shell-level repair knobs to the
canonical wrapper.

## Experiment rule

Create a separate profile and purpose-based wrapper for a new hypothesis. Keep
the canonical profile unchanged until the experiment has a clean, commit-tied
server result and a documented comparison. Machine path overrides may remain in
the environment; timing policy must remain in the profile.

## Naming rule

New scripts should be named for the design boundary, timing view, and purpose,
for example `run_genus_axis_core_typical_closed.sh`. New profile variables
should name the design intent first and the backend adapter second, as in
`MPTDC_GENUS_BASELINE_PD_LOCAL_ALLOW_X2`. Do not expose backend experiment
knobs as public environment variables unless the wrapper also validates and
documents their allowed values.
