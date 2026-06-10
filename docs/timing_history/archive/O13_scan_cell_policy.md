# O13 Scan Cell Policy

Status: `NO_SCAN_FOR_NORMAL_SYNTHESIS`

The XLIBD extraction includes scan flops:

- `SDFFQHDX2`
- `SDFFQHDX4`

Both are marked `dont_use=true`.

Current SPADMIC O13 timing/PNR closure is not a DFT scan insertion flow.

## Policy

- Do not use scan cells for normal synthesis.
- Do not change synthesis constraints to enable scan cells for O13.
- Do not enable scan-cell replacement in normal synthesis.
- Use scan cells only if a deliberate DFT/scan strategy is introduced later.
- If scan is introduced later, review scan enable tie-off, scan data loading, CN clock load, recovery/removal behavior, and ATPG/DFT intent before enabling these cells.

## Reference Values

| Cell | dont_use | CN cap fF | D cap fF | SD cap fF | SE cap fF |
|---|---|---:|---:|---:|---:|
| `SDFFQHDX2` | true | 3.80 | 3.33 | 2.98 | 5.89 |
| `SDFFQHDX4` | true | 3.80 | 3.33 | 2.99 | 5.89 |

The scan enable input is relatively heavy at `5.89 fF`; do not introduce scan behavior accidentally.
