# O1C3 PD Gate False-Hit Analysis

## Hypothesis

The external RTL review claimed that the core-level PD gate can create artificial hits:

```systemverilog
.slow_phase(pd_enable_gated & slow_phase[ns])
```

Inside `mptdc_pd_cell`, a falling edge is detected when the sampled pipeline sees `q2=1` and `q1=0`.  If the real slow tap is high but `pd_enable_gated` drops, the PD cell sees a forced falling edge that did not come from the oscillator.

## RTL Trace

Relevant RTL:

- `MPTDC/rtl/top/mptdc_core.sv`
  - `pd_enable_gated = fe_pd_enable & meas_pd_gate`
  - each PD cell receives `pd_enable_gated & slow_phase[ns]`
- `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv`
  - O1C2 behavior: `pd_gate_o = IDLE || MEASURE`
  - `snapshot_en_o = (state_q == ST_M_SNAPSHOT)`
  - `pd_clear_o = (state_q == ST_M_CLEAR)`
  - `osc_keep_alive_o = MEASURE || SNAPSHOT`
- `MPTDC/rtl/async/mptdc_hit_capture_bridge.sv`
  - samples the held PD/counter image on `posedge clk_sys` when `sample_en_i` is high.

Important sequencing:

1. The controller enters `ST_M_SNAPSHOT`.
2. With O1C2 RTL, `pd_gate_o` immediately becomes 0 after that `clk_sys` edge.
3. `snapshot_en_o` is high while `state_q == ST_M_SNAPSHOT`, so the bridge samples on the next `clk_sys` edge.
4. The fast oscillator is still alive because `osc_keep_alive_o` is high in SNAPSHOT and STOP is still latched.
5. Therefore there can be active fast tap edges while `pd_gate_o=0` and before the bridge sample.

This makes the hypothesis possible by state ordering.

Line references used:

- `MPTDC/rtl/top/mptdc_core.sv:348-351`
- `MPTDC/rtl/top/mptdc_core.sv:400-418`
- `MPTDC/rtl/top/mptdc_core.sv:500-514`
- `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv:165-176`
- `MPTDC/rtl/pd/mptdc_pd_cell.sv:83-96`
- `MPTDC/rtl/async/mptdc_hit_capture_bridge.sv:31-50`

## Local Test

Added:

```text
MPTDC/tb/unit/tb_pd_gate_false_hit_unit.sv
```

The test primes a PD cell with two high slow samples, then forces `slow_phase` low while the fast clock continues.  This emulates the core-level AND gate dropping the PD input even though the real analog slow tap may still be high.

Result:

```text
PASS tb_pd_gate_false_hit_unit: forced-low PD input creates a hit
```

Command run locally:

```bash
CCACHE_DIR=/tmp/spadmic_ccache CCACHE_TEMPDIR=/tmp/spadmic_ccache/tmp \
  bash MPTDC/scripts/sim/run_tb.sh tb_pd_gate_false_hit_unit --sim verilator
```

This proves the PD cell will latch a hit for a forced-low input transition.  It does not prove every silicon conversion would see the bug, but combined with the state trace it confirms a real reachable hazard in the current RTL sequence.

## Implemented Low-Risk Fix

Changed `mptdc_meas_ctrl` so `pd_gate_o` remains high through `ST_M_SNAPSHOT`:

```systemverilog
assign pd_gate_o = (state_q == ST_M_IDLE)
                || (state_q == ST_M_MEASURE)
                || (state_q == ST_M_SNAPSHOT);
```

Why this is the preferred first fix:

- It does not change PD-cell sampling semantics.
- It does not change START/STOP relation.
- It does not change raw field layout or packet meanings.
- It preserves capture-before-clear.
- It keeps the PD input path real until the bridge sample and row-count capture edge.
- Any forced-low edge after the transition to COUNT happens after the bridge image and row counts are already registered.

## Updated Local Checks

Updated:

```text
MPTDC/tb/unit/tb_meas_ctrl_unit.sv
```

New checks:

- `pd_gate` remains open in `ST_M_SNAPSHOT`.
- `pd_gate` closes after the snapshot sample when the controller reaches `ST_M_COUNT`.

Commands run locally:

```bash
CCACHE_DIR=/tmp/spadmic_ccache CCACHE_TEMPDIR=/tmp/spadmic_ccache/tmp \
  bash MPTDC/scripts/sim/run_tb.sh tb_meas_ctrl_unit --sim verilator

CCACHE_DIR=/tmp/spadmic_ccache CCACHE_TEMPDIR=/tmp/spadmic_ccache/tmp \
  bash MPTDC/scripts/sim/run_tb.sh tb_pd_gate_false_hit_unit --sim verilator

CCACHE_DIR=/tmp/spadmic_ccache CCACHE_TEMPDIR=/tmp/spadmic_ccache/tmp \
  bash MPTDC/sim/verilator/run_lint.sh 20260601_o1c3_local_lint
```

Results:

- `tb_meas_ctrl_unit`: PASS, 132 checks.
- `tb_pd_gate_false_hit_unit`: PASS, reproduces forced-low hit behavior.
- Verilator lint: PASS, result directory `results/local_verilator/20260601_o1c3_local_lint/`.

## Residual Risk

Functional risk is low, but this is still a measurement-sequencing change and should be included in the next Xcelium server regression.  It should not change calibrated field meanings; it only prevents a fabricated hit caused by digital teardown gating before the held snapshot.
