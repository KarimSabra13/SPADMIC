# MPTDC False-Path Checkpoint PG Dangling Repair Plan - 2026-07-02

## Objective

Use the current best internal dryGDS risk-review checkpoint as the source, make
a safe physical copy, and investigate the remaining VDD/VSS special-PG
connectivity failures without disturbing the accepted checkpoint.

This is not a full reroute plan. The current failure class is narrow:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
SPECIAL_PG_DANGLING_MARKERS=8
FAILURE_CLASS=VDD_VSS_IMPVFC_94_DANGLING_SPECIAL_WIRE_ONLY
```

## Source Checkpoint

```text
run_id=20260701_mptdc_211109_falsepath_nfast_risk_235618
result_dir=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618
source_checkpoint=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/checkpoints/repaired_route.enc.dat
source_def=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/def/repaired_route.def
label_dir=/sim/ksabra/SPADMIC_work/innovus/ACCEPTED_INTERNAL_DRYGDS_RISK_20260701_mptdc_211109_falsepath_nfast_risk_235618
```

The source checkpoint is accepted only for internal dryGDS risk review. It is
not final signoff and not ready for tapeout because setup timing is clean only
under the explicit nfast false-path exception, and special PG connectivity still
fails.

## Remaining Marker Coordinates

The remaining special-PG markers are:

```text
VDD MET3  dangling endpoints: (48.000,681.160) (48.000,121.160) (221.745,681.160) (221.745,121.160)
VDD METTP dangling endpoints: (201.160,118.000) (121.160,118.000)
VSS MET3  dangling endpoints: (48.000,125.160) (221.745,125.160)
```

Earlier topology dumps show that these coordinates line up with special-wire
stripe endpoints, not ordinary signal-route DRC:

```text
VDD MET3 stripe y=121.16 has two path segments ending at x=48.000 and x=221.745.
VDD MET3 stripe y=681.16 has two path segments ending at x=48.000 and x=221.745.
VDD METTP stripes x=121.16 and x=201.16 stop at y=118.000.
VSS MET3 stripe y=125.16 has two path segments ending at x=48.000 and x=221.745.
```

This points to a PG mesh segmentation artifact around the central blocked region
or macro/route keepout. It is not evidence that signal routing is dirty.

## Why Analysis Comes First

A prior probe tried small bounded endpoint deletion:

```text
editDelete -net VDD/VSS -layer <marker_layer> -area <small_box_around_marker> -type Special
ecoRoute -target
ecoRoute -fix_drc
```

That preserved geometry and regular connectivity, but it did not clear the
eight markers. Therefore the next useful step is object-level inspection:

1. Run `verifyConnectivity -type special -nets {VDD VSS} -report ...`.
2. Parse every `dangling Wire at (...) on layer: ...` line.
3. Match each marker to exact `sWire` objects whose endpoint equals the marker
   point.
4. Dump the matched object's net, layer, shape, status, width, box, points, and
   segment length.
5. Only if the matched object is truly safe to remove, delete it one marker at a
   time from a copied checkpoint and re-verify DRC, regular connectivity, and
   special connectivity after every deletion.

This avoids repeating blind `editDelete` or post-route `sroute`. Broad
post-route `sroute` previously connected some PG topology but created massive
shorts in related experiments, so it is not the first repair candidate here.

## Added Tools

Two repo tools implement the safe workflow:

```text
MPTDC/pnr/scripts/server_repair_mptdc_pg_dangling_checkpoint.sh
MPTDC/pnr/scripts/innovus_mptdc_pg_dangling_checkpoint_tools.tcl
```

The shell wrapper:

```text
1. checks repository HEAD and clean tracked worktree;
2. refuses to overwrite an existing result directory;
3. copies the source checkpoint into result_dir/source_checkpoint_safe/;
4. optionally copies the matching DEF into the same safe source bundle;
5. runs Innovus restore/analysis/repair against the safe copy only.
```

The Tcl tool:

```text
1. captures detailed VDD/VSS special connectivity;
2. parses dangling marker coordinates;
3. maps each marker to exact endpoint-matching sWire objects;
4. reports nearby VDD/VSS sWires for root-cause review;
5. optionally deletes exact matched sWire objects one by one in explicit repair modes.
```

Default mode is analysis-only. Repair is intentionally opt-in.

## Recommended Server Run - Analysis Only

Run this first. It should not delete anything.

```sh
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source /eda/cadence/eda_2023-2024
source .venv/bin/activate 2>/dev/null || true

git fetch origin SPADMIC_test
git checkout SPADMIC_test
git pull --ff-only

export EXPECTED_HEAD=<new_commit_after_this_plan_is_committed>
test "$(git rev-parse HEAD)" = "$EXPECTED_HEAD"

export FP_RUN_ID=20260701_mptdc_211109_falsepath_nfast_risk_235618
export FP_DIR=/sim/ksabra/SPADMIC_work/innovus/$FP_RUN_ID
export PG_ANALYZE_RUN_ID=20260702_mptdc_pg8_dangling_analyze_$(date +%H%M%S)

