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
bash TOP/syn/scripts/run_genus_all_matrix_ooc.sh "$RUN_ID"
```

The script writes all generated files under
`/sim/ksabra/SPADMIC_work/genus/<RUN_ID>/<BLOCK>/` and fails clearly if Genus is
not available in `PATH`.

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
