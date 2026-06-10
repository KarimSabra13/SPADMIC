# O12C Buffer Cell Cap Audit

REPORT_STATUS=REVIEW_REQUIRED

Before trying `BUHDX8` or `BUHDX12` as a first-stage phase buffer, audit the input capacitance of the candidate cells in the actual XH018 Liberty used by the Innovus run.

Budgets:

- Strict RO D-input budget: `58.72 fF`.
- CN/clock-like budget: `75.59 fF`.

Tool:

```bash
python3 tools/pdk/audit_buffer_input_caps.py \
  /data/pdk/xfab/xh018/diglibs/D_CELLS_HD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib \
  --output results/innovus/20260608_o12c_phase_buffer_topology_abs1/reports/buffer_input_cap_audit.md
```

CSV form:

```bash
python3 tools/pdk/audit_buffer_input_caps.py \
  /data/pdk/xfab/xh018/diglibs/D_CELLS_HD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_HD_LPMOS_typ_1_80V_25C.lib \
  --csv \
  --output results/innovus/20260608_o12c_phase_buffer_topology_abs1/reports/buffer_input_cap_audit.csv
```

## Server Result

The O12C abs1 server audit produced:

| Cell | Pin | Cap pF | Cap fF | Strict Ratio | CN Ratio | Status |
|---|---|---:|---:|---:|---:|---|
| BUHDX4 | A | 0.01056 | 10.56 | 0.18 | 0.14 | OK_STRICT |
| BUHDX6 | A | 0.01623 | 16.23 | 0.28 | 0.21 | OK_STRICT |
| BUHDX8 | A | 0.02170 | 21.70 | 0.37 | 0.29 | OK_STRICT |
| BUHDX12 | A | 0.03224 | 32.24 | 0.55 | 0.43 | OK_STRICT |

All audited single-stage candidates stay below the strict `58.72 fF` RO input budget.  This means `BUHDX8` and `BUHDX12` are valid first-stage candidates from the input-cap point of view.  They still need transition, delay, mismatch, and power review before adoption.

Candidate decision:

- If `BUHDX8` input cap is within `58.72 fF`, it is a reasonable stronger single-stage candidate.
- If `BUHDX8` is above `58.72 fF` but below `75.59 fF`, use only with analog approval.
- If `BUHDX8` or `BUHDX12` exceeds the chosen analog budget, do not place it directly on `RO_tune4/S[n]`; use a two-stage topology if stronger drive is still needed.
