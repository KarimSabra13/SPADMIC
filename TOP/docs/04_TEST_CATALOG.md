# Active Test Catalog

## Fast gates

| Command | Scope |
| --- | --- |
| `bash TOP/ci/check_csr_map_generated.sh` | authoritative map versus generated C/Python/register CSV/field CSV/Markdown |
| `bash TOP/ci/run_smoke.sh` | map drift plus CSR and I2C matrix-top unit smoke |
| `bash TOP/ci/run_directed_regression.sh` | maintained directed block/integration manifest |
| `bash TOP/ci/run_vip_smoke.sh` | active matrix-top VIP smoke or local compile/lint fallback |
| `bash TOP/ci/run_tapeout_readiness.sh` | aggregate RTL evidence gate |

## CSR and I2C benches

| Bench | Primary checks |
| --- | --- |
| `tb_spadmic_matrix_top_csr_unit` | all pages, reset values, access policy, W1C, counters, atomic enable |
| `tb_spadmic_i2c_control_plane_unit` | protocol framing, pointer/read/write, current pointer, partial and reset aborts |
| `tb_spadmic_i2c_matrix_top_16b_unit` | full transport through router and banks |

## Matrix-top directed benches

The active set includes shell, BOTH mode, mode transition, reset-during-event,
FIFO pressure, skew campaign, event bundle, snapshot frontend, position
packetizer, source mapping, TX egress, sequencer, qualifier, and retained
cluster/position stress benches. The exact executable list is the `BENCHES`
array in `TOP/ci/run_directed_regression.sh`.

## VIP tests

| Test | Purpose |
| --- | --- |
| `smoke_tdc` | normal coordinated R/Y/B acquisition |
| `smoke_position` | cluster position path |
| `smoke_position_raw` | fixed raw position packet path |
| `smoke_switching` | legal disabled/idle mode transitions |
| `spad_reset_modes` | coordinated reset enable/width behavior |
| `i2c_end_to_end` | fixed-address wire protocol through active top |
| `tdc_modes` | normal versus calibration mask policy |
| `ctrl_reject` | unsafe/invalid CSR rejection and diagnostics |
| `coverage_walk` | deterministic ABI and fault-bin traversal |
| `stress_random` | constrained long control/event campaign |

`TOP/ci/run_vip_smoke.sh` and `TOP/ci/run_vip_coverage.sh` define the maintained
campaign membership.

## Simulator policy

Local Verilator is used for portable directed evidence and VIP compile/lint.
Xcelium is required for the class-based runtime VIP and functional covergroups.
Server results must be tied to an exact commit and archived reports.
