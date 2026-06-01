# O1C3 Architecture Options

## Root Cause Ranking

### 1. Oscillator-domain standard-cell timing feasibility

Highest confidence root cause.  O1C2 shows the fast counter, PD `nfast_hit`, and some slow-snapshot decode paths failing by roughly 2.7-3.1 ns.  These paths are ordinary synthesized standard-cell registers being asked to operate at oscillator rates or sub-cycle tap windows.

This must be resolved before Innovus is useful.

### 2. PD gate teardown can fabricate hits before snapshot

Confirmed by RTL trace and local Verilator unit test.  A low-risk fix has been applied by keeping `pd_gate` open through `ST_M_SNAPSHOT`.

This is a correctness fix, not the main Genus WNS fix.

### 3. clk_sys backend still has setup violations

`clk_sys` WNS is around `-825 ps`.  The paths are mostly drain scan/control and residual hit-count logic.  This should be addressed after the oscillator-domain issue is classified, because H4b/clk_sys changes cannot remove the `OSC_FAST_REAL` blocker.

## Ranked Closure Plan

### Rank 1: choose an explicit oscillator-domain implementation model

**Patch name:** `O2_measurement_fabric_timing_model`

**Rationale:** Genus cannot close ordinary XH018 standard-cell flops at the modeled fast oscillator timing.  The design must either use hardened measurement macros or redesign fast-count capture semantics so no live binary S0-to-tap path is required.

**Files likely affected:**

- `MPTDC/rtl/pd/mptdc_pd_cell.sv` if PD internals remain RTL.
- `MPTDC/rtl/top/mptdc_core.sv` for fast-count/tag distribution.
- `MPTDC/rtl/cdc/mptdc_gray_cnt_sync.sv` if the current generic counter is not usable in the oscillator domain.
- `MPTDC/syn/inputs/mptdc_osc_pd_o1c.sdc` for path classification/constraints.
- `docs/timing_closure/cdc_async_waiver_package.md`
- `docs/timing_closure/osc_pd_exception_waivers.md`

**Expected timing impact:** removes or reclassifies the dominant `OSC_FAST_REAL` failures only if the model is real.  A broad false path without macro/semantic proof is not acceptable.

**Functional risk:** medium to high, depending on whether raw `nfast_hit` semantics change.

**Linearity/precision risk:** medium to high unless the offset and tap matching are explicitly covered by calibration.

**Required local tests:**

- PD cell unit tests.
- Fast-count/tag unit tests for every tap.
- Integration packet/readout scoreboard with latency-insensitive comparison.
- Tests proving `nfast_hit` offset is deterministic.

**Required server tests:**

- Genus O2.
- Xcelium directed/random MPTDC regression if any raw field semantics change.
- Innovus only after Genus shows the remaining failures are physical.

**Rollback condition:** any changed packet schema, non-deterministic `nfast_hit`, broken capture-before-clear, or unclassified timing paths.

### Rank 2: keep O1C3 PD-gate fix and clean report/SDC infrastructure

**Patch name:** `O1C3_pd_gate_and_report_cleanup`

**Rationale:** This is a confirmed correctness bug plus report cleanup.  It is safe to merge ahead of the next timing experiment, but it will not close the fast-domain WNS.

**Files changed in current work:**

- `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv`
- `MPTDC/tb/unit/tb_meas_ctrl_unit.sv`
- `MPTDC/tb/unit/tb_pd_gate_false_hit_unit.sv`
- `MPTDC/syn/inputs/mptdc_osc_pd_o1c.sdc`
- `MPTDC/syn/scripts/procedures.tcl`
- `MPTDC/syn/scripts/server_run_genus_o1c_macro_binding.sh`
- O1C3 documentation files

**Expected timing impact:** little to none on `OSC_FAST_REAL`.  May slightly change gate-related local PD logic but does not address counter/CQ/setup feasibility.

**Functional risk:** low.  The change keeps the PD input open until the actual sample edge.

**Linearity/precision risk:** low positive.  It avoids a digitally fabricated hit; it does not modify oscillator taps or PD sampling internals.

**Required local tests:**

- Verilator lint.
- `tb_meas_ctrl_unit`.
- `tb_pd_gate_false_hit_unit`.
- Integration smoke if time permits.

**Required server tests:**

- Xcelium server regression should include reset/STOP/snapshot stress.
- Genus rerun is optional and not recommended by itself while the fast-domain architecture is unresolved.

**Rollback condition:** if Xcelium shows missed legitimate hits due to the gate staying open through SNAPSHOT.

### Rank 3: resume clk_sys backend/H4b after oscillator-domain classification

**Patch name:** `H4b_drain_emit_clk_sys_cleanup`

**Rationale:** clk_sys WNS is still negative, but the worst Genus issue is not clk_sys.  H4b should wait until the oscillator-domain plan stops dominating the run.

**Expected timing impact:** improves `CLK_SYS_REAL` only.

**Functional risk:** low to medium depending on drain sequencing.

**Linearity/precision risk:** low if packet fields remain unchanged.

**Required tests:** existing drain/FIFO/readout Verilator and Xcelium regression if sequencing changes.

## Candidate Review

### Candidate A: stable fast-cycle tag

Best direction if we can define a tag stable before all PD tap captures.  Needs an explicit offset.  Hard part: producing that tag at oscillator speed may itself require hardened/custom logic.

### Candidate B: previous-count convention

Conceptually aligned with existing `VERNIER_NFAST_ORIGIN_BIAS = 1`.  Not enough to write a multicycle exception unless RTL/physical implementation guarantees the current count transition cannot reach PD capture flops during the tap window.

### Candidate C: Gray tag capture

Useful for coherency, not sufficient for timing.  It does not fix 50 ps S0-to-S1 timing.

### Candidate D: local replicated tag/registers

May reduce fanout but does not solve internal standard-cell counter timing or the first tap window by itself.

### Candidate E: true `detect_en` inside PD cell

Useful if we want to stop new hit detection without forcing `slow_phase` low.  O1C3 uses a lower-risk first fix instead: keep the current gate open through snapshot.  `detect_en` remains a possible cleanup but touches every PD cell.

### Candidate F: R800

Blocked.  R800 only helps if analog confirms a safe tune pair and if the path window grows enough.  O1C2 standard-cell setup/CQ values suggest R800 alone may not close.

### Candidate G: timing exception

Acceptable only after the data requirement is proven to be previous/stable count or a macro-internal measurement exception.  Not acceptable as a convenience false path.

## Immediate Recommendation

Do not run Innovus and do not run R800.

Commit O1C3 low-risk fixes and docs.  Then decide whether the next major work package is:

1. `O2_measurement_fabric_macro_contract`: ask analog/digital implementation to harden/provide macro views for PD/counter fabric.
2. `O2_stable_nfast_tag`: RTL redesign of `nfast_hit` with an explicit deterministic offset.

Run Genus only after one of those major decisions is implemented.  A Genus rerun of only O1C3 cleanup will still be dominated by `OSC_FAST_REAL`.
