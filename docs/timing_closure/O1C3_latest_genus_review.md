# O1C3 Latest Genus Review

## Run Identity

- Current local branch after pull: `SPADMIC_TOP`
- Current local HEAD after pull: `226549ca4064d8dcb1f5e06fc3223c2454e1d0b7`
- Latest committed Genus result directory: `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/`
- Latest lab snapshot directory copied into the result: `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/synthesis_reports/`
- Server-run HEAD recorded by `SUMMARY.md`: `0e9175e8776d45c9c8f056a608c6bb872c262140`
- Run classification: O1C2 fast-count audit, not O1C3.  This O1C3 file reviews it and prepares the next action.
- Genus exit code: `0`
- Snapshot exit code: `0`

## Binding And Constraint Health

- `RO_tune4` binding remains valid enough for review:
  - `RO_tune4` instance count: `2`
  - `mptdc_osc_stub` residue count: `0`
  - `rstb` reset-like connection count: `0`
  - `report_clocks` RO_tune4/S match count: `16`
  - O1C binding status: `O1C_ARCH_VALID_BINDING_CANDIDATE`
- Real macro instances from `macro_binding_check.rpt`:
  - fast: `RO_tune4 u_core_u_osc_fast_u_ro_tune4(.code (8'b0), .rstb (u_core_fe_osc_fast_en), .S (u_core_fast_phase))`
  - slow: `RO_tune4 u_core_u_osc_slow_u_ro_tune4(.code (8'b0), .rstb (u_core_fe_start_latched), ...)`
- The previous Tcl quoting issue is fixed:
  - `Tcl invalid-command count: 0`
  - No repeat of `invalid command name "0:7"`.
- SDC/reporting is still not fully clean:
  - O1C SDC warning count: `1`
  - O1C SDC status: `REVIEW_REQUIRED`
  - Base SDC still emits unsupported-command failures around async clear false paths, STOP metadata max-delay, reset max-transition, and net-level phase bounds.
  - Focused fast-count files exist under `synthesis_reports/post_synthesis/`, but the top-level result summary marked `timing_fast_count_to_nfast_hit.rpt` and `fast_count_capture_endpoint_audit.rpt` missing.  The wrapper has been updated to copy them next time.
- The endpoint audit counted one endpoint because the Tcl helper did not iterate Cadence collections correctly.  The detailed timing parser still recovered 252 actual fast-counter to `nfast_hit` paths.

Primary report line references used:

- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/SUMMARY.md:3-22`
- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/PARSED_SUMMARY.md:7-16`
- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/fast_count_capture_summary.md:3-24`
- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/timing_osc_fast_full_clock.rpt:11-30`
- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/check_timing_intent.rpt`
- `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/report_high_fanout.rpt`

## Timing By Class

| Path class | WNS (ps) | TNS / count evidence | Main startpoints | Main endpoints | Likely root cause | Next action |
|---|---:|---|---|---|---|---|
| `OSC_FAST_REAL` | -3051 | 287 parsed paths; fast timing groups dominate total TNS at about `-1458k ps` | `u_core_u_fast_cnt_bin_q_reg[*]`, `u_core_gen_pd_*hit_latched_reg`, slow-counter sync flops | `nfast_hit_latched_reg[*]`, fast counter bits, slow counter decode in fast domain | Ordinary XH018 standard-cell flop/CQ/setup and binary counter logic are not physically plausible at 0.9 ns / 50 ps tap windows | Do not run Innovus; choose architecture/macro treatment for oscillator-domain logic |
| `OSC_SLOW_REAL` | -2695 | 50 parsed paths; `clk_osc_slow` WNS -2590.6 ps, paths 22 | slow counter bits, START watchdog bits, slow snapshot sync flops | slow counter / fast-domain decode endpoints | Same standard-cell speed issue; some paths are actually fast-domain consumption of slow snapshot decode | Classify which are real versus held/async; likely needs same macro/architecture decision |
| `CLK_SYS_REAL` | -825 | `clk_sys` WNS -824.6 ps, TNS -41995.3 ps, paths 60 | mostly `u_core_u_drain_ctrl_drain_ctx_q_reg[0]`, some `row_cnt_q` | `pd_scan_q`, `event_seq_q`, `total_hits_q` | Backend still has setup violations, but it is not the dominant conceptual blocker | Resume H4b/drain work only after oscillator-domain issue is contained |
| `PD_INTENTIONAL_VERNIER` | not isolated | 70 data pins driven by clock signals are the q1 slow_phase inputs and STOP metadata pins | `slow_phase[*]` into PD q1 D | `q1_reg/D` | Expected measurement crossing; should not be normal setup closure | Needs waiver tied to physical matching and calibration |
| `HELD_BUS_CDC` | not dominant in parsed paths | No unknown held-bus class in latest classifier | PD/counter held image | `mptdc_hit_capture_bridge` | Existing held-bus contract still visible; no new evidence of dominance | Preserve capture-before-clear |
| `ASYNC_CLEAR` | report health issue | Base SDC async-clear exceptions still generate SDC errors | `meas_pd_clear`, reset/clear nets | async clear pins | Constraint syntax/modeling needs cleanup; not timing closure evidence yet | Clean SDC helper before next expensive run |
| `UNKNOWN_REVIEW_REQUIRED` | none | 0 parsed unknown paths | none | none | Current classifier covered detailed parsed paths | OK to reason about classes above |

## DRV And Fanout

- `report_design_rules.rpt`: Max_transition violation total = `248862`.
- `report_high_fanout.rpt`:
  - `clk_sys` fanout = `4843`.
  - `u_core_fast_phase[0]` fanout = `111`.
  - `u_core_fast_phase[1:7]` fanout = `80` each.
  - `u_core_meas_pd_clear` fanout = `66`.
- The phase0 load imbalance is real evidence for a matching/linearity risk.  It should not be fixed by adding a one-off digital buffer on phase0.

## Hypothesis Review

### H1_FAST_COUNT

- Status: confirmed as a real blocker, but the deeper problem is broader than the bus.
- Supporting evidence:
  - `fast_count_capture_summary.md`: 252 fast-counter to `nfast_hit` paths, worst slack `-3051 ps`.
  - Worst path: `u_core_u_fast_cnt_bin_q_reg[4]/C` to `gen_pd_col[1].u_pd/nfast_hit_latched_reg[4]/D`.
  - `timing_osc_fast_full_clock.rpt` shows internal fast counter paths also fail, e.g. `bin_q_reg[2]` to `bin_q_reg[5]` with data path `2865 ps` against a 0.9 ns period.
- Evidence against: none strong.  The only caveat is that the Liberty shell/clock modeling may be incomplete, but that does not explain ordinary standard-cell flop setup/CQ exceeding the oscillator-period budget.
- Conclusion: do not spend Innovus on this yet.  The problem is not placement-first.

### H2_PD_GATE_FALSE_HIT

- Status: confirmed functional/timing bug.
- Supporting RTL evidence:
  - `mptdc_core.sv`: `pd_enable_gated = fe_pd_enable & meas_pd_gate`; each PD cell receives `pd_enable_gated & slow_phase[ns]`.
  - `mptdc_meas_ctrl.sv` before O1C3 fix: `pd_gate_o` was high only in IDLE/MEASURE and low in SNAPSHOT.
  - `snapshot_en_o` is asserted in SNAPSHOT, but the bridge samples on a `clk_sys` edge after the state is already SNAPSHOT.  Therefore `pd_gate` was low for a full clk_sys cycle before sample.
  - `osc_keep_alive_o` remains high in MEASURE/SNAPSHOT and `fe_stop_latched` is still set, so fast edges can occur while the forced-low PD input is visible.
- Local test evidence:
  - Added `tb_pd_gate_false_hit_unit`.
  - Verilator PASS: forcing a PD slow input low after two high samples creates a `hit_level` without a real slow falling edge.
- Conclusion: fix by keeping `pd_gate_o` high through ST_M_SNAPSHOT.  This preserves the bridge sample and row-count edge before the gate drops.

### H3_CLK_SYS_BACKEND

- Status: still failing, but not the main conceptual blocker.
- Evidence:
  - `clk_sys` WNS `-824.6 ps`, TNS `-41995.3 ps`, paths `60`.
  - Worst paths are drain scan decode and remaining count tree paths.
- Conclusion: H4b/backend work remains useful later, but not before oscillator-domain classification is resolved.

### H4_PHASE0_LOAD

- Status: confirmed matching risk.
- Evidence:
  - `u_core_fast_phase[0]` fanout `111`.
  - `u_core_fast_phase[1:7]` fanout `80`.
  - phase0 drives fast counter and PD loads, siblings drive mainly PD loads.
- Conclusion: physical/analog follow-up required.  Preferred fix is analog-approved separate phase0 outputs or matched tap buffering/loading across all taps.

### H5_CONSTRAINT_OR_MODELING

- Status: partially confirmed.
- Evidence:
  - O1C macro clocks attach to `RO_tune4/S[0:7]`, so the old stub binding is not the dominant issue.
  - SDC/reporting still emits errors, including unsupported net-level max transition/cap and invalid path specs.
  - Standard-cell timing numbers are too slow for the oscillator-domain logic even before net parasitics.
- Conclusion: clean report scripts and SDC noise, but do not dismiss the fast-domain failures as only a constraint artifact.

## Decision

- Innovus: blocked.  Genus shows architecture/macro feasibility issues, not a placement-only issue.
- R800: blocked.  A 1.15 ns fast period still may not overcome ~0.6-0.7 ns setup plus ~1.0 ns standard-cell CQ and counter logic.
- H4b: paused.  clk_sys is secondary behind oscillator-domain failures.
- Next meaningful timing closure work: choose an O1D/O2 strategy for oscillator-domain logic:
  1. Harden/model PD cells and fast/slow counters as measurement macros with real Liberty/LEF and reviewed waivers for intentional measurement behavior.
  2. Redesign fast-count capture semantics to avoid live binary S0-to-tap capture, with explicit calibration offset and local tests.
  3. Only then rerun Genus; Innovus follows only if Genus shows remaining problems are physical.
