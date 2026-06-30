# SPADMIC Matrix TOP Genus OOC Plan

Status: typical-only synthesis feasibility plan. No Genus run has been performed locally.

## Metadata

- Branch: `SPADMIC_test`
- Baseline commit for this plan: `5cdf489fbfb0a13e1a5ee7f5a253002e023602ac`
- Server repo path: `/home/validmgr/ksabra/2026_SPAD/SPADMIC`
- Cadence environment: `source /eda/cadence/eda_2023-2024`
- Work root: `/sim/ksabra/SPADMIC_work`
- Genus output root: `/sim/ksabra/SPADMIC_work/genus/<RUN_ID>/<BLOCK>/`
- Signoff status: non-signoff, typical-only feasibility.

## Required Technology Alignment

The matrix-top Genus OOC flow must match the current mature MPTDC physical
baseline unless a separate reviewed technology migration is opened:

- XFAB process: `xh018`, 180 nm.
- XH018 stack: `xx31` / `XH018_1131_1P3M_MET3_METMID`.
- Technology LEF family: `xh018_xx31_HD_MET3_METMID.lef`.
- Standard-cell family: `D_CELLS_JIHD`.
- Route layer list: `MET1 MET2 MET3 METTP`.
- Ordinary signal top layer: `MET3`.
- Effective top floor / PG / reviewed exception layer: `METTP`.

`TOP/syn/scripts/run_genus_all_matrix_ooc.sh` sets these defaults before
launching Genus. `TOP/syn/scripts/run_genus_matrix_block.tcl` checks the sourced
MPTDC library state and fails early if the stack or standard-cell family drifts
away from `xx31/JIHD`.

## Block List And Order

1. Snapshot-driven position wrapper/path.
2. Output FIFO plus bundle path.
3. OR64 three-axis wrapper.
4. Matrix reset controller.
5. Matrix configuration controller plus Cout sampler.
6. DDR16 pairer.
7. Event coordinator.
8. Matrix-top CSR.
9. I2C/CSR bridge feasibility.
10. `spadmic_top_matrix_v1` feasibility with intended black boxes/collateral documented.

For MPTDC, use existing MPTDC axis-core flow/results as source of truth. Do not synthesize three unique MPTDC variants unless a later handoff requires it.

## Constraints

Minimum intended constraints:

- `clk_sys`: 6.25 ns.
- `clk_cfg_40m`: 25 ns.
- `clk_ref_40m`: 25 ns where STOP qualifier logic is included.
- Treat `clk_sys` and `clk_cfg_40m` as distinct domains unless the final PLL/STA constraints prove a synchronous relationship.
- Mark ASYNC_REG synchronizers for preservation.
- Classify matrix R/Y/B START paths separately from synchronized snapshot paths.
- Preserve OR64 hierarchy sufficiently for path and skew reporting.
- Avoid broad false paths that hide useful START-tree or reset-output timing.

## Reports Per Block

Each block run should produce:

```text
logs/
reports/elaboration/check_design_post_elab.rpt
reports/timing/check_timing_intent.rpt
reports/timing/report_clocks.rpt
reports/timing/report_timing_pre_synth.rpt
reports/timing/report_timing_post_generic.rpt
reports/timing/report_timing_post_map.rpt
reports/timing/report_timing_post_opt.rpt
reports/qor/report_qor.rpt
reports/qor/report_area.rpt
reports/qor/report_area_hierarchy.rpt
reports/qor/report_design_rules.rpt
reports/messages/report_messages.rpt
outputs/<block>.postsyn.v
outputs/<block>.postsyn.sdc
outputs/<block>.postsyn.sdf if available
SUMMARY.md
```

Do not generate final netlists if elaboration or `check_design` fails.

## Warning Classification

The Genus wrapper must classify at least:

- unresolved modules;
- inferred latches;
- unconstrained clocks;
- no paths for required clocks;
- all paths false-pathed;
- CDC synchronizer preservation problems;
- black boxes intentionally used versus accidental black boxes;
- max transition, max fanout, and max capacitance warnings;
- undriven or multiply-driven signals.

## Server Command

The wrapper script `TOP/syn/scripts/run_genus_all_matrix_ooc.sh` is now present.
After review, the intended server command is:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test
source /eda/cadence/eda_2023-2024
export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_XH018_STACK=xx31
export MPTDC_STDCELL_FAMILY=JIHD
bash TOP/syn/scripts/run_genus_all_matrix_ooc.sh "$RUN_ID"
```

The script writes all generated files under
`/sim/ksabra/SPADMIC_work/genus/<RUN_ID>/<BLOCK>/` and fails clearly if Genus is
not available in `PATH`.

## Matrix-Top Genus Filelist

`TOP/filelist.f` remains the shared simulation and legacy-top filelist. The
Genus wrapper resolves it to `filelists/top_abs.raw.f`, then creates a
matrix-top synthesis filelist at `filelists/top_abs.f`.

The Genus-only filelist excludes:

- `TOP/rtl/spadmic_ddr_tx.sv`, the obsolete 8-bit dual-edge DDR RTL;
- `TOP/rtl/spadmic_top_v1.sv`, the legacy top that instantiates that DDR8 path.

This filtering does not alter Xcelium/Verilator inputs. It only prevents unused
legacy RTL from blocking `spadmic_top_matrix_v1` OOC synthesis. The matrix-top
output path uses `spadmic_ddr16_tx_pairer` and the future DDR16 macro boundary.

After the run, create a small tracked evidence snapshot for review:

```bash
TOP/ci/collect_matrix_top_server_snapshot.sh genus "$RUN_ID"
git add TOP/docs/server_snapshots/genus/"$RUN_ID"
git commit -m "docs: add matrix top Genus snapshot $RUN_ID"
git push origin SPADMIC_test
```

Do not commit raw Genus databases, full logs, netlists, SDF/SPEF, or tarballs.

## Limitations

This plan does not claim:

- full chip timing closure;
- MMMC closure;
- extracted timing;
- final MPTDC physical integration closure;
- final matrix macro timing;
- final DDR macro timing;
- DRC/LVS/PEX;
- tapeout readiness.
