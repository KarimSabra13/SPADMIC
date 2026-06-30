# Review: Matrix TOP Genus OOC Rerun genus_matrix_ooc_rerun_20260630_1009

## Metadata

- Branch: `SPADMIC_test`
- Snapshot commit reviewed locally: `d6f30ddb`
- Server run ID: `genus_matrix_ooc_rerun_20260630_1009`
- Server run commit: `c306e947a86c5d1a545bf043b0a8ddd54096a51d`
- Evidence snapshot: `TOP/docs/server_snapshots/genus/genus_matrix_ooc_rerun_20260630_1009/`
- Review status: PASS for OOC feasibility; not final timing closure.
- Signoff status: non-signoff, typical-only.

## Result Reviewed

The rerun passed all 12 configured Genus OOC targets:

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

The Genus-only filelist correctly excluded:

- `TOP/rtl/spadmic_ddr_tx.sv`
- `TOP/rtl/spadmic_top_v1.sv`

This confirms the previous DDR8/legacy-top input-selection blocker is fixed for
the matrix-top OOC flow.

## Key Evidence

- Stack: XH018 `xx31`
- Standard-cell family: `JIHD`
- Route layers: `MET1 MET2 MET3 METTP`
- Ordinary signal top layer: `MET3`
- Effective top/floor layer: `METTP`
- Top run QOR:
  - `clk_sys` period: 6.25 ns
  - `clk_cfg_40m` period: 25 ns
  - `clk_ref_40m` period: 25 ns
  - top `clk_sys` slack: 12.4 ps
  - total TNS: 0
  - violating paths: 0
  - leaf instances: 58606
  - sequential instances: 26601
  - combinational instances: 32005

## Verifier Findings

| ID | Severity | Finding | Impact | Builder Response | Status |
| --- | --- | --- | --- | --- | --- |
| GENUS-RERUN-001 | NOTE | All OOC blocks passed after filtering obsolete DDR8 and the legacy top from the Genus input filelist. | Confirms matrix-top path can elaborate/synthesize in Genus with the aligned XH018/JIHD stack. | No RTL change required. | VERIFIED |
| GENUS-RERUN-002 | MEDIUM | `report_clocks.rpt` still prints apparent clock relationships among `clk_sys`, `clk_cfg_40m`, and `clk_ref_40m`. The source SDC intended asynchronous clock groups, but the snapshot did not include targeted inter-clock `report_timing` evidence to prove those paths are cut. | Risk of overclaiming CDC/STA state. `clk_cfg_40m` must remain a distinct domain until final PLL/STA constraints prove a safe synchronous relationship. | Strengthened the OOC SDC to emit one complete async clock-group declaration when all clocks exist. Added targeted `report_timing` reports for `clk_sys <-> clk_cfg_40m` and `clk_sys <-> clk_ref_40m` to the Genus runner. | FIXED LOCALLY, NEEDS SERVER RERUN |
| GENUS-RERUN-003 | MEDIUM | `matrix_cfg_ctrl` timing intent reports unclocked `matrix_cout_i[*]` capture clock pins. | This is expected from the returned-Cout readback architecture, but it is not signoff. Cout/Dout timing must be resolved with the matrix macro handoff. | Kept as an explicit non-signoff macro timing item. Future Genus snapshots now collect more timing/message evidence. | DEFERRED TO MATRIX TIMING CONTRACT |
| GENUS-RERUN-004 | MEDIUM | Top timing intent reports `spadmic_ref_stop_qualifier` data pins driven by a clock signal. | This is the MPTDC stop-qualification boundary behavior and must be classified before final STA. It is not a new matrix-top RTL regression. | Documented as protected-boundary timing-intent review item. Do not edit MPTDC internals. | DEFERRED TO CDC/STA REVIEW |
| GENUS-RERUN-005 | LOW | `warning_classification.rpt` is noisy: it counts script echoes and library variable names as blackbox/unresolved/undriven hits. | Makes review slower and can hide real warnings. | Refined `classify_reports` to scan curated report files only and exclude raw script/library echoes. | FIXED LOCALLY, NEEDS SERVER RERUN |
| GENUS-RERUN-006 | LOW | The committed snapshot does not include `report_messages.rpt`, post-opt timing excerpts, or filtered Genus message tails. | Limits local review fidelity after server runs. | Updated the snapshot collector to include curated message/timing/design-rule excerpts and filtered message tails. | FIXED LOCALLY, NEEDS SERVER RERUN |

## Builder Fixes After Review

- `TOP/syn/constraints/matrix_top_ooc_common.sdc`
  - Clarified async clock-group declaration for `clk_sys`, `clk_cfg_40m`, and
    `clk_ref_40m`.
- `TOP/syn/scripts/run_genus_matrix_block.tcl`
  - Added targeted inter-clock timing reports.
  - Added `report_exceptions`.
  - Refined warning classification scope.
- `TOP/ci/collect_matrix_top_server_snapshot.sh`
  - Added curated `report_messages`, design-rule, post-opt timing, inter-clock
    timing, and filtered Genus-message snapshot capture.

## Remaining Limitations

- This is not MMMC closure.
- This is not extracted timing.
- This is not CDC/RDC signoff.
- `matrix_cout_i[*]` returned-clock/readback timing remains macro-contract
  dependent.
- `clk_ref_40m` and MPTDC internal clocking remain protected MPTDC-boundary
  timing items.
- DDR16 macro timing is still provisional.

## Verifier Status

The rerun is accepted as a successful Genus OOC feasibility pass. The Builder
fixes above are required before the next Genus rerun so the next snapshot gives
better evidence for clock grouping, warning classification, and timing review.
