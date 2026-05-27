# H1 Hit-Count Analysis

Hypothesis: the 64-bit hit-count reduction is the main clk_sys setup killer.

Status: not confirmed on the fresh Genus baseline.

## RTL Review

`MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv` already contains a partially staged hit-count
implementation:

- `SNAPSHOT`: samples the held measurement image in `mptdc_hit_capture_bridge`
  and registers eight independent row counts in `row_cnt_q`.
- `COUNT`: sums registered row counts through a balanced tree, computes
  `hit_count_o` and close flags, and asserts `capture_en_o`.
- `CLEAR`: asserts `pd_clear_o` after the snapshot/context capture cycle.

Current sequence:

```text
IDLE -> MEASURE -> SNAPSHOT -> COUNT -> CLEAR -> IDLE
```

The capture-before-clear invariant is preserved in this RTL:

- `snapshot_en_o` is asserted in `SNAPSHOT`.
- `capture_en_o` and `fe_clear_o` are asserted in `COUNT`.
- `pd_clear_o` is asserted in `CLEAR`.

## Remaining H1 Risk

The current `COUNT` cycle still combines:

- final row-count summation from `row_cnt_q`
- max-hit saturation compare
- close-flag generation
- context-bank capture of raw snapshot plus metadata
- frontend clear pulse generation

That could still be a real clk_sys path. A lower-risk candidate remains:

```text
IDLE -> MEASURE -> SNAPSHOT -> COUNT_ROW -> COUNT_SUM -> COMMIT -> CLEAR -> IDLE
```

However, the fresh Genus reports do not yet prove that this cone is the dominant
clk_sys violation.

## Server Evidence

`timing_summary.rpt` reports clk_sys WNS/TNS:

- WNS: `-1486.0 ps`
- TNS: `-91719.4 ps`
- Violating paths: `79`

But the detailed committed path reports do not include clk_sys paths:

- `timing_violations.rpt` top 200 paths are oscillator/PD measurement paths.
- `timing_meas_ctrl_hotspots.rpt` failed generation.
- `timing_context_bank_hotspots.rpt` failed generation.

## Decision

Do not implement the H1 RTL pipeline yet. First fix report generation and rerun
Genus so the actual clk_sys startpoints/endpoints are visible.

Rollback trigger for future H1 patch:

- packet fields change
- raw snapshot fields change
- source clear can happen before snapshot/context protection
- context is visible before complete metadata is internally consistent
- hit_count differs from popcount/saturation semantics
- Verilator or server Xcelium sequencing regression fails
