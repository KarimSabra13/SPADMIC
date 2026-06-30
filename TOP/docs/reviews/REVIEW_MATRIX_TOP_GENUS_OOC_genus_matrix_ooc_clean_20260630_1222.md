# Review: Matrix TOP Genus OOC Clean Run genus_matrix_ooc_clean_20260630_1222

## Metadata

- Branch: `SPADMIC_test`
- Snapshot commit reviewed locally: `94c8b014`
- Server run ID: `genus_matrix_ooc_clean_20260630_1222`
- Server run commit from `run_manifest.txt`: `50e488e7044f9a991c0605601bd1f1f1110d4760`
- Evidence snapshot: `TOP/docs/server_snapshots/genus/genus_matrix_ooc_clean_20260630_1222/`
- Review status: PASS for Genus OOC feasibility; evidence-flow cleanup required.
- Signoff status: non-signoff, typical-only.

## Result Reviewed

The run completed all 12 configured Genus OOC targets with `GENUS_RC=0`:

- `position_snapshot`
- `output_fifo`
- `event_bundle_tx`
- `or64_tree`
- `matrix_reset_ctrl`
- `matrix_cfg_ctrl`
- `ddr16_pairer`
- `event_coordinator`
- `matrix_top_csr`
- `i2c_csr_bridge`
- `i2c_slave`
- `spadmic_top_matrix_v1`

The Genus-only filelist still excludes the obsolete/protected paths required by
the matrix-top flow:

- `TOP/rtl/spadmic_ddr_tx.sv`
- `TOP/rtl/spadmic_top_v1.sv`

## Top-Level Evidence

For `spadmic_top_matrix_v1`:

- `clk_sys`: 6.25 ns
- `clk_cfg_40m`: 25 ns
- `clk_ref_40m`: 25 ns
- worst `clk_sys` path slack: 12.4 ps
- total TNS: 0
- violating paths: 0
- leaf instances: 58606
- sequential instances: 26601
- combinational instances: 32005
- total area reported by Genus: 2992326.853

The generated SDC excerpt contains the intended asynchronous clock grouping for
`clk_sys`, `clk_cfg_40m`, and `clk_ref_40m`. The unconstrained inter-clock
reports are present and expose the expected CDC/returned-clock paths for review.
This is useful evidence, not CDC/RDC signoff.

## Verifier Findings

| ID | Severity | Finding | Impact | Builder Response | Status |
| --- | --- | --- | --- | --- | --- |
| GENUS-CLEAN-001 | NOTE | All 12 OOC targets passed with the XH018 `xx31`/`JIHD` stack. | Matrix-top RTL remains synthesizable in the server Genus environment. | No RTL change required. | VERIFIED |
| GENUS-CLEAN-002 | MEDIUM | `report_messages.rpt` for every block still contains `TUI-204`. The raw filtered message tail shows it near the report/output-collateral stage. | The design pass is still valid, but the evidence flow is not clean enough to use as a polished Genus baseline. | Replaced unsupported `report_area -hierarchical` with a Genus-22.13-compatible `report_area` capture under `report_area_hierarchy.rpt`. Moved `report_messages` after output writes so output-stage problems are captured. | FIXED LOCALLY, NEEDS SERVER RERUN |
| GENUS-CLEAN-003 | LOW | The warning classifier counts `No undriven ...` check-design lines as undriven findings. | This is a false positive and makes triage noisy. | Added skip rules for negative `No ... undriven/unconnected/multiply driven` lines. | FIXED LOCALLY, NEEDS SERVER RERUN |
| GENUS-CLEAN-004 | LOW | The snapshot README labels the commit at collection time as `Repository commit`, while the actual run commit is in `run_manifest.txt`. | This can confuse run provenance after a rebase or late collection. | Updated the collector to print separate source-run and snapshot-collection branch/commit fields. | FIXED LOCALLY, NEEDS SERVER RERUN |
| GENUS-CLEAN-005 | MEDIUM | `matrix_cfg_ctrl` and top still show 89 unclocked returned-Cout capture pins. | Expected for current Cout/Dout returned-edge placeholder; not signoff without matrix macro timing. | Keep as non-signoff CDC/STA item. | DEFERRED |
| GENUS-CLEAN-006 | MEDIUM | Top unconstrained reports expose protected MPTDC `clk_ref_40m` to `clk_sys` paths. | This needs final CDC/STA classification but must not be fixed by editing protected MPTDC internals here. | Preserve as protected-boundary timing item. | DEFERRED |

## Protected Boundary Check

No protected MPTDC internal RTL changes are required by this review. The fixes
are limited to TOP-owned Genus evidence scripts and snapshot collection.

## Verifier Status

Accepted as a Genus OOC feasibility pass. Not accepted as the final clean Genus
evidence baseline until one more server rerun shows:

- no `TUI-204` in `report_messages.rpt`;
- `tool_error count=0`;
- no false-positive `undriven` classification from `No undriven ...` lines;
- `report_area_hierarchy.rpt` present in the snapshot;
- source-run commit and snapshot-collection commit clearly separated.
