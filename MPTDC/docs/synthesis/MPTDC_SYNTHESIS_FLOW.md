# MPTDC Synthesis Flow

Author: Karim Sabra

The active synthesis flow is a typical-only Cadence Genus flow for MPTDC timing
closure.  It is not MMMC signoff and is not final tapeout signoff.

## Active Command

Run from the repository root:

```bash
bash MPTDC/syn/scripts/server_run_genus_mptdc_typical.sh
```

Equivalent stable aliases are available for timing-closure and final-typical
server handoff:

```bash
bash MPTDC/syn/scripts/server_run_genus_mptdc_timing_closure.sh
bash MPTDC/syn/scripts/server_run_genus_mptdc_final_typical.sh
```

Outputs are written to `work/genus/<run_id>/`.

## Active Timing Model

The active flow uses:

- Typical-only timing view.
- R750_delta5 frequency mode.
- Real `RO_tune4` macro binding.
- Raw RO phase clocks at `RO_tune4/S[0:7]`.
- Buffered phase clocks at the final `BUHDX12` phase drivers.
- A narrow, count-checked PD intentional Vernier exception.
- Clock/CDC constraints for the async capture and context bridge.

The current stable command is the user-facing name for the latest
phase-distribution, clock/CDC, and PD Vernier repair flow.  Historical
experiment names and result notes are preserved in
`docs/timing_history/MPTDC_TIMING_CLOSURE_HISTORY.md`.

## Inputs

Protected inputs include:

- `syn/inputs/mptdc_typical_r750_delta5.sdc`.
- `syn/inputs/mptdc_clock_model_typical.sdc`.
- `syn/inputs/mptdc_pd_vernier_exceptions.sdc`.
- `syn/inputs/mptdc_phase_distribution.sdc`.
- `syn/macros/RO_tune4_real_abstract_shell.lib`.
- `analog_handoff/real_ro_tune4_abstract.env`.

The stable SDC names are aliases first.  Legacy SDC files remain until all
references are updated and validated.

## Output Policy

The Genus wrapper must:

- Print the exact run directory and git HEAD.
- Print `FINAL_SIGNOFF=NO`.
- Reject a dirty tracked tree unless `MPTDC_ALLOW_DIRTY=1`.
- Fail if required filelists, SDCs, macro abstracts, or handoff files are
  missing.
- Keep historical traceability in labels and manifests without making old
  experiment names the recommended command.

## Signoff Boundary

This flow is suitable for typical timing-closure development and backend
handoff.  It does not replace MMMC, final extracted timing, formal signoff
checks, analog phase validation, LVS, DRC, or PEX.
