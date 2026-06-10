# MPTDC Verification

Author: Karim Sabra

This document defines the active verification entrypoints.  It does not claim
final signoff coverage.

## Scope

The maintained verification collateral includes:

- Unit and integration benches under `tb/unit/` and `tb/int/`.
- VIP harness and test definitions under `tb/vip/` and `tb/tests/`.
- Verilator smoke and lint scripts.
- Xcelium server smoke and regression wrappers.
- Characterization and calibration scripts for generated datasets.

Generated simulation outputs must be written under `work/`, not tracked in git.

## Local Smoke

Use the stable local smoke wrapper:

```bash
bash MPTDC/scripts/sim/run_mptdc_verilator_smoke.sh
```

The wrapper writes to `work/verilator/<run_id>/`, records the git HEAD, and
prints `FINAL_SIGNOFF=NO`.

## Xcelium Smoke

Use the stable server smoke wrapper on a machine with Cadence tools:

```bash
bash MPTDC/scripts/sim/run_mptdc_xcelium_smoke.sh
```

The wrapper writes to `work/xcelium/<run_id>/`.  Xcelium is the required check
for simulator portability issues that Verilator may not detect.

## Characterization

Use:

```bash
bash MPTDC/scripts/sim/run_mptdc_characterization.sh
```

The active characterization mode uses the fixed packet format, local fast raw
tagging, and the selected frequency mode.  The generated campaign data belongs
under `work/characterization/<run_id>/` or an external artifact store.

## Required Interpretation

- Passing local Verilator smoke is a development check only.
- Passing Xcelium smoke is a stronger portability check, not final tapeout
  signoff.
- Characterization must be rerun after the final physical phase-distribution
  topology and analog phase behavior are confirmed.
- Coverage and characterization reports should be summarized in concise markdown
  before any raw generated data is removed from git.
