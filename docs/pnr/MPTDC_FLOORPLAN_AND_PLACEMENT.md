# MPTDC Floorplan And Placement

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## Default Geometry

Default core utilization is `55%`.

North-to-south ordering:

```text
slow RO_tune4
slow BUHDX4/BUHDX12 phase-buffer row
central 8x8 PD island
fast BUHDX12/BUHDX4 phase-buffer row
fast RO_tune4
```

`clk_sys`, control, FIFO, CSR, and readout logic are placed east of the matched
RO/phase/PD region.

## PD Island

`MPTDC_PNR_PLACE_PD_GRID=1` enables placement/audit of the 64 PD cells in an
8x8 grid. The grid is interpreted as slow phase by row and fast phase by
column unless physical pin evidence requires a documented swap.

## Fast Tags

`MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=1` places or audits fast-tag logic by PD
column when the synthesized hierarchy is placeable. This is a placement hint,
not a change to RTL timing semantics.

## Phase Buffers

Freeze the O13 topology:

```text
RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric
```

The `BUHDX4` cell is the isolation stage seen by the RO output. The `BUHDX12`
cell is the final driver stage seen by the PD/phase fabric. Do not resize only
one tap unless the mismatch is reviewed.

## Required Reports

- floorplan box and utilization manifest
- macro supply pin connection report
- PD grid placement/audit CSV
- phase-buffer placement CSV
- phase route mismatch report
- fast-tag column-placement report when enabled
