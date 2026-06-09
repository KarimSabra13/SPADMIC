# O13 XLIBD Reference Update

Status: `REFERENCE_LAYER_UPDATED_NOT_SIGNOFF`

## Current Raw Reference

- Raw file: [xlibd_cell_values_spadmic_with_dfrshdx1_buhdx2_buhdx3.txt](../../MPTDC/tech/xlibd/xlibd_cell_values_spadmic_with_dfrshdx1_buhdx2_buhdx3.txt)
- Source library: `D_CELLS_HD_LPMOS_typ_1.80V_25C`
- Voltage/temperature: `1.8 V / 25 C`
- Timing reference input slope: `0.6210 ns`

This file supersedes the previous partial XLIBD extraction for SPADMIC timing and PNR interpretation. Genus and Innovus still use the full Liberty view for timing, optimization, and DRV checks.

## Newly Covered Cells

- Buffers: `BUHDX2`, `BUHDX3`, `BUHDX4`, `BUHDX6`, `BUHDX8`, `BUHDX12`
- Inverters: `INHDX0`, `INHDX1`, `INHDX4`, `INHDX6`, `INHDX12`
- Logic: `EO2HDX0`
- Flops: `DFRRQHDX1`, `DFRRQHDX2`, `DFRRQHDX4`, `DFRQHDX2`, `DFRHDX1`, `DFRSHDX1`
- Scan flops: `SDFFQHDX2`, `SDFFQHDX4`

## Flow Changes

- The compact Tcl config now includes selected values from the superseding extraction.
- O13 Innovus reports now have separate XLIBD-aware raw RO, final phase-output, and fast-tag load CSVs.
- The provisional IO model remains based on `DFRRQHDX2 D_CAP = 3.20 fF`.
- Reset documentation now distinguishes `RN` reset flops from the `SN` set flop `DFRSHDX1`.

## O13 Decision

Keep the current O13 topology:

```text
RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric
```

`BUHDX2` and `BUHDX3` are useful intermediate-drive options but are not final-driver candidates for the observed `0.5-0.7 pF` phase output loads. `INHDX12` is also not a first-stage isolation candidate because its `55.64 fF` input cap is too close to the strict `58.72 fF` analog budget and it inverts phase.

## Remaining Useful Values

Do not block O13 abs3 on these:

- `INHDX2`
- `ON22HDX0`
- `ON22HDX1`
- `BUHDX0`
- `BUHDX1`
- dedicated clock buffers/inverters, if they exist
- integrated clock-gating cells, if later CTS or low-power analysis needs them
