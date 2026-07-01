# Review: Matrix TOP Full-Boundary Staged Planning Patch

Date: 2026-07-02
Branch: `SPADMIC_test`
Reviewed baseline: `52331ae3f7e5fad0982575d4b41a37d3c6d66469`

## Scope

This review covers the staged matrix-top planning patch that:

- promotes the MPTDC planning envelope from the old 1.0 mm2 placeholder to the full DEF/block boundary `1061.20 um x 801.92 um`;
- adds 5 percent dimensional margin plus a provisional 20 um halo around each MPTDC;
- uses the known custom TOP die envelope `4293.179 um x 3209.173 um` and 164 um pad-ring/core planning depth;
- documents the one-external-160-MHz clock policy and internal 40 MHz logical clocks;
- reduces the implemented output FIFO depth to 256 entries while preserving the 129-entry event reservation;
- excludes `ddr16_pairer` and full `spadmic_top_matrix_v1` from default Genus OOC runs.

## Findings

No blocking implementation issues were found in the reviewed patch.

The new gated floorplan scenario is `B_FULL_BOUNDARY_MARGIN_HALO`, not the old optimistic placeholder. Local generation reports:

- `STATUS=PASS`
- MPTDC planning envelope per axis: `1154.260 um x 882.016 um`
- MPTDC planning area per axis: `1.018076 mm2`
- maximum required-style per-axis planning area that fits: `1.173762 mm2`
- die area: `13.778 mm2`
- matrix area: `3.450925 mm2`

The wrapper correctly reaches a passing geometry plan locally and then stops only because `innovus` is not installed in the local PATH. That is an environment limitation, not a geometry failure.

## Protected File Check

The modified file list is confined to TOP RTL/package, TOP docs, TOP PnR scripts/inputs, TOP CI collection, and TOP Genus wrappers.

No protected MPTDC RTL internals were modified. The legacy `TOP/rtl/spadmic_top_v1.sv` file was not modified.

Untracked protected/reference files remain untracked and were not staged:

- `ParameterDefs.sv`
- `multi_ShiftRegisterChain_cfg_v1.sv`
- `pixel_readout.pdf`
- `MPTDC/pnr/scripts/innovus_mptdc_pg_dangling_checkpoint_tools.tcl`

## Verification

Local checks run:

| Command | Result |
| --- | --- |
| `git diff --check` | PASS |
| `python3 -m py_compile TOP/pnr/scripts/gen_matrix_top_floorplan_plan.py` | PASS |
| `bash -n TOP/syn/scripts/run_genus_all_matrix_ooc.sh` | PASS |
| `bash -n TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh` | PASS |
| `bash -n TOP/pnr/scripts/server_run_innovus_matrix_ooc.sh` | PASS |
| `bash -n TOP/ci/collect_matrix_top_server_snapshot.sh` | PASS |
| `python3 TOP/pnr/scripts/gen_matrix_top_floorplan_plan.py --out /tmp/spadmic_full_boundary_plan_check --run-id local_full_boundary_check` | PASS, Scenario B feasible |
| `SPADMIC_WORK_ROOT=/tmp/spadmic_wrapper_check bash TOP/pnr/scripts/server_run_innovus_matrix_top_staged_floorplan.sh local_wrapper_full_boundary_check_2` | Expected local FAIL: `innovus not found in PATH`; plan status before Innovus was PASS |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_output_fifo_unit --sim verilator` | PASS, 17 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_output_fifo_ddr_marker_unit --sim verilator` | PASS, 17 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_output_fifo_pressure_integration_unit --sim verilator` | PASS, 20 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_unit --sim verilator` | PASS, 190 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_matrix_top_csr_16b_unit --sim verilator` | PASS, 190 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_output_pressure_unit --sim verilator` | PASS, 6 pass / 0 fail |
| `bash TOP/scripts/sim/run_tb.sh tb_spadmic_top_matrix_v1_shell_unit --sim verilator` | PASS, 32 pass / 0 fail |

## Limitations

This review does not prove final timing, MMMC, CTS, route, PG, DRC, LVS, PEX, or signoff.

The MPTDC physical boundary is still treated as a provisional macro planning envelope for TOP. Final import must be rechecked when the MPTDC team provides the final abstract/LEF/DEF and orientation constraints.

The one-external-160-MHz clock policy is documented for planning, but the final clock pad type, PLL abstract, clock mux implementation, generated-clock STA constraints, and CDC/RDC closure still require separate review.

The reduced 256-entry FIFO passed focused local Verilator coverage. It still needs a fresh server Xcelium matrix-top regression snapshot and Genus OOC evidence after this patch is pushed.
