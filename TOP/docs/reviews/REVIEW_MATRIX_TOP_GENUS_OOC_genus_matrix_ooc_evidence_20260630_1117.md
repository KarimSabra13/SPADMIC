# Review: Matrix TOP Genus OOC Evidence Run genus_matrix_ooc_evidence_20260630_1117

## Metadata

- Branch: `SPADMIC_test`
- Snapshot commit reviewed locally: `3603455e`
- Server run ID: `genus_matrix_ooc_evidence_20260630_1117`
- Server run commit: `57c11ac1fc86fd5dd5a84143bfc324e0278416d5`
- Evidence snapshot: `TOP/docs/server_snapshots/genus/genus_matrix_ooc_evidence_20260630_1117/`
- Review status: PASS for Genus OOC feasibility; script evidence issue fixed after review.
- Signoff status: non-signoff, typical-only.

## Result

The run passed all 12 configured Genus OOC targets with `GENUS_RC=0`:

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

The Genus-only matrix-top filelist still correctly excludes:

- `TOP/rtl/spadmic_ddr_tx.sv`
- `TOP/rtl/spadmic_top_v1.sv`

## Timing And QOR Evidence

For `spadmic_top_matrix_v1`:

- `clk_sys`: 6.25 ns
- `clk_cfg_40m`: 25 ns
- `clk_ref_40m`: 25 ns
- `clk_sys` worst slack: 12.4 ps
- total TNS: 0
- violating paths: 0
- leaf instances: 58606
- sequential instances: 26601
- combinational instances: 32005
- total area reported by Genus: 2992326.853

This is useful OOC feasibility evidence only. It is not MMMC, extracted timing,
final PnR timing, CDC/RDC signoff, or DDR/matrix macro timing signoff.

## Verifier Findings

| ID | Severity | Finding | Impact | Builder Response | Status |
| --- | --- | --- | --- | --- | --- |
| GENUS-EVID-001 | NOTE | All 12 OOC targets passed after the legacy DDR8/top filter fix. | Matrix-top RTL path is Genus-elaboratable and synthesizable under XH018 `xx31`/`JIHD` typical-only setup. | No RTL change required. | VERIFIED |
| GENUS-EVID-002 | MEDIUM | `report_messages.rpt` contains `TUI-204` because `report_exceptions` is not a valid command in this Genus environment. | This is a server-script issue, not a design failure, but it pollutes message summaries. | Removed `report_exceptions` from `run_genus_matrix_block.tcl`. | FIXED LOCALLY, NEEDS RERUN |
| GENUS-EVID-003 | MEDIUM | Inter-clock reports for `clk_sys <-> clk_cfg_40m` and `clk_sys <-> clk_ref_40m` show no displayed paths but print the Genus note about hidden unconstrained paths. | The async clock-group intent is still not conveniently auditable from the snapshot. | Added explicit `report_timing -unconstrained` inter-clock reports and generated-SDC clock-group excerpts to the next snapshot flow. | FIXED LOCALLY, NEEDS RERUN |
| GENUS-EVID-004 | MEDIUM | `matrix_cfg_ctrl` and top timing-intent reports show 89 `matrix_cout_i[*]` returned-clock capture pins without clock waveforms. | Expected for the current Cout-edge sampler, but it is not signoff. Final handling needs the matrix macro timing contract. | Keep documented as matrix macro CDC/STA open item. | DEFERRED |
| GENUS-EVID-005 | MEDIUM | Top timing-intent still reports three `spadmic_ref_stop_qualifier` data pins driven by `clk_ref_40m`. | This is the MPTDC stop-qualification boundary and needs final STA/CDC classification. | Do not modify protected MPTDC internals. Keep as review item for integration STA. | DEFERRED |
| GENUS-EVID-006 | LOW | Warning classifier still counted headings such as `Unresolved References & Empty Modules` and `Max_transition design rule: no violations`. | Counts are less noisy than before, but still not clean enough for quick triage. | Refined classifier skip rules and patterns. | FIXED LOCALLY, NEEDS RERUN |
| GENUS-EVID-007 | LOW | `check_design` reports 145 unloaded sequential elements, mostly MPTDC status/debug/RO images and position cluster intermediate outputs. | Not a functional blocker, but needs conscious cleanup or preservation policy before final synthesis. | Document as OOC synthesis review item. | OPEN |

## Protected Boundary Check

No protected MPTDC internal RTL was modified for this review. The observed MPTDC
timing-intent issues remain integration/STA classification items.

## Next Required Evidence

Run one more Genus evidence pass after the script fixes so the snapshot confirms:

- no `TUI-204` invalid command in `report_messages.rpt`;
- unconstrained inter-clock reports are present;
- generated SDC clock-group excerpts are captured;
- warning classification no longer counts non-finding headings as findings.

## Verifier Status

Accepted as a valid Genus OOC feasibility pass. Not accepted as final timing
closure. Builder fixed the evidence-flow issues locally; one more Genus rerun is
needed to capture the cleaned reports.
