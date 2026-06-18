# MPTDC Verification

Author: Karim Sabra

The maintained verification boundary is `mptdc_axis_core`. This document defines
handoff gates; it does not claim final coverage or analog/post-layout signoff.

## Verification layers

| Layer | Maintained entrypoint | Required interpretation |
| --- | --- | --- |
| Verilator lint + product smoke | `bash MPTDC/ci/run_smoke.sh` | Fast development gate for compile, lint, and the active product bench. |
| Local product regression | `bash MPTDC/ci/run_full_regression.sh` | Required after RTL/filelist/define changes. |
| Stable local wrapper | `bash MPTDC/scripts/sim/run_mptdc_verilator_smoke.sh` | Writes reproducible evidence under `work/verilator/`. |
| Xcelium smoke | `bash MPTDC/scripts/sim/run_mptdc_xcelium_smoke.sh` | Required Cadence portability/event-semantics check. |
| Synthesis policy check | `bash MPTDC/syn/scripts/check_genus_axis_core_typical_closed_profile.sh` | Verifies wrapper syntax and exact closed-profile values without running Genus. |
| Physical timing | canonical Genus and Innovus wrappers | Verifies mapped/physical feasibility; does not replace functional simulation. |

The active product integration test is
`tb/int/tb_axis_core_product_smoke.sv`. The class-based standalone VIP under
`tb/vip/` is archival because it targets the retired CSR/readout boundary.

Verilator-based wrappers require a local `verilator` binary. Cadence server
bring-up may have Xcelium but not Verilator; in that case record the Verilator
gate as blocked by tool availability and keep the Xcelium smoke result separate.

## Minimum handoff scenarios

The maintained product regression must exercise:

- asynchronous and soft reset behavior;
- SPAD versus calibration input selection;
- conversion arm and normal START/STOP completion;
- packet valid/ready, SOP/EOP, and backpressure;
- FIFO clear and full/status behavior;
- rejected START/overflow accounting;
- watchdog recovery when STOP does not arrive;
- consecutive conversions without stale context leakage.

Focused unit tests are useful for local logic but do not replace the product
boundary test.

## Timing-sensitive intent

Simulation warnings must be interpreted against the architecture. The async
frontend contains intentional latch-style state; oscillator phases act as clocks
and data in the measurement fabric; the context bridge uses a static held-bus
protocol. These structures require targeted assertions/review rather than blind
lint suppression or automatic synchronization of every bit.

## Evidence and rerun policy

Generated logs, waves, coverage databases, and campaign data belong under
`work/`. A review summary records the git commit, command, tool version, seed or
test list, pass/fail count, and exclusions.

The June 18, 2026 Genus result proves typical mapped timing for its exact RTL and
profile. It does not prove that simulation still passes after repository cleanup.
Before merging a handoff refactor, run the local smoke and profile check. Before
updating the functional baseline, also run the full regression and Xcelium smoke.
RTL or timing-policy changes require a fresh Genus result; physical topology
changes additionally require Innovus and characterization reruns.
