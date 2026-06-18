# Genus Closure Profiles

Author: Karim Sabra

This directory contains versioned synthesis policy. A profile defines what the
flow is allowed to optimize; the server runner implements how Genus is invoked.

## Canonical profile

`genus_axis_core_typical_closed.sh` is the handoff baseline validated by the
June 18, 2026 run at commit `fa66cc4d36936e2bf0d41e6b24f2f9486569e242`.
It fixes the effective policy inside the repository and rejects inherited
experiment timing variables.

Use only:

```bash
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh [run_id]
```

The optional argument names the run directory. Timing constraints, repair
selection, target cells, discovery limits, and guards are not command-line or
environment inputs for this flow.

## Changing policy

Do not edit the backend runner to start an experiment. Copy the canonical
profile, give the copy a name describing the hypothesis, change only the
relevant policy values, and document the expected path family and rollback
criterion. A profile becomes canonical only after its reports show:

- clean SDC and timing-intent diagnostics;
- exact PD Vernier exception counts;
- zero setup violations in the intended view;
- zero transition, capacitance, and fanout violations;
- no new path-family regression;
- a recorded commit, run directory, and comparison against the prior baseline.

Historical `O13`, `ABS*`, and `REPAIR*` names remain in the backend for report
traceability. They are implementation labels, not handoff interfaces.

Name new profile fields by stable intent, not by experiment number. A reviewer
should be able to infer the affected path family and guard directly from the
variable name.
