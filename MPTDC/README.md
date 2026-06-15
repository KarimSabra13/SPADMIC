# MPTDC

Author: Karim Sabra

MPTDC is the SPADMIC Vernier multi-phase time-to-digital converter.  The active
repository view is a typical-only closure and documentation workspace: it keeps
RTL, verification, synthesis, PnR, calibration, and compact evidence in git,
while generated tool outputs belong under `work/`.

This checkout does not claim final tapeout signoff.  MMMC, final analog
confirmation, final LVS/DRC/PEX, and final post-layout characterization remain
open signoff work.

## Active Design

- Product top level: `rtl/top/mptdc_axis_core.sv`
- Core: `rtl/top/mptdc_core.sv`
- Package constants and packet types: `rtl/pkg/mptdc_pkg.sv`
- Oscillator and phase distribution: `rtl/osc/`
- Phase detector matrix: `rtl/pd/`
- Async capture and context bridge: `rtl/async/`
- Drain, FIFO, and product packet readout: `rtl/ctrl/`, `rtl/readout/`

The current architecture uses two `RO_tune4` oscillator macros, slow and fast
phase distribution buffers, an `8 x 8` intentional Vernier phase-detector
    matrix, local raw fast tagging, a slow Johnson epoch, and a fixed product
    packet format emitted directly from `mptdc_axis_core`.  See
[`docs/architecture/MPTDC_ARCHITECTURE.md`](docs/architecture/MPTDC_ARCHITECTURE.md).

## Standard Output Policy

New generated output goes under:

```text
../work/
  genus/
  innovus/
  xcelium/
  verilator/
  characterization/
  calibration/
  plots/
  logs/
  evidence/
  scratch/
```

The `work/` tree is ignored by git except for its README.  Do not add Genus,
Innovus, Xcelium, Verilator, waveform, database, large CSV, or checkpoint
outputs to source control.

## Active Commands

Run these commands from the repository root:

```bash
bash MPTDC/syn/scripts/server_run_genus_mptdc_typical.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh
bash MPTDC/scripts/sim/run_mptdc_verilator_smoke.sh
bash MPTDC/scripts/sim/run_mptdc_xcelium_smoke.sh
bash MPTDC/scripts/sim/run_mptdc_characterization.sh
bash MPTDC/scripts/calibration/run_mptdc_calibration.sh
```

The stable wrappers print the run directory, git HEAD, and
`FINAL_SIGNOFF=NO`.  They reject a dirty tracked tree unless
`MPTDC_ALLOW_DIRTY=1` is set.

## Documentation

| Area | Document |
| --- | --- |
| Architecture | [`docs/architecture/MPTDC_ARCHITECTURE.md`](docs/architecture/MPTDC_ARCHITECTURE.md) |
| Verification | [`docs/verification/MPTDC_VERIFICATION.md`](docs/verification/MPTDC_VERIFICATION.md) |
| Synthesis | [`docs/synthesis/MPTDC_SYNTHESIS_FLOW.md`](docs/synthesis/MPTDC_SYNTHESIS_FLOW.md) |
| PnR | [`docs/pnr/MPTDC_PNR_FLOW.md`](docs/pnr/MPTDC_PNR_FLOW.md) |
| Calibration | [`docs/calibration/MPTDC_CALIBRATION_FLOW.md`](docs/calibration/MPTDC_CALIBRATION_FLOW.md) |
| Timing status | [`docs/timing_closure/MPTDC_TIMING_CLOSURE_STATUS.md`](docs/timing_closure/MPTDC_TIMING_CLOSURE_STATUS.md) |
| Signoff limitations | [`docs/signoff_notes/MPTDC_SIGNOFF_LIMITATIONS.md`](docs/signoff_notes/MPTDC_SIGNOFF_LIMITATIONS.md) |
| Historical closure log | [`../docs/timing_history/MPTDC_TIMING_CLOSURE_HISTORY.md`](../docs/timing_history/MPTDC_TIMING_CLOSURE_HISTORY.md) |

## Protected Inputs

Keep these categories versioned:

- RTL, testbenches, VIP, filelists, scripts, and constraints.
- `RO_tune4` macro abstracts under `syn/macros/`.
- Analog handoff inputs under `analog_handoff/`.
- XLIBD reference/config files under `tech/xlibd/` and `pnr/config/`.
- Concise architecture, flow, timing, and evidence documentation.
