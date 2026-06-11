# MPTDC IO Constraint Plan

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## Pin Sides

- West: SPAD and calibration asynchronous inputs.
- East: `acq_*`, CSR, status, FIFO/control, and readout-facing signals.
- Low priority: `narrow_*` legacy signals.
- Outside this block: chip-visible TX integration.

## Load Policy

Default class: `medium`

The block-level IO load policy is provisional and non-pad-signoff. The stable
constraint alias is:

`MPTDC/pnr/constraints/mptdc_io_block_constraints.sdc`

Classes:

- `light`: `12.8 fF`
- `medium`: `25.6 fF`
- `heavy`: `51.2 fF`

Use `MPTDC_PNR_IO_LOAD_CLASS=medium` unless review asks for another class.

## Reports

- IO side assignment summary
- output load application report
- reset/control transition report
- acquisition/readout timing report
- packet and CSR connectivity report
