# O13 abs4: abs3 Deep Review

Status: `ABS3_CLOCK_CDC_REPAIR_SUCCEEDED_ABS4_REPORT_REPAIR_REQUIRED`

## Evidence Reviewed

- Snapshot: `results/github_snapshots/20260609_o13_abs3_clock_cdc_repair_snapshot/`
- Summary: `SUMMARY.md`
- Clock model: `o13_clock_model_check.sdc.rpt`
- Timing: `timing_summary.rpt`, `timing_violations.rpt`, `timing_pd_capture_hotspots.rpt`
- Classifier: `timing_path_classification.csv`, `timing_path_classification_summary.md`
- SDC health: `sdc_command_failures.md`
- DRV: `report_design_rules.rpt`

## Clock Model Result

O13 abs3 fixed the abs2 integration bug.

| Check | abs3 result |
|---|---:|
| `RO_tune4` instances | 2 |
| old `mptdc_osc_stub` residue | 0 |
| raw RO clocks | 16 |
| final buffer phase clocks | 16 |
| oscillator clocks in async group | 32 |
| `clk_sys` clocks | 1 |
| buffer clocks async to `clk_sys` | YES |
| `clk_sys` async to buffer phase clocks | YES |

The impossible abs2 paths from `clk_sys` into `clk_osc_*_buf_tap*` disappeared. `clk_sys` timing in abs3 is clean or near-clean; the top reported `clk_sys` path has positive slack. This means the main abs2 failure was a clock/CDC constraint integration bug, not evidence that the O13 BUHDX4 -> BUHDX12 topology is bad.

## RTL Mapping

The O13 phase topology is implemented in `MPTDC/rtl/osc/mptdc_phase_buffer_bank.sv:21-25` and `MPTDC/rtl/osc/mptdc_phase_buffer_bank.sv:70-86`:

- `RO_tune4/S[n]` drives the first-stage `BUHDX4 u_iso`.
- `BUHDX4` output drives `BUHDX12 u_drv`.
- `BUHDX12` output drives the buffered phase fabric.

`mptdc_core` instantiates the slow and fast phase buffer banks at `MPTDC/rtl/top/mptdc_core.sv:429-440`. Downstream consumers use the buffered buses:

- fast tag columns are clocked by `fast_phase[nf]` at `MPTDC/rtl/top/mptdc_core.sv:445-465`.
- slow epoch Johnson is clocked by `slow_phase[0]` at `MPTDC/rtl/top/mptdc_core.sv:472-484`.
- the PD matrix connects `slow_phase[ns]` and `fast_phase[nf]` at `MPTDC/rtl/top/mptdc_core.sv:486-505`.

## The 64 UNKNOWN Paths

abs3 reported:

- `UNKNOWN_REVIEW_REQUIRED = 64`
- all top unknown paths launch from `u_core_u_phase_buf_slow/gen_phase_buf[*].u_drv/Q`
- all endpoints are `u_core_gen_pd_row[*].gen_pd_col[*].u_pd/q1_reg/D`
- all destination clocks are `clk_osc_fast_buf_tap*`

These are the 8 x 8 slow-to-fast PD sampler relations:

```text
buffered slow_phase[ns]
  -> mptdc_pd_cell.q1_reg/D
  sampled by buffered fast_phase[nf]
```

The RTL contract is explicit in `MPTDC/rtl/pd/mptdc_pd_cell.sv:10-14` and `MPTDC/rtl/pd/mptdc_pd_cell.sv:86-99`: `q1 <= slow_phase` on `posedge fast_phase`, then `q2 <= q1`, and `hit_latched` detects the slow falling-edge relation.

Conclusion: the 64 UNKNOWN paths are expected intentional Vernier measurement crossings. They should classify as `PD_INTENTIONAL_VERNIER`, not `UNKNOWN_REVIEW_REQUIRED`, `PHASE_BUFFER_CHAIN`, or `OSC_FAST_REAL`.

## Real Fast-Domain Timing Still Visible

After excluding the intended Vernier crossings, the real oscillator-domain timing remains visible:

- `PD_Q1_TO_Q2_LOCAL_FAST`: worst abs3 smoke reclassification is about `-320 ps`.
- `LOCAL_FAST_TAG_SELF`: worst about `-50 ps`.
- `FAST_TAG_TO_PD_TS`: worst about `-40 ps`.
- `PD_HIT_LATCH_LOCAL_FAST` / hit-freeze logic: small negative paths remain.

These are real local fast-domain paths. Abs4 must not hide them.

## Broken or Misleading Reports

- `timing_o13_phase_buffer_paths.rpt` says `No paths found`; this is a report bug because generated clocks make the buffer chain poor as a normal `report_timing` query. Abs4 replaces it with a structural topology report.
- `timing_clk_sys_violations.rpt` must distinguish no negative `clk_sys` paths from a stale filter. Abs4 adds `timing_clk_sys_internal_top100.rpt`.
- abs3 SDC failure extraction still shows failed base-SDC commands around stringified Tcl collection handles. Abs4 fixes the helper pattern and keeps `sdc_command_failures.md` as a hard review artifact.

## Decision

Do not reject O13.

Do not run Innovus yet.

Run O13 abs4 first. Abs4 pass criteria are:

- `UNKNOWN_REVIEW_REQUIRED = 0`
- `PD_INTENTIONAL_VERNIER = 64` or a documented equivalent count
- buffer clocks remain async to `clk_sys`
- structural phase-buffer report shows all 16 chains
- no unresolved safety-critical SDC command failures
- real local fast-domain paths remain visible for review
