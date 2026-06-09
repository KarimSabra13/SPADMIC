# SPADMIC XLIBD Cell Values Summary

Status: `REFERENCE_ONLY_NOT_TIMING_ENGINE`

Raw source: [xlibd_cell_values_spadmic_with_dfrshdx1_buhdx2_buhdx3.txt](../../MPTDC/tech/xlibd/xlibd_cell_values_spadmic_with_dfrshdx1_buhdx2_buhdx3.txt)

## Source Library

- Library view: `D_CELLS_HD_LPMOS_typ_1.80V_25C`
- VDD: `1.8 V`
- Temperature: `25 C`
- Capacitance units: `pF` and `fF`
- Time unit: `ns`
- Area unit: `um2`
- Static power unit: `pW`
- Dynamic energy form: `uW/MHz`, with `L` as output load in pF
- Selected timing reference input slope: `0.6210 ns`

These values are extracted engineering references. Genus and Innovus continue to use the full Liberty file for actual timing, optimization, and design-rule checks.

## Phase Buffer Cells

| Cell | Area um2 | Input cap fF | Q max cap fF | Q max fanout |
|---|---:|---:|---:|---:|
| `BUHDX2` | 12.54 | 5.72 | 1607 | 676 |
| `BUHDX3` | 17.56 | 8.07 | 2420 | 1018 |
| `BUHDX4` | 20.07 | 10.56 | 3227 | 1357 |
| `BUHDX6` | 27.60 | 16.23 | 4769 | 2006 |
| `BUHDX8` | 35.12 | 21.70 | 6452 | 2714 |
| `BUHDX12` | 50.18 | 32.24 | 9678 | 4071 |

Selected timing at input slope `0.6210 ns`:

| Cell | Load pF | TPLH ns | TPHL ns | Rise transition ns | Fall transition ns |
|---|---:|---:|---:|---:|---:|
| `BUHDX2` | 0.8040 | 1.8380 | 1.4838 | 2.3207 | 1.5194 |
| `BUHDX3` | 0.6058 | 0.9962 | 0.9584 | 1.1723 | 0.8588 |
| `BUHDX4` | 0.8075 | 0.9944 | 0.9437 | 1.1716 | 0.8442 |
| `BUHDX8` | 0.8074 | 0.5784 | 0.6192 | 0.5964 | 0.4280 |
| `BUHDX12` | 0.6058 | 0.3683 | 0.4630 | 0.3080 | 0.2295 |
| `BUHDX12` | 1.2106 | 0.5768 | 0.6272 | 0.5955 | 0.4391 |

## Inverter Cells

| Cell | Area um2 | Input cap fF | Q max cap fF | Q max fanout |
|---|---:|---:|---:|---:|
| `INHDX0` | 7.43 | 2.92 | 335 | 140 |
| `INHDX1` | 7.53 | 4.78 | 714 | 300 |
| `INHDX4` | 15.05 | 18.70 | 2877 | 1210 |
| `INHDX6` | 20.07 | 27.89 | 4483 | 1885 |
| `INHDX12` | 35.12 | 55.64 | 8679 | 3651 |

`INHDX12` is strong but has high input cap. Do not use it directly on `RO_tune4/S[n]` without analog review.

## Logic Cells

| Cell | Area um2 | A cap fF | B cap fF | Q max cap fF | Q max fanout |
|---|---:|---:|---:|---:|---:|
| `EO2HDX0` | 19.97 | 5.24 | 5.53 | 175 | 73 |

`EO2HDX0` is useful for interpreting XOR-like critical path points only. Do not use this reference to force logic mapping.

## DFF Cells

| Cell | Area um2 | C cap fF | D cap fF | RN cap fF | Q max cap fF | Q max fanout |
|---|---:|---:|---:|---:|---:|---:|
| `DFRRQHDX1` | 57.70 | 3.62 | 3.19 | 7.32 | 799 | 336 |
| `DFRRQHDX2` | 60.21 | 3.45 | 3.20 | 6.51 | 1587 | 667 |
| `DFRRQHDX4` | 65.23 | 3.60 | 3.19 | 6.37 | 3025 | 1272 |
| `DFRQHDX2` | 50.18 | 3.63 | 2.70 | NA | 1590 | 668 |
| `DFRHDX1` | 52.68 | 3.63 | 2.71 | NA | 794 | 334 |

`DFRSHDX1` is a set flop, not a reset flop:

| Cell | Area um2 | C cap fF | D cap fF | SN cap fF | Q/QN max cap fF | Q/QN max fanout |
|---|---:|---:|---:|---:|---:|---:|
| `DFRSHDX1` | 57.70 | 3.64 | 2.70 | 8.61 | 794 | 334 |

Key `DFRRQHDX2` constraint maxima from the extracted table:

- Setup D to C rise/fall: `0.4316 ns` / `1.3358 ns`
- Hold D to C rise/fall: `0.3846 ns` / `0.1310 ns`
- Recovery RN to C rise: `2.5845 ns`
- Removal RN to C rise: `0.2017 ns`
- Min width C high/low: `0.4684 ns` / `0.5096 ns`
- Min width RN low: `0.5535 ns`

## Scan DFF Cells

| Cell | dont_use | CN cap fF | D cap fF | SD cap fF | SE cap fF | Q max cap fF |
|---|---|---:|---:|---:|---:|---:|
| `SDFFQHDX2` | true | 3.80 | 3.33 | 2.98 | 5.89 | 1587 |
| `SDFFQHDX4` | true | 3.80 | 3.33 | 2.99 | 5.89 | 3163 |

Scan cells exist but remain `dont_use` for normal synthesis unless a deliberate DFT strategy is introduced.

## SPADMIC Reference Budgets

- Strict analog RO D-load budget: `58.72 fF`
- CN/clock-like analog estimate: `75.59 fF`
- O13 intended raw RO first-cell load: `BUHDX4` input cap `10.56 fF`; measured raw pin load must still come from Innovus DB reports.
- Provisional IO load unit: `DFRRQHDX2 D_CAP = 3.20 fF`

## Missing Values For Later Detailed Analysis

Do not block O13 abs3 on these. Extract them when detailed path-level timing asks for them:

- `INHDX2`
- `ON22HDX0`
- `ON22HDX1`
- `BUHDX0`
- `BUHDX1`
- Optional: dedicated clock buffers/inverters and integrated clock-gating cells
