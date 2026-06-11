# SPADMIC_test Verification Plan

## Local Verilator

Run at minimum:

```bash
bash MPTDC/scripts/sim/run_tb.sh tb_meas_ctrl_unit --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_async_frontend_teardown_unit --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_context_bank_unit --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_drain_ctrl_unit --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_drain_opt_unit --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_narrow16_tx_v2_unit --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_drain_raw_tag_unit --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_single_conv --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_multi_conv_stress --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_backpressure --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_lossless_pressure --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_watchdog_recovery --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
bash MPTDC/scripts/sim/run_tb.sh tb_10_events_spacing_sweep --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
```

## Added Tests

- `tb_async_frontend_teardown_unit`
- `tb_drain_opt_unit`
- `tb_10_events_spacing_sweep`

Coverage targets:

- START during teardown rejected.
- Clear release before re-arm.
- H=0 row-skip drain.
- H=1 in each row.
- H=15 sparse drain.
- Adjacent stride-2 hits.
- Backpressure while a stride-2 hit pair is pending.
- Saturated hit bitmap with `hit_count=15` emits exactly 15 HIT records.
- Ten-event spacing sweep closes accounting and packet output at 40, 60, 80, 100, 150, 200, 300, and 600 ns.

## Spacing Sweep

Use a dedicated integration/VIP run for 10 events at:

40 ns, 60 ns, 80 ns, 100 ns, 150 ns, 200 ns, 300 ns, 600 ns.

Check no lost event above predicted safe interval and correct overflow or stall behavior below the interval.

Implemented local bench:

```bash
bash MPTDC/scripts/sim/run_tb.sh tb_10_events_spacing_sweep --freq-mode r750_delta5 --mptdc-opt-mode STRIDE2
```

The local STRIDE2 Verilator run passed. It observed short-gap rejects and zero rejects at 200 ns, 300 ns, and 600 ns in the behavioral oscillator model.

## Known Local Gap

`tb_lossless_pressure` currently fails in the saturated-FIFO `saturation_release max_hits=1` envelope even in `BASELINE`. Keep it as an open pre-existing stress issue and do not treat it as a STRIDE2 regression unless a fresh SPADMIC_FINAL run proves otherwise.
