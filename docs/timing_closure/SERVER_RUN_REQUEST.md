# SERVER RUN REQUEST

Run ID:

`20260527_1115_h1_drain_pipeline_xcelium_retry`

Git branch:

`SPADMIC_TOP`

Git commit to run:

Use the exact SHA provided in the assistant final response for this wrapper fix.
This request file is committed with the patch it describes, so the self-hash
cannot be embedded in this file without changing the hash.

Purpose:

Rerun Xcelium VIP after fixing the server wrapper artifact directory. The prior
Xcelium directed tests passed, but the VIP manager rejected the top-level
`results/xcelium/.../vip/cov_work` path before exercising RTL.

Required tool(s):

- [ ] Genus
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
  this wrapper fix.
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

bash MPTDC/sim/xcelium/server_run_xcelium_mptdc.sh 20260527_1115_h1_drain_pipeline_xcelium_retry
```

Expected output directories:

```text
results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/
MPTDC/results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/
```

Expected key files:

- `results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/SUMMARY.md`
- `results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/run_manifest.txt`
- `results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/test_summary.txt`
- `results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/xcelium_20260527_1115_h1_drain_pipeline_xcelium_retry.log`
- `results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/directed/`
- `results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/vip/`
- `results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/failures/`
- `MPTDC/results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/vip/`

Files to commit/push after run:

- `results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/`
- `MPTDC/results/xcelium/20260527_1115_h1_drain_pipeline_xcelium_retry/`

If the run fails, still commit/push:

- the main Xcelium log
- `run_manifest.txt`
- `SUMMARY.md`
- `test_summary.txt` if present
- any `failures/` tails
- VIP `jobs.txt`, `vip_manifest.jsonl`, `vip_summary.json`, and logs if present
- the tool version/banner lines from logs, if available

Post-run commit message suggestion:

```text
server-results: 20260527_1115_h1_drain_pipeline_xcelium_retry
```

No Genus rerun is needed for this request because the patch changes only the
server Xcelium wrapper and timing-analysis docs, not RTL or constraints.
