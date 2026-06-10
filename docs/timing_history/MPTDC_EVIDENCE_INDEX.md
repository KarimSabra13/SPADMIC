# MPTDC Evidence Index

Author: Karim Sabra

This index preserves compact evidence breadcrumbs before generated run bulk is
removed from git.  Raw artifacts are historical inputs, not source files.

| Run family | Run ID / path | Git HEAD | Purpose | Key result | Status | Original artifact path | Raw artifact removed from git |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R750_delta5 Genus | `20260604_o9_final_typical_r750_delta5` | `1ee8e7101a7f263998b63cc736dfa38018e4e4ba` in reviewed note | Typical Genus with R750_delta5 | Near-clean typical result; small fast-tag-to-PD residual; no final signoff | Historical basis for active mode | `results/genus_osc_pd/20260604_o9_final_typical_r750_delta5/` | Pending cleanup commit |
| R750_delta5 characterization | `20260604_o9_r750_delta5_overnight` | `a6583c799cd604c07e5d2e7065f846551fa7abdc` in reviewed note | Xcelium characterization campaign shape | Manifest completed; detailed metrics not fully committed | Historical, rerun required after final topology | `results/o9_char/20260604_o9_r750_delta5_overnight/` | Pending cleanup commit |
| Innovus feasibility | `20260604_o10_2_pnr_repair` | See archived manifest | Routed feasibility and report repair | Routed checkpoint useful; RO load problem discovered | Historical evidence | `results/innovus/20260604_o10_2_pnr_repair/` and mirrored lab snapshot | Pending cleanup commit |
| RO-load analysis | `20260608_o11_ro_load_analysis*` | See archived notes | Source-pin load budget analysis | Direct RO loads were physical and excessive; do not waive by Liberty relaxation | Active lesson | `results/innovus/20260608_o11_ro_load_analysis*/` | Pending cleanup commit |
| Phase isolation | phase-buffer analysis family | See archived notes | Reduce direct RO loading through isolation buffers | Established the need for one local buffer input per RO output | Active lesson | `results/innovus/20260608_o12*` | Pending cleanup commit |
| Phase distribution / clock CDC / PD Vernier | `20260609_o13_abs5e_pd_q1_constraint_mode_fix` | `5836c9f85c640c134905aa31714577ecd29abd89` in reviewed note | Current phase-distribution timing model and PD Vernier exception | 16 raw clocks, 16 buffered clocks, 64 exact PD Vernier endpoints, no overmatch | Active equivalent flow | `results/github_snapshots/20260609_o13_abs5e_pd_q1_constraint_mode_fix_snapshot/` | Pending cleanup commit |

## Retained Evidence

The retained evidence is this index plus:

- `docs/timing_history/MPTDC_TIMING_CLOSURE_HISTORY.md`
- `docs/timing_history/MPTDC_RESULT_RETENTION_POLICY.md`
- Archived detailed notes under `docs/timing_history/archive/`
- Active architecture and flow docs under `MPTDC/docs/`
- Protected macro/analog/XLIBD source inputs

## Interpretation

Every row is `NOT_FINAL_SIGNOFF`.  Use these rows to understand why the active
flow is shaped as it is.  Do not use raw historical paths as required source
dependencies for fresh clone operation.
