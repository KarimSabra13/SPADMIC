# SPADMIC TOP — Verification Results Report

Author: Karim Sabra

> **Date**: _________________  
> **Engineer**: _________________  
> **Branch**: `SPADMIC_top` @ commit `_________________`  
> **Tool**: Cadence Xcelium _________________  

---

## 1. Executive Summary

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Directed benches | 13/13 pass | ___/13 | ☐ |
| VIP smoke tests | 3/3 pass | ___/3 | ☐ |
| VIP feature tests | 6/6 pass | ___/6 | ☐ |
| VIP random tests | 3/3 pass | ___/3 | ☐ |
| Functional coverage | ≥ 95% | ___% | ☐ |
| Code coverage | ≥ 90% | ___% | ☐ |
| Functional bin review | 100% reviewed/waived | ___% | ☐ |
| Active block evidence | bench/stress/VIP/assertion or waiver for every active block | ___ | ☐ |
| Python decoder cross-check | PASS | ___ | ☐ |
| CDC/lint/formal-style gate | PASS / waived | ___ | ☐ |
| Synthesis/timing sanity | PASS / waived | ___ | ☐ |
| SVA failures | 0 | ___ | ☐ |
| **Overall** | **PASS** | ___ | ☐ |

---

## 2. Directed Bench Results

| Bench | Result | Notes |
|-------|--------|-------|
| `tb_spadmic_axis_cluster_scan_unit` | | |
| `tb_spadmic_arb_modes` | | |
| `tb_spadmic_arb_stress` | | |
| `tb_spadmic_i2c_control_plane_unit` | | |
| `tb_spadmic_ref_stop_qualifier_hold_unit` | | |
| `tb_spadmic_ref_stop_qualifier_unit` | | |
| `tb_spadmic_stress_cluster_scan` | | |
| `tb_spadmic_stress_csr` | | |
| `tb_spadmic_stress_position` | | |
| `tb_spadmic_stress_stop_qualifier` | | |
| `tb_spadmic_top_sequencer_unit` | | |

---

## 3. VIP Test Results

| Test | Seed | Result | Packets | Notes |
|------|------|--------|---------|-------|
| `smoke_tdc` | 1 | | | |
| `smoke_position` | 1 | | | |
| `smoke_switching` | 1 | | | |
| `tdc_modes` | 1 | | | |
| `pos_clusters` | 1 | | | |
| `ctrl_reject` | 1 | | | |
| `reset_recovery` | 1 | | | |
| `bp_stress` | 1 | | | |
| `i2c_end_to_end` | 1 | | | |
| `long_random` | 1 | | | |
| `coverage_walk` | 1 | | | |
| `stress_random` | multi | | | |

---

## 4. Coverage Summary

### 4.1 Functional Coverage

| Covergroup | Coverage | Bins Hit / Total |
|------------|----------|-----------------|
| `cg_stim` | ___% | ___/___ |
| `cg_tdc_pkt` | ___% | ___/___ |
| `cg_pos_pkt` | ___% | ___/___ |
| `cg_ctrl` | ___% | ___/___ |
| `cg_fault` | ___% | ___/___ |
| **Total** | **___**% | |

### 4.1.1 Mandatory Safety/Protocol Bin Review

| Category | Hit/Reviewed/Waived | Notes |
|----------|---------------------|-------|
| Reset behavior | | |
| CDC boundary assumptions | | |
| CSR faults/errors/W1C/readback | | |
| Packet grammar/source/length | | |
| Shared event IDs and wrap | | |
| FIFO pressure/queue drops/overflow | | |
| Mode transitions/drain-commit | | |

### 4.2 Code Coverage

| Module | Line | Branch | Toggle | FSM |
|--------|------|--------|--------|-----|
| `spadmic_top_v1` | ___% | ___% | ___% | N/A |
| `spadmic_csr_decoder` | ___% | ___% | ___% | ___% |
| `spadmic_global_csr` | ___% | ___% | ___% | N/A |
| `spadmic_top_sequencer` | ___% | ___% | ___% | ___% |
| `spadmic_tdc_axis_csr` | ___% | ___% | ___% | ___% |
| `mptdc_packet16_tx` | ___% | ___% | ___% | ___% |
| `spadmic_packet_arbiter4` | ___% | ___% | ___% | ___% |
| `spadmic_position_block` | ___% | ___% | ___% | ___% |
| `spadmic_tdc_axis_wrapper` | ___% | ___% | ___% | N/A |
| `spadmic_i2c_slave` | ___% | ___% | ___% | ___% |
| **Average** | **___**% | **___**% | **___**% | **___**% |

### 4.3 SVA Assertion Summary

| Assertion | Attempts | Passes | Failures |
|-----------|----------|--------|----------|
| P1: cfg_accept_gate | | | |
| P2: drain_disables | | | |
| P3: transition_clear | | | |
| P4: reject_monotonic | | | |
| P5: one_grant | | | |
| P6: source_stable | | | |
| P7: eoc_on_deassert | | | |
| P8: grant_needs_valid | | | |
| P9: sel_change_idle | | | |
| P10: pos_ready_gated | | | |
| P11: tdc_ready_gated | | | |
| P12: valid_routing | | | |
| P13: word_idx_bound | | | |
| P14: eoc_at_end | | | |
| P15: header_at_start | | | |

---

## 5. Stress Campaign Summary

| Metric | Value |
|--------|-------|
| Total seeds | ___ |
| Seeds passed | ___ |
| Seeds failed | ___ |
| Total conversions | ___ |
| Total packets captured | ___ |
| Coverage after campaign | ___% |

---

## 6. Active Block Evidence / Waivers

| Block | Evidence | Waiver needed? | Notes |
|-------|----------|----------------|-------|
| `spadmic_i2c_slave` | | | |
| `spadmic_i2c_csr_bridge` | | | |
| `spadmic_csr_decoder` | | | |
| `spadmic_global_csr` | | | |
| `spadmic_top_sequencer` | | | |
| `spadmic_ref_stop_qualifier` | | | |
| `mptdc_packet16_tx` | | | |
| `spadmic_packet_arbiter4` | | | |
| `spadmic_position_block` | | | |
| `spadmic_axis_cluster_scan` | | | |
| `spadmic_correlated_tx` | | | |
| `spadmic_ddr_tx` | | | |
| MPTDC active blocks | | | See `MPTDC/docs/verification/MPTDC_VERIFICATION.md` |

---

## 7. Off-chip Decoder Cross-check

| Artifact | Result | Notes |
|----------|--------|-------|
| Dumped logical TX words parsed by Python decoder | | |
| SV monitor packet classification matches Python decoder | | |
| TDC packet grammar | | |
| Position cluster packet grammar | | |
| Position raw packet grammar | | |
| Shared event-ID grouping | | |

---

## 8. Static and Implementation Sanity

| Gate | Result | Waivers / Notes |
|------|--------|-----------------|
| CDC/reset exception review | | |
| Lint | | |
| Formal/assertion checks | | |
| Synthesis elaboration | | |
| Timing constraints sanity | | |
| Macro contract assumptions | | |

---

## 9. Known Limitations

1. _(Fill in any untested scenarios)_
2. _(Fill in any excluded coverage bins with justification)_

---

## 10. Open Issues

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | | | |

---

## 11. Recommendation

_(Fill in: PASS / PASS WITH WAIVERS / FAIL — and next steps)_