MPTDC/pnr/scripts/server_repair_mptdc_pg_dangling_checkpoint.sh \
  --run-id "$PG_ANALYZE_RUN_ID" \
  --checkpoint "$FP_DIR/checkpoints/repaired_route.enc.dat" \
  --source-def "$FP_DIR/def/repaired_route.def" \
  --mode analyze \
  --expected-head "$EXPECTED_HEAD"

export PG_ANALYZE_DIR=/sim/ksabra/SPADMIC_work/innovus/$PG_ANALYZE_RUN_ID
echo "PG_ANALYZE_DIR=$PG_ANALYZE_DIR"
```

Inspect:

```sh
grep -nE 'MARKER_COUNT=|MARKER_[0-9]+_EXACT_ENDPOINT_SWIRE_COUNT=|MARKER_[0-9]+_EXACT_1_(NET|LAYER|SHAPE|STATUS|GEOMTYPE|BOX|PTS|LENGTH_UM)=|PG_DANGLING_STATUS=|FINAL_DANGLING_MARKER_COUNT=' \
  "$PG_ANALYZE_DIR/reports/pg_dangling_analysis_status.rpt"

grep -nE 'FINAL_DRC=|FINAL_SHORTS=|FINAL_REGULAR_CONNECTIVITY_BAD=|FINAL_SPECIAL_CONNECTIVITY_BAD=|CHECKPOINT_REPAIR_STATUS=' \
  "$PG_ANALYZE_DIR/reports/checkpoint_repair_status.rpt"

cat "$PG_ANALYZE_DIR/manifests/safe_source_manifest.txt"
```

Expected analysis result:

```text
MARKER_COUNT=8
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
PG_DANGLING_STATUS=ANALYSIS_ONLY
```

The important new data is the exact matched `sWire` object and length for each
marker.

## Optional Repair Probe

Only run this if the analysis report shows exact one-to-one endpoint matches
and we accept that the matched objects may be long PG stripe segments.

```sh
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source /eda/cadence/eda_2023-2024
source .venv/bin/activate 2>/dev/null || true

export EXPECTED_HEAD=<new_commit_after_this_plan_is_committed>
test "$(git rev-parse HEAD)" = "$EXPECTED_HEAD"

export FP_RUN_ID=20260701_mptdc_211109_falsepath_nfast_risk_235618
export FP_DIR=/sim/ksabra/SPADMIC_work/innovus/$FP_RUN_ID
export PG_REPAIR_RUN_ID=20260702_mptdc_pg8_dangling_deleteall_$(date +%H%M%S)

MPTDC/pnr/scripts/server_repair_mptdc_pg_dangling_checkpoint.sh \
  --run-id "$PG_REPAIR_RUN_ID" \
  --checkpoint "$FP_DIR/checkpoints/repaired_route.enc.dat" \
  --source-def "$FP_DIR/def/repaired_route.def" \
  --mode delete_all \
  --allow-long-delete \
  --expected-head "$EXPECTED_HEAD"

export PG_REPAIR_DIR=/sim/ksabra/SPADMIC_work/innovus/$PG_REPAIR_RUN_ID
echo "PG_REPAIR_DIR=$PG_REPAIR_DIR"
```

Inspect:

```sh
grep -nE 'PG_DANGLING_DELETE_ATTEMPTS=|PG_DANGLING_DELETE_SUCCESSES=|PG_DANGLING_DIRTY_ABORT=|PG_DANGLING_STATUS=|FINAL_DANGLING_MARKER_COUNT=' \
  "$PG_REPAIR_DIR/reports/pg_dangling_analysis_status.rpt"

grep -nE 'FINAL_DRC=|FINAL_SHORTS=|FINAL_REGULAR_CONNECTIVITY_BAD=|FINAL_SPECIAL_CONNECTIVITY_BAD=|FINAL_ROUTE_GATE_PASS=|CHECKPOINT_REPAIR_STATUS=|FINAL_CHECKPOINT_DAT=' \
  "$PG_REPAIR_DIR/reports/checkpoint_repair_status.rpt"
```

Repair acceptance requires:

```text
PG_DANGLING_DIRTY_ABORT=0
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=0
FINAL_ROUTE_GATE_PASS=1
CHECKPOINT_REPAIR_STATUS=PASS_ROUTE_GATE
```

If deletion clears the markers but weakens PG topology too much, it is still a
review item. The next external signoff step must include full PG/LVS review.

## Stop Conditions

Stop and do not use the repair checkpoint if any of these occur:

```text
FINAL_DRC != 0
FINAL_SHORTS != 0
FINAL_REGULAR_CONNECTIVITY_BAD != 0
PG_DANGLING_DIRTY_ABORT=1
MARKER_N_EXACT_ENDPOINT_SWIRE_COUNT != 1 for any marker
```

If the analysis shows that the eight markers are long intentional stripe
endpoints, the most defensible options are:

```text
1. formal internal dryGDS waiver for IMPVFC-94-only dangling special-wire endpoints;
2. manual PG mesh edit in layout with signoff-owner approval;
3. pre-route PG topology fix in the main PnR flow, then reroute and rerun timing.
```

Do not claim final signoff until special PG connectivity, LVS, antenna, foundry
DRC, and the nfast timing-exception policy are resolved.
