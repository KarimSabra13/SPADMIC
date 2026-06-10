# MPTDC PnR Flow

Author: Karim Sabra

The active PnR flow is a typical-only Innovus feasibility and timing-closure
flow.  It is not final tapeout signoff.

## Active Commands

Run from the repository root:

```bash
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_typical.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_final_typical.sh
```

Outputs are written to `work/innovus/<run_id>/`.

## Physical Intent

The active PnR model preserves:

- `RO_tune4/S[0:7]` as raw analog source/load-check pins.
- BUHDX4 isolation followed by BUHDX12 final phase drivers.
- Matched slow and fast phase-buffer topology.
- No CTS on RO or buffered phase clocks.
- Ordinary CTS policy for `clk_sys`.
- Explicit RO raw-load reporting and phase-buffer output-load reporting.

The `RO_tune4` macro abstracts, analog handoff files, and XLIBD references are
protected source inputs and must not be removed during cleanup.

## Constraints

Stable PnR constraint aliases are:

- `pnr/constraints/mptdc_typical_r750_delta5.sdc`.
- `pnr/constraints/mptdc_clock_model_typical.sdc`.
- `pnr/constraints/mptdc_phase_distribution.sdc`.
- `pnr/constraints/mptdc_io_load_model.sdc`.

These aliases initially source or mirror existing validated overlays.  Legacy
constraint filenames remain until all wrappers and docs are updated.

## Outputs

Generated PnR directories, logs, reports, checkpoints, routed databases, and
tarballs belong under `work/innovus/` or an external artifact store.  Git should
keep only compact summaries and curated evidence indexes.

## Signoff Boundary

This flow is a feasibility and closure flow.  It does not claim:

- MMMC closure.
- Final extracted post-layout timing.
- Final analog phase confirmation.
- LVS/DRC/PEX completion.
- Tapeout-ready signoff.
