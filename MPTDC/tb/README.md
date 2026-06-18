# MPTDC Verification Collateral

Author: Karim Sabra

The maintained verification target is the product boundary
`mptdc_axis_core`. The former standalone CSR/readout VIP remains under `vip/`
for archival or reusable components, but it is not part of the product smoke or
regression filelists.

## Maintained checks

| Check | Command | Purpose |
| --- | --- | --- |
| Lint + product smoke | `bash MPTDC/ci/run_smoke.sh` | Fast local gate around `tb_axis_core_product_smoke`. |
| Local regression | `bash MPTDC/ci/run_full_regression.sh` | Maintained integration suite and top-level lint. |
| Stable Verilator wrapper | `bash MPTDC/scripts/sim/run_mptdc_verilator_smoke.sh` | Reproducible `work/verilator/<run_id>` evidence. |
| Xcelium smoke | `bash MPTDC/scripts/sim/run_mptdc_xcelium_smoke.sh` | Cadence simulator portability and event-semantics check. |
| TOP integration | TOP-level arbitration benches under `TOP/tb/` | Confirms product-axis packet integration beyond this block. |

The active product bench is `int/tb_axis_core_product_smoke.sv`. Unit benches
under `unit/` may be used for focused logic changes, but they do not replace the
product integration gate.

## Required behavioral coverage

A handoff regression should cover reset and soft reset, SPAD and calibration
input selection, conversion arm, START/STOP acquisition, normal packet
backpressure, FIFO clear, overflow/rejected START behavior, watchdog recovery,
consecutive conversions, and the slow/fast RO-code contract. The RO-code checks
must prove reset-default zero behavior, idle capture of nonzero CSR values, and
that `soft_reset_i` does not force the local code shadows to zero.
Timing-sensitive analog behavior remains modeled; physical phase/jitter
validation is a separate analog/post-layout task.

## Evidence policy

Generated logs, waveforms, coverage databases, and CSV data belong under
`work/`. Commit a concise summary only when it is needed for a review. The
summary must record the git commit, simulator/version, command, seed or test
list, pass/fail count, and known exclusions.

## Handoff gate

The Genus closure result does not replace functional verification. After script
or documentation-only cleanup, run at least the local smoke and synthesis
profile check. After RTL, filelist, define, reset, CDC, packet, or timing-policy
changes, run the full local regression, Xcelium smoke, and the affected physical
flow before declaring the handoff baseline updated.
