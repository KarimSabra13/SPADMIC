# Review: Matrix TOP Genus OOC staged run

- Branch: `SPADMIC_test`
- Source commit reviewed: `195b6d1bf87c16042294c8e3d411b50d989f541a`
- Snapshot commit observed locally: `c72e620b7e33fa04adbe806168e224473bb77974`
- Run ID: `genus_matrix_ooc_staged_20260630_1516`
- Run directory: `/sim/ksabra/SPADMIC_work/genus/genus_matrix_ooc_staged_20260630_1516`
- Snapshot: `TOP/docs/server_snapshots/genus/genus_matrix_ooc_staged_20260630_1516/`
- Tool: Genus 22.13, XH018 `xx31`, JIHD, `MET1 MET2 MET3 METTP`
- Signoff status: non-signoff, typical-only OOC feasibility

## Files Reviewed

- `SUMMARY.md`
- per-block `reports/elaboration/check_design_post_elab.rpt`
- per-block `reports/messages/warning_classification.rpt`
- per-block `reports/qor/report_area.rpt`
- per-block timing reports captured in the snapshot

## Result

All 12 configured OOC blocks passed the wrapper:

| Block | Result | Total area mm2 |
| --- | --- | ---: |
| `or64_tree` | PASS | 0.000969 |
| `i2c_csr_bridge` | PASS | 0.004031 |
| `ddr16_pairer` | PASS | 0.005686 |
| `event_bundle_tx` | PASS | 0.006278 |
| `event_coordinator` | PASS | 0.007430 |
| `i2c_slave` | PASS | 0.020246 |
| `matrix_reset_ctrl` | PASS | 0.027971 |
| `matrix_top_csr` | PASS | 0.052758 |
| `matrix_cfg_ctrl` | PASS | 0.105054 |
| `position_snapshot` | PASS | 0.287770 |
| `output_fifo` | PASS | 0.862053 |
| `spadmic_top_matrix_v1` | PASS | 2.992327 |

The full-top number still includes synthesized MPTDC internals in this feasibility run. It must not be used as final TOP-owned area after the MPTDC physical block handoff arrives.

## Findings

| Severity | Finding | Status |
| --- | --- | --- |
| NOTE | `spadmic_ddr_tx.sv` and `spadmic_top_v1.sv` were excluded from the Genus TOP filelist as intended. This protects the obsolete DDR8 RTL and old top path from blocking matrix-top OOC feasibility. | FIXED |
| MEDIUM | `matrix_cfg_ctrl` and `spadmic_top_matrix_v1` still report `no_clock_waveform count=89` in the curated warning report. These are tied to asynchronous or intentionally separated domains and must stay visible for CDC/STA planning. | OPEN |
| LOW | The warning classifier counted `Multidriven Port(s)/Pin(s)` section headings as undriven/multidriven findings even when the detailed report says no such issue. | FIXED |
| NOTE | Missing external delay warnings remain expected in OOC feasibility because pad and macro timing contracts are not final. | DEFERRED |

## Verifier Conclusion

Verifier accepts this run as OOC feasibility evidence only. It does not prove final timing closure, MMMC, CDC/RDC signoff, Innovus readiness, or matrix/MPTDC macro timing.
