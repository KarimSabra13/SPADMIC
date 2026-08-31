# RTL Readiness Gate

## Purpose

This document defines the control-plane RTL evidence needed before requesting a
new synthesis/implementation stage. It is not itself a tapeout signoff.

## Required local gates

```bash
bash TOP/ci/check_csr_map_generated.sh
bash TOP/ci/run_smoke.sh
bash TOP/ci/run_directed_regression.sh
bash TOP/ci/run_vip_smoke.sh
bash TOP/ci/run_tapeout_readiness.sh
```

Required outcomes:

- generated C/Python/register CSV/field CSV/Markdown exactly match the SV package
- active RTL compiles with no error
- CSR/I2C directed benches pass
- retained data/event/TX directed benches pass
- active VIP harness and SVA compile locally
- no active filelist, CI, or runbook references retired RTL

## Required server gates

On an exact clean commit with Xcelium:

```bash
SPADMIC_SIM=xrun bash TOP/ci/run_directed_regression.sh
bash TOP/ci/run_vip_smoke.sh
bash TOP/ci/run_vip_coverage.sh
```

Archive branch, full commit, simulator version, commands, logs, scoreboards,
assertion summaries, and functional coverage reports. Review mandatory coverage
holes explicitly.

## ABI acceptance checklist

- I2C fixed address/timing and byte order verified
- repeated-start and current-pointer reads verified
- partial writes and transport-reset aborts discarded and logged
- transport reset preserves bank state
- invalid accesses are bounded, deterministic, and diagnosed
- all config safety and value checks verified
- W1C faults and disabled/idle counter maintenance verified
- normal R/Y/B and calibration mask policies verified
- event-only conversion start and reset-width prerequisite verified
- C/Python/register CSV/field CSV/Markdown collateral generated from the same SV source

## Separate downstream gates

After RTL acceptance, each downstream phase still needs its own evidence:

| Phase | Independent evidence |
| --- | --- |
| Genus | elaboration, unmapped/black-box checks, constraints, timing, handoff files |
| CDC/STA | clock/reset assumptions, unconstrained-path review, applicable timing corners |
| Innovus | floorplan, placement, routing, regular and special connectivity, timing |
| PVS DRC | attributable immutable run and rule classification |
| PVS LVS | exact GDS/source/CDL/top attribution and explicit MATCH |
| export | exact artifacts, checksums, and destination contract |

No RTL pass authorizes OA edits or waives physical, connectivity, timing, DRC,
or LVS failures.
