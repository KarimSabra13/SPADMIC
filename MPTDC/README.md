# MPTDC

Author: Karim Sabra

MPTDC is the SPADMIC multi-phase Vernier time-to-digital converter. The active
repository boundary is one product axis with a 16-bit packet stream. RTL,
verification, synthesis/PnR inputs, calibration code, and concise evidence are
versioned; generated tool output belongs under `work/`.

Start with [`HANDOFF.md`](HANDOFF.md).

## Handoff rule

The active handoff path is product-axis first: `mptdc_axis_core`, product smoke,
canonical Genus profile, then Innovus feasibility. Retired standalone CSR/VIP
handoff drafts and O-stage narrative documents were removed from the active
documentation set. Backend compatibility names may still appear inside scripts
and generated evidence so old reports remain traceable, but new work should use
the stable purpose-named entrypoints listed here.

## Active design

- Product top: `rtl/top/mptdc_axis_core.sv`
- Integration core: `rtl/top/mptdc_core.sv`
- Package and packet contract: `rtl/pkg/mptdc_pkg.sv`
- Oscillator and phase distribution: `rtl/osc/`
- Intentional `8 x 8` Vernier detector matrix: `rtl/pd/`
- Async capture and held-context bridge: `rtl/async/`
- System control, drain, FIFO, and packet output: `rtl/ctrl/`, `rtl/readout/`

The active physical model uses two `RO_tune6` layout-backed RO macros and a
two-stage `BUJIHDX4 -> BUJIHDX12` digital phase distribution per tap. Slow and
fast RO tuning codes enter through TOP-owned CSR values and are captured into
local idle-only shadow registers before driving the RO macros. The internal RO
instance path remains `u_ro_tune4` to preserve the validated timing/report
constraint surface while the macro master is `RO_tune6`. `mptdc_top_asic` and
the retired standalone CSR/VIP boundary are not the product synthesis top.

## Stable entrypoints

Run from the repository root:

```bash
bash MPTDC/ci/run_smoke.sh
bash MPTDC/ci/run_full_regression.sh
bash MPTDC/scripts/sim/run_mptdc_xcelium_smoke.sh
bash MPTDC/scripts/sim/run_mptdc_characterization.sh
bash MPTDC/scripts/calibration/run_mptdc_calibration.sh
bash MPTDC/syn/scripts/check_genus_axis_core_typical_closed_profile.sh
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh --mode discover_only
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh --mode validate_only
```

The stable wrappers record the run directory and git HEAD, print
`FINAL_SIGNOFF=NO`, and reject a dirty tracked tree unless
`MPTDC_ALLOW_DIRTY=1` is intentionally set.

The digital signoff wrapper is not a renamed typical wrapper. It must remain
fail-closed until the PDK physical cells, MMMC setup, power, CTS, routing,
extraction, antenna, DRC, LVS, and deliverable checks have concrete evidence.

## Documentation

| Area | Document |
| --- | --- |
| Handoff index | [`HANDOFF.md`](HANDOFF.md) |
| Documentation map | [`docs/README.md`](docs/README.md) |
| RTL ownership | [`rtl/README.md`](rtl/README.md) |
| Architecture | [`docs/architecture/MPTDC_ARCHITECTURE.md`](docs/architecture/MPTDC_ARCHITECTURE.md) |
| Verification | [`docs/verification/MPTDC_VERIFICATION.md`](docs/verification/MPTDC_VERIFICATION.md) |
| Synthesis | [`docs/synthesis/MPTDC_SYNTHESIS_FLOW.md`](docs/synthesis/MPTDC_SYNTHESIS_FLOW.md) |
| Genus profile rationale | [`docs/synthesis/GENUS_AXIS_CORE_TYPICAL_CLOSED_PROFILE.md`](docs/synthesis/GENUS_AXIS_CORE_TYPICAL_CLOSED_PROFILE.md) |
| Timing status | [`docs/timing_closure/MPTDC_TIMING_CLOSURE_STATUS.md`](docs/timing_closure/MPTDC_TIMING_CLOSURE_STATUS.md) |
| PnR | [`docs/pnr/MPTDC_PNR_FLOW.md`](docs/pnr/MPTDC_PNR_FLOW.md) |
| Signoff limits | [`docs/signoff_notes/MPTDC_SIGNOFF_LIMITATIONS.md`](docs/signoff_notes/MPTDC_SIGNOFF_LIMITATIONS.md) |

## Output policy

New generated data goes under the repository-level `work/` tree:

```text
work/{genus,innovus,xcelium,verilator,characterization,calibration,evidence,logs,scratch}/
```

Do not add tool databases, logs, waveforms, checkpoints, large CSV files, or
raw run directories to source control. Keep only reviewed summaries that state
the source commit, command, run ID, result, and signoff boundary.
