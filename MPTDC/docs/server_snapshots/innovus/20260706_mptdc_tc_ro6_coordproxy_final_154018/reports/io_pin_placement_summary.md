# O10.2 IO Pin Placement Summary

REPORT_STATUS=OK

- Enabled: `1`
- Layer: `MET3`
- Spacing um: `2.0`
- Total ports: `57`
- West ports: `4`
- East ports: `31`
- North ports: `21`
- South ports: `1`

| Side | Status | Notes |
|---|---:|---|
| WEST | OK | `editPin sized fixed LEFT MET3` |
| EAST | OK | `editPin sized fixed RIGHT MET3` |
| NORTH | OK | `editPin sized fixed TOP MET3` |
| SOUTH | OK | `editPin sized fixed BOTTOM MET3` |

North side carries the product 16-bit packet output bus and packet framing/status stream pins.
West side is reserved for SPAD and calibration asynchronous detector inputs.
East side carries clk_sys, packet ready, mode/control, max_hits, and minimal status pins.
South side carries async reset when present. VDD/VSS are special power nets handled by the power-grid plan, not ordinary signal IO ports.
