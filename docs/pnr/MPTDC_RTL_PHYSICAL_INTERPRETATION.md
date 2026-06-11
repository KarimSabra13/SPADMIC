# MPTDC RTL Physical Interpretation

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## Source Files

- `MPTDC/rtl/top/mptdc_top_asic.sv`
- `MPTDC/rtl/top/mptdc_core.sv`
- `MPTDC/rtl/pkg/mptdc_pkg.sv`
- `MPTDC/rtl/pd/mptdc_pd_cell.sv`
- `MPTDC/rtl/pd/mptdc_fast_epoch_tag.sv`
- `MPTDC/rtl/cdc/mptdc_sync_fifo.sv`
- `MPTDC/rtl/readout/mptdc_csr_minimal.sv`

## Physical Meaning

The package geometry is an 8-by-8 phase detector fabric. The physical plan
therefore treats the 64 PD cells as a central matrix, with slow phase
distribution associated with one axis and fast phase distribution associated
with the other axis.

The oscillator wrappers provide `RO_tune4` phase taps. The physical design must
not bury raw RO outputs under uncontrolled fanout. The O13 buffer chain is the
physical interface between the analog RO macro outputs and the synthesized
phase fabric.

Fast-tag logic is timing-real setup logic. It was closed in Genus by targeted
tap0 bit 5/6 pressure, not by false-path or multicycle relaxation. Keep that
interpretation in Innovus timing reports.

The synchronous FIFO and readout logic are backend logic. They belong on the
east side with control, CSR, acquisition, and status paths, away from the
matched RO/PD island unless timing evidence requires a local exception.
