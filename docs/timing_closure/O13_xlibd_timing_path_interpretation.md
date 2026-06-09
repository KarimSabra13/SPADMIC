# O13 XLIBD Timing Path Interpretation

Status: `REPORT_INTERPRETATION_ONLY`

Use XLIBD values to make Genus timing reports easier to understand. Do not use them to replace the Liberty timing engine, force cell mapping, or waive constraints.

## How To Read Top Paths

For each top path, annotate the endpoint/startpoint cells when the report exposes the cell type:

| Cell family | Interpretation |
|---|---|
| `BUHDX2`, `BUHDX3` | Intermediate-drive buffers; not final phase drivers for `0.5-0.7 pF` loads. |
| `BUHDX4` | Preferred first RO isolation cell, `10.56 fF` input cap. |
| `BUHDX12` | Preferred O13 final phase driver among extracted BUHD cells. |
| `INHDX0`, `INHDX1` | Small inverters; not phase final drivers. |
| `INHDX12` | Strong inverter, but `55.64 fF` input cap is too close to strict RO budget for direct RO loading. |
| `EO2HDX0` | XOR logic; useful for explaining small-gate path delay/load, not a topology decision by itself. |
| `DFRRQHDX1/2/4` | Reset flops with real `RN` recovery/removal/min-pulse checks. |
| `DFRQHDX2`, `DFRHDX1` | No-reset flop references for D/clock load interpretation. |
| `DFRSHDX1` | Set flop with `SN`, not a reset flop. |

## Useful Reference Values

- Strict analog RO D-load budget: `58.72 fF`
- CN/clock-like RO estimate: `75.59 fF`
- `DFRRQHDX1` D/C/RN caps: `3.19 / 3.62 / 7.32 fF`
- `DFRRQHDX2` D/C/RN caps: `3.20 / 3.45 / 6.51 fF`
- `DFRQHDX2` D/C caps: `2.70 / 3.63 fF`
- `DFRHDX1` D/C caps: `2.71 / 3.63 fF`
- `DFRSHDX1` D/C/SN caps: `2.70 / 3.64 / 8.61 fF`

## Genus Classification Use

When reviewing O13 abs3 timing:

- Large `clk_sys <-> clk_osc_*_buf_tap*` setup paths are still a constraint/CDC issue unless they are explicitly classified as real local paths.
- Real local oscillator paths should remain visible and timed.
- Reset/set recovery and removal paths should be classified separately from setup closure.
- `DFRSHDX1` paths must be interpreted as set-pin behavior, not reset-pin behavior.
- Scan cells remain `dont_use`; do not interpret scan-cell existence as permission to use them.

## Reporting Rule

If a script cannot determine a real cell type or real DB capacitance, it should emit `UNKNOWN` or `ERROR` in the report. The XLIBD file can provide reference pin caps and equivalent-load estimates, but it cannot manufacture measured design load.
