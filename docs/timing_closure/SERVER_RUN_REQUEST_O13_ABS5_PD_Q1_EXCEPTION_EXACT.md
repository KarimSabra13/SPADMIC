# Server Run Request: O13 Abs5 Exact PD q1 Exception

Status: `READY_FOR_SERVER_RERUN_AFTER_SOURCE_DISCOVERY_FIX`

Run mode:

```text
O13_ABS5_PD_Q1_EXCEPTION_EXACT_MATCH
```

Purpose:

- keep O13 BUHDX4 -> BUHDX12 topology
- keep raw RO and final buffered phase clocks from abs3
- keep `clk_sys` async to raw/buffer oscillator clocks
- discover exactly 64 PD q1 sampler endpoints
- discover exactly 8 slow buffered phase source pins using the same per-tap BUHDX12 `u_drv/Q` resolver that abs3 used to create the buffered clocks
- apply a narrow intentional Vernier exception
- keep real local fast-domain timing visible

Do not run Innovus from this request.

## Command

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only

EXPECTED_HEAD=<agent_provided_sha>
ACTUAL_HEAD="$(git rev-parse HEAD)"
test "$ACTUAL_HEAD" = "$EXPECTED_HEAD"

git status --short
git log --oneline -5

bash MPTDC/syn/scripts/server_run_genus_o13_abs5_pd_q1_exception_exact.sh \
  20260609_o13_abs5b_pd_q1_source_fix
```

## Review After Run

```bash
RUN=20260609_o13_abs5b_pd_q1_source_fix

cat results/genus_osc_pd/$RUN/SUMMARY.md
cat results/genus_osc_pd/$RUN/pd_vernier_endpoint_discovery.rpt
cat results/genus_osc_pd/$RUN/pd_vernier_source_discovery.rpt
cat results/genus_osc_pd/$RUN/pd_vernier_exception_check.rpt
cat results/genus_osc_pd/$RUN/timing_pd_intentional_vernier.rpt
cat results/genus_osc_pd/$RUN/timing_path_classification_summary.md
cat results/genus_osc_pd/$RUN/sdc_command_failures.md
```

## Expected Key Results

```text
PD_VERNIER_FOUND_ENDPOINTS=64
PD_VERNIER_FOUND_SOURCES=8
PD_VERNIER_EXCEPTION_APPLIED=YES
PD_VERNIER_OVERMATCH=NO
PD_VERNIER_UNDERMATCH=NO
UNKNOWN_REVIEW_REQUIRED=0
```

The previous -422 ps Vernier setup paths should disappear from ordinary violating timing. The expected next real worst family is local fast-domain PD sampler timing, likely `q1_reg -> q2_reg`.

## Preserve Evidence

```bash
RUN=20260609_o13_abs5b_pd_q1_source_fix
SNAP=results/github_snapshots/${RUN}_snapshot

rm -rf "$SNAP"
mkdir -p "$SNAP"
cp -a results/genus_osc_pd/$RUN/. "$SNAP/"

cat > results/github_snapshots/${RUN}_manifest.txt <<EOF
O13 abs5 exact PD q1 Vernier exception Genus snapshot
RUN_ID=$RUN
FINAL_SIGNOFF=NO
FORMAT=directory_snapshot_no_tar
EOF

git add -f \
  "$SNAP" \
  results/github_snapshots/${RUN}_manifest.txt

git commit -m "server-results: O13 abs5 exact PD q1 exception snapshot"
git push origin SPADMIC_localtag
```
