# MPTDC Synthesis

Author: Karim Sabra

This directory contains the Cadence Genus inputs and backend for the active
`mptdc_axis_core` product boundary. The current repository baseline is closed in
a typical reference view at its exact Genus-run commit and is intended for
Innovus feasibility, not final signoff. RTL changes require a new canonical
Genus run before the checkout is a valid PnR handoff.

## Run the handoff flow

From the repository root:

```bash
bash MPTDC/syn/scripts/check_genus_axis_core_typical_closed_profile.sh
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh [run_id]
```

Only the optional run ID is accepted. Do not pass repair cells, path counts,
max-delay values, or experiment modes through the shell. The validated values
are documented and stored in:

```text
scripts/profiles/genus_axis_core_typical_closed.sh
```

Machine paths and work roots remain configurable because they are deployment
settings rather than timing policy.

## Active layout

```text
syn/
├── README.md
├── filelist_axis_core_typical_closed.f   canonical product synthesis filelist
├── inputs/
│   ├── README.md                         active constraint map and edit rules
│   └── mptdc_axis_core_typical_closed.sdc canonical constraint entrypoint
├── macros/                                RO_tune4 Liberty/physical abstracts
├── libraries/                             XFAB library resolution
└── scripts/
    ├── README.md                          public/internal ownership map
    ├── run_genus_axis_core_typical_closed.sh public handoff entrypoint
    ├── check_genus_axis_core_typical_closed_profile.sh static profile check
    ├── profiles/
    │   └── genus_axis_core_typical_closed.sh validated timing policy
    ├── genus.tcl                          Genus orchestration
    ├── procedures.tcl                     reports, checks, mapped repairs
    └── server_run_genus_o13_phase_distribution.sh internal historical backend
```

Older O13/ABS/REPAIR scripts and SDCs remain for report correlation and as
backend implementation details. Existing stable wrapper names are compatibility
aliases to the canonical command; they are not separate policies.

## Closed baseline

- Commit: `fa66cc4d36936e2bf0d41e6b24f2f9486569e242`
- Run: `20260618_111124_axis_core_genus_timing_close_on22x1_final_guarded`
- WNS/TNS: `+0.3 ps / -0.0 ps`
- Setup violations: `0`
- Transition/capacitance/fanout violations: `0 / 0 / 0`
- Effective local repair: 355 resolved `ON22JIHDX0` instances resized to X1
- X2 policy: prohibited after a `LOCAL_FAST_TAG_SELF` regression

The later `20260618_axis_core_typical_closed_handoff_rerun2` server run also
closed typical Genus and passed the pre-PnR handoff gate for its exact HEAD. It
does not cover subsequent RO-code RTL changes.

See
[`../docs/synthesis/GENUS_AXIS_CORE_TYPICAL_CLOSED_PROFILE.md`](../docs/synthesis/GENUS_AXIS_CORE_TYPICAL_CLOSED_PROFILE.md)
for the reasoning and direct impact of every policy value.

## Input and output policy

The canonical filelist excludes `mptdc_osc_model.sv`, binds the real
`RO_tune4` macro interface, selects `R750_delta5`, and preserves the validated
`BUJIHDX4 -> BUJIHDX12` phase distribution. The canonical SDC delegates to the
count-checked PD Vernier constraint stack.

Generated output belongs in `work/genus/<run_id>/`. Do not commit Genus databases,
logs, netlists, reports, or checkpoints as source. Preserve a concise summary
only when needed for review, including commit, run ID, metrics, path family, and
signoff boundary.

## Readiness rule

A result may be labeled `GENUS_TYPICAL_CLOSED` only when the tool exits cleanly,
SDC/object checks pass, the PD exception and local repair counts pass, WNS is
non-negative, setup TNS and violating paths are zero within report tolerance,
and all tracked DRV counts are zero. This label authorizes physical feasibility;
it does not authorize final signoff.
