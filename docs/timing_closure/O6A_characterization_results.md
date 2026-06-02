# O6A Current Raw-LFSR Characterization Results

Date: 2026-06-02

Mode: `O6A_best_current_raw_lfsr_tag`

Reviewed HEAD: `1506b050db1f0a86c5c7b912b3364f885fcaff29`

## Stage 0 Local Regression

Command:

```bash
bash MPTDC/sim/verilator/run_smoke.sh 20260602_o6_stage0_current_raw_lfsr_tag
```

Result:

```text
Passed steps: 17
Failed steps: 0
```

Summary path:

```text
results/local_verilator/20260602_o6_stage0_current_raw_lfsr_tag/SUMMARY.md
```

Passed checks:

- lint
- `tb_slow_epoch_johnson_unit`
- `tb_stop_epoch_capture_async_unit`
- `tb_johnson_decode_unit`
- `tb_fast_epoch_tag_unit`
- `tb_pd_cell_tag_capture_unit`
- `tb_pd_gate_false_hit_unit`
- `tb_drain_raw_tag_unit`
- `tb_meas_ctrl_unit`
- `tb_hit_capture_bridge_unit`
- `tb_context_bank_unit`
- `tb_drain_ctrl_unit`
- `tb_single_conv`
- `tb_backpressure`
- `vip_smoke_single_conv`
- `vip_backpressure_integrity`
- `vip_vip_maxhits_matrix`

This is local Verilator evidence only. It does not replace Xcelium
characterization, calibration, or timing evidence.

## Stage 1 Xcelium Smoke

Status: pending.

Use the command in `docs/timing_closure/O6_characterization_gate_plan.md`.

## Stage 2 Medium Characterization

Status: pending.

Use the command in `docs/timing_closure/O6_characterization_gate_plan.md` only
after Stage 1 passes.

## Genus Gate

Genus remains blocked until Stage 1 and Stage 2 pass.
