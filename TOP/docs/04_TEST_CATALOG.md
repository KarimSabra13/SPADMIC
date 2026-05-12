# SPADMIC TOP — Test Catalog

## 1. Directed Benches (Unit/Stress Layer)

| # | Bench | Block Under Test | Key Checks |
|---|-------|-------------------|------------|
| 1 | `tb_spadmic_axis_cluster_scan_unit` | Axis cluster scanner | Single/dual/overflow cluster extraction |
| 2 | `tb_spadmic_i2c_control_plane_unit` | I2C → CSR bridge | I2C write/read, pointer handling, NACK |
| 3 | `tb_spadmic_ref_stop_qualifier_hold_unit` | Stop qualifier | Hold timing, qualifier window |
| 4 | `tb_spadmic_ref_stop_qualifier_unit` | Stop qualifier | Basic qualification, timeout |
| 5 | `tb_spadmic_shared_tx_mux_unit` | Legacy TX mux | Source selection on the older logical mux path |
| 6 | `tb_spadmic_stress_arbiter` | TDC arbiter | Fairness, back-to-back, starvation |
| 7 | `tb_spadmic_stress_cluster_scan` | Cluster scanner | Random patterns, gap/span sweep |
| 8 | `tb_spadmic_stress_csr` | CSR decoder + global CSR | All-region RW, timeout, back-to-back |
| 9 | `tb_spadmic_stress_position` | Position block | Full FSM exercise, packet framing |
| 10 | `tb_spadmic_stress_stop_qualifier` | Stop qualifier | Stress random timing |
| 11 | `tb_spadmic_tdc_arbiter3_unit` | Legacy 3-way arbiter | (Legacy — secondary priority) |
| 12 | `tb_spadmic_tdc_shared_readout_unit` | Shared readout | Round-robin, atomicity, META-first |
| 13 | `tb_spadmic_top_sequencer_unit` | Top sequencer | RESET→IDLE→DRAIN FSM |

## 2. VIP Smoke Tests (Must-Pass Gate)

| Test | Scenario | Accept Criteria |
|------|----------|-----------------|
| `smoke_tdc` | Enable all axes + CAL, 1 event/axis, collect 3 packets | 3 valid TDC packets with correct source tags |
| `smoke_position` | Enable position, single-cluster X-axis, 1 packet | 1 valid 12-word position packet |
| `smoke_switching` | TDC→drain→position→drain→TDC | Clean transitions, no interleaving, no faults |

## 3. VIP Feature Tests

| Test | Scenario | Accept Criteria |
|------|----------|-----------------|
| `tdc_modes` | 3 modes × 4 max_hits = 12 combos | All 12 combos produce correct packets |
| `pos_clusters` | 3 gap × 3 span × patterns | Cluster extraction matches reference |
| `ctrl_reject` | CTRL write while NOT idle | `mode_reject_sticky=1`, count increments |
| `reset_recovery` | Reset during TDC packets | Recovery to clean config + new packets |
| `bp_stress` | READY→RANDOM→STALL→recovery | All packets eventually delivered |
| `i2c_end_to_end` | Full I2C programming + readback | Correct data through I2C path |

## 4. VIP Constrained-Random Tests

| Test | Phases | Seeds | Focus |
|------|--------|-------|-------|
| `long_random` | 50 | 1 | Legal/coherent mixed TDC/position/switching/BP/correlated traffic |
| `coverage_walk` | Systematic | 1 | Fill cross-coverage holes |
| `stress_random` | 200 | 20–100 | Legal/coherent high-volume coverage closure with explicit phase weights |

Random phase weights can be overridden through `run_vip_test.sh`:

```bash
--random-legal-only 0|1
--rand-w-tdc N --rand-w-pos N --rand-w-switch N --rand-w-bp N --rand-w-corr N
```

The default is legal-only randomization. Fault campaigns that intentionally use
reset-during-traffic, FIFO-full pressure, or permanently stalled output must be
named and checked as stress/fault tests rather than mixed into ordinary random.

## 5. Mission Profile Weights

| Profile | Weight | Primary Scenario |
|---------|--------|------------------|
| TDC Characterization | 50% | CAL events, all modes, all axes |
| Position Detection | 20% | Line patterns, cluster diversity |
| Mode Switching | 15% | TDC↔Position transitions with drain |
| Stress/Corner | 15% | Reset, stall, fast-close, simultaneous |

## 6. Acceptance Criteria

- [ ] All 13 directed benches pass on Xcelium
- [ ] All 3 smoke tests pass
- [ ] All 6 feature tests pass
- [ ] `long_random` passes with seed=1
- [ ] `coverage_walk` passes
- [ ] `stress_random` passes with ≥20 seeds
- [ ] Functional coverage ≥ 95%
- [ ] Code coverage ≥ 90%
- [ ] 0 SVA assertion failures across all runs
