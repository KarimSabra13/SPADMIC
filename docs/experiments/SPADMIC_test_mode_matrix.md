# SPADMIC_test Mode Matrix

| Mode | Defines | RTL changes | Expected gain | Risk | Default |
| --- | --- | --- | --- | --- | --- |
| `BASELINE` | none | No experimental RTL enabled | None | Reference only | No |
| `SAFE_TEARDOWN` | `MPTDC_SAFE_TEARDOWN` | START teardown block and ready hardening | Safety only | Low | No |
| `ROW_SKIP` | `MPTDC_SAFE_TEARDOWN`, `MPTDC_DRAIN_ROW_SKIP` | Snapshot row metadata and empty-row drain skip | Large for sparse rows | Low | No |
| `STRIDE2` | `MPTDC_SAFE_TEARDOWN`, `MPTDC_DRAIN_ROW_SKIP`, `MPTDC_DRAIN_SCAN_STRIDE2` | Two-cell scan with pending second adjacent hit | Moderate to large | Medium | Yes |
| `CLEAR_EARLY` | `STRIDE2` defines plus `MPTDC_PD_CLEAR_EARLY` | PD clear starts in CAPTURE and remains in CLEAR | Small | Medium | No |
| `CAPTURE_CLEAR_EXPERIMENTAL` | Not enabled by scripts | Planned only | 1 cycle | Medium/high | No |

Script selection:

`MPTDC_OPT_MODE=STRIDE2`

or:

`--mptdc-opt-mode STRIDE2`

Unsupported modes fail closed.
