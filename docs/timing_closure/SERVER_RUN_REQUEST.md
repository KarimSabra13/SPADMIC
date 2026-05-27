# SERVER RUN REQUEST

Run ID:

`20260527_1200_h1b_count_eval_split`

Git branch:

`SPADMIC_TOP`

Git commit to run:

Use the exact SHA provided in the assistant final response for the H1b patch.
This request file is committed with the patch it describes, so the self-hash
cannot be embedded in this file without changing the hash.

Purpose:

Validate H1b: split final hit-total registration from hit-count/flag
publication in `mptdc_meas_ctrl`. Genus must show whether the remaining
`row_cnt_q -> meas_ctrl_hit_count_q/flags_q` `clk_sys` setup path is removed or
materially improved. Xcelium must validate the additional backend `clk_sys`
latency stage.

Required tool(s):

- [x] Genus
- [ ] Innovus
- [x] Xcelium

Before running:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git status --short
git rev-parse HEAD
git log --oneline -5
```

Expected clean condition:

- `HEAD` must equal the exact SHA provided in the assistant final response for
  the H1b patch.
- Working tree should be clean, except allowed local server environment files.

Commands:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_TOP
git pull --ff-only
EXPECTED_HEAD=<SHA_FROM_ASSISTANT_FINAL_RESPONSE>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"
git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_mptdc.sh 20260527_1200_h1b_count_eval_split_genus
bash MPTDC/sim/xcelium/server_run_xcelium_mptdc.sh 20260527_1200_h1b_count_eval_split_xcelium
```

Expected output directories:

```text
results/genus/20260527_1200_h1b_count_eval_split_genus/
MPTDC/lab_snapshots/genus_20260527_1200_h1b_count_eval_split_genus/
results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/
MPTDC/results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/
```

Expected key Genus files:

- `results/genus/20260527_1200_h1b_count_eval_split_genus/SUMMARY.md`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/PARSED_SUMMARY.md`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/timing_summary.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/timing_clk_sys_violations.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/timing_context_bank_hotspots.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/timing_drain_ctrl_hotspots.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/report_design_rules.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/check_timing_intent.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/latch_audit.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/cdc_manual_audit.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/report_clocks.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/report_constraints.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/report_qor.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/report_area.rpt`
- `results/genus/20260527_1200_h1b_count_eval_split_genus/genus_20260527_1200_h1b_count_eval_split_genus.log`

Expected key Xcelium files:

- `results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/SUMMARY.md`
- `results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/run_manifest.txt`
- `results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/test_summary.txt`
- `results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/xcelium_20260527_1200_h1b_count_eval_split_xcelium.log`
- `results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/directed/`
- `results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/vip/`
- `results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/failures/`
- `MPTDC/results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/vip/`

Files to commit/push after run:

- `results/genus/20260527_1200_h1b_count_eval_split_genus/`
- `MPTDC/lab_snapshots/genus_20260527_1200_h1b_count_eval_split_genus/`
- `results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/`
- `MPTDC/results/xcelium/20260527_1200_h1b_count_eval_split_xcelium/`

If either run fails, still commit/push:

- main tool log
- `SUMMARY.md`
- `run_manifest.txt` if present
- partial reports if created
- `test_summary.txt` if present
- `failures/` tails and failed waveforms if compact
- tool version/banner lines from logs, if available

Post-run commit message suggestion:

```text
server-results: 20260527_1200_h1b_count_eval_split Genus Xcelium
```

What this run decides:

- Whether H1b removes or materially improves the remaining
  `row_cnt_q -> meas_ctrl_hit_count_q/flags_q` real `clk_sys` setup paths.
- Whether the added backend latency preserves directed and VIP functional
  behavior.
- Whether to keep H1b and move to the next separate hypothesis, likely H4b
  drain/context read prefetch.
