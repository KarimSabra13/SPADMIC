# SERVER RUN REQUEST

Status: PAUSED.  Do not run this H4b backend request while the O0
oscillator/PD signoff track is active.  Use
`docs/timing_closure/SERVER_RUN_REQUEST_OSC_PD.md` unless explicitly instructed
to resume H4b.

Run ID:

`20260527_1330_h4b_drain_emit_stage`

Git branch:

`SPADMIC_TOP`

Git commit to run:

Use the exact SHA provided in the assistant final response for the H4b patch.
This request file is committed with the patch it describes, so the self-hash
cannot be embedded in this file without changing the hash.

Purpose:

Validate H4b: add a registered drain emit stage so META/HIT record construction
does not feed directly into the FIFO pending-record register. Genus must show
whether the current
`ns_cnt_q/drain_ctx_q -> u_core_u_drain_ctrl_pending_wr_data_q` `clk_sys` setup
cone is removed or materially improved. Xcelium must validate the added readout
latency under backpressure and selected VIP traffic.

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
  the H4b patch.
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

bash MPTDC/syn/scripts/server_run_genus_mptdc.sh 20260527_1330_h4b_drain_emit_stage_genus
bash MPTDC/sim/xcelium/server_run_xcelium_mptdc.sh 20260527_1330_h4b_drain_emit_stage_xcelium
```

Expected output directories:

```text
results/genus/20260527_1330_h4b_drain_emit_stage_genus/
MPTDC/lab_snapshots/genus_20260527_1330_h4b_drain_emit_stage_genus/
results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/
MPTDC/results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/
```

Expected key Genus files:

- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/SUMMARY.md`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/PARSED_SUMMARY.md`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/timing_summary.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/timing_clk_sys_violations.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/timing_drain_ctrl_hotspots.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/timing_fifo_hotspots.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/report_design_rules.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/report_high_fanout.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/check_timing_intent.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/latch_audit.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/cdc_manual_audit.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/report_clocks.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/report_constraints.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/report_qor.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/report_area.rpt`
- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/genus_20260527_1330_h4b_drain_emit_stage_genus.log`

Expected key Xcelium files:

- `results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/SUMMARY.md`
- `results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/run_manifest.txt`
- `results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/test_summary.txt`
- `results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/xcelium_20260527_1330_h4b_drain_emit_stage_xcelium.log`
- `results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/directed/`
- `results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/vip/`
- `results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/failures/`
- `MPTDC/results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/vip/`

Files to commit/push after run:

- `results/genus/20260527_1330_h4b_drain_emit_stage_genus/`
- `MPTDC/lab_snapshots/genus_20260527_1330_h4b_drain_emit_stage_genus/`
- `results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/`
- `MPTDC/results/xcelium/20260527_1330_h4b_drain_emit_stage_xcelium/`

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
server-results: 20260527_1330_h4b_drain_emit_stage Genus Xcelium
```

What this run decides:

- Whether H4b removes or materially improves the
  `ns_cnt_q/drain_ctx_q -> pending_wr_data_q` real `clk_sys` setup cone.
- Whether the added drain readout latency preserves directed and VIP functional
  behavior.
- Whether to keep H4b and request Innovus, or continue with the next remaining
  clk_sys cone.
