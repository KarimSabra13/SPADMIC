# MPTDC Handoff

This is the starting point for a new RTL, verification, synthesis, or physical
implementation owner. The active product boundary is `mptdc_axis_core`; the
current backend input is a typical-only Genus-closed netlist suitable for an
Innovus feasibility pass, not final signoff.

## Frozen baseline

| Item | Value |
| --- | --- |
| RTL product top | `MPTDC/rtl/top/mptdc_axis_core.sv` |
| Integration core | `MPTDC/rtl/top/mptdc_core.sv` |
| Frequency mode | `R750_delta5` |
| Phase distribution | `BUHDX4 -> BUHDX12` per slow/fast tap |
| PD fabric | intentional `8 x 8` Vernier matrix |
| Genus baseline commit | `fa66cc4d36936e2bf0d41e6b24f2f9486569e242` |
| Genus baseline run | `20260618_111124_axis_core_genus_timing_close_on22x1_final_guarded` |
| Genus result | WNS `+0.3 ps`, TNS `-0.0 ps`, setup paths `0`, DRVs `0` |
| Backend readiness | `READY_FOR_O13_INNOVUS_FEASIBILITY` (recorded historical tool label) |
| Signoff boundary | typical-only; not MMMC, extracted, LVS, DRC, or PEX signoff |

The server result path is external generated evidence and is not a repository
source path:

```text
/sim/ksabra/SPADMIC_work/genus/20260618_111124_axis_core_genus_timing_close_on22x1_final_guarded
```

## Canonical commands

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
```

The Genus command accepts only an optional run ID. The closure policy is stored
in `MPTDC/syn/scripts/profiles/genus_axis_core_typical_closed.sh` so an inherited
shell environment cannot silently change the handoff baseline.

## Ownership map

| Area | Source of truth | Handoff contract |
| --- | --- | --- |
| RTL | `rtl/README.md`, `docs/architecture/MPTDC_ARCHITECTURE.md` | Preserve packet format, CDC contracts, oscillator/PD intent, and product top. |
| Verification | `tb/README.md`, `docs/verification/MPTDC_VERIFICATION.md` | Product-axis smoke is maintained; old standalone VIP is archival. |
| Synthesis | `syn/README.md`, `docs/synthesis/MPTDC_SYNTHESIS_FLOW.md` | Use the canonical profile and stable SDC/filelist aliases. |
| Timing status | `docs/timing_closure/MPTDC_TIMING_CLOSURE_STATUS.md` | Typical closure is clean; physical/MMMC signoff remains open. |
| PnR | `docs/pnr/MPTDC_PNR_FLOW.md` | Begin with feasibility and preserve nonstandard oscillator/phase-clock intent. |
| Signoff limits | `docs/signoff_notes/MPTDC_SIGNOFF_LIMITATIONS.md` | Do not convert feasibility labels into final signoff claims. |

## Change rules

1. Keep generated results under `work/`; commit only concise evidence summaries.
2. Do not rename or repurpose packet fields without a coordinated RTL,
   verification, calibration, and software change.
3. Treat async frontend storage, the static held-bus bridge, oscillator clocks,
   and the PD Vernier relation as explicit design intent, not lint cleanup.
4. Give experiments hypothesis-based names. Do not make sequence labels such as
   `O13` or `REPAIR8` the public command.
5. A synthesis profile change requires before/after WNS, TNS, violation count,
   DRV count, path-family classification, and exact exception-count evidence.
6. Merge the handoff cleanup only after the local smoke, profile check, and a
   server-side Genus rerun have passed from a clean tracked tree.
