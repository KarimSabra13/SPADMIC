# MPTDC PVS PG Short Root Cause - 2026-07-02

## Status

This note documents the PVS LVS VDD/VSS short seen after the internal dryGDS
risk-review streamout of:

```text
run_id=20260701_mptdc_211109_falsepath_nfast_risk_235618
source_checkpoint=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/checkpoints/repaired_route.enc.dat
source_def=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/def/repaired_route.def
drygds_dir=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608
pvs_lvs_findshorts=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_findshorts
```

The current classification is:

```text
Innovus geometry gate: PASS
Innovus regular connectivity gate: PASS
Innovus special connectivity gate: FAIL, pre-existing PG special issue
PVS LVS PG short gate: FAIL
Root cause class: EXPORTED_SPECIALNET_GEOMETRY
Final signoff ready: NO
Ready for tapeout: NO
```

This is still an internal dryGDS risk-review checkpoint only. It is not final
signoff and must not be treated as tapeout-clean.

## Why This Is Not A Label-Only Problem

PVS first reports label collapse:

```text
Different labels for net 2, it is assigned to "VDD_LEFT":
  VDD_LEFT  at (17.160, 361.160) on METTP_TEXT
  VDD_RIGHT at (1044.040, 361.160) on METTP_TEXT
  VSS_LEFT  at (14.160, 445.160) on METTP_TEXT
  VSS_RIGHT at (1047.040, 445.160) on METTP_TEXT
```

That warning by itself could look like text-label ambiguity. The full
`mptdc_axis_core_lvs.sum.shorts` report proves more than label ambiguity: it
contains a real conductor chain using `mttrm`, `m3trm`, `vtpCON`, `m2trm`,
`via2CON`, `m1trm`, and `via1` geometry.

The two relevant PVS shorts are:

```text
SHORT 2. VSS_LEFT  - VDD_LEFT in mptdc_axis_core
SHORT 3. VSS_RIGHT - VDD_LEFT in mptdc_axis_core
```

The PVS polygon path is therefore a physical extracted PG short until a fresh
PVS run proves otherwise.

## Confirmed Analysis Run

Analysis was run through the safe-copy wrapper:

```text
repo_head=9df7ed3f03704edea7c2d77eb27a59fa8dbec5d6
analysis_run=20260702_mptdc_pvs_pg_short_analyze_def_143715
analysis_dir=/sim/ksabra/SPADMIC_work/innovus/20260702_mptdc_pvs_pg_short_analyze_def_143715
tool=MPTDC/pnr/scripts/server_probe_mptdc_pvs_pg_short.sh
mode=analyze
```

The probe restored only a physical safe copy:

```text
safe_checkpoint=/sim/ksabra/SPADMIC_work/innovus/20260702_mptdc_pvs_pg_short_analyze_def_143715/source_checkpoint_safe/repaired_route.enc.dat
```

The accepted source checkpoint was not edited.

The final Innovus route-check gate remained:

```text
COMMAND_1_STATUS=PASS
COMMAND_2_STATUS=PASS
COMMAND_3_STATUS=PASS
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY
```

The special connectivity failure is expected from the existing PG dangling
class. The PVS short analysis is a separate foundry/LVS gate.

## PVS-To-DEF Mapping Result

The first matcher used Innovus `dbGet` sWire bboxes and found no polygon
matches. That did not mean the geometry was absent. The checkpoint serializes
the relevant special routes such that the matching evidence is clear in DEF but
not reliably visible as simple Innovus sWire boxes.

The DEF fallback parser expands `SPECIALNETS` route centerlines by the route
width and compares those boxes to PVS short polygons.

The confirmed mapping result is:

```text
TARGET_VDD_VSS_SHORT_COUNT=2
TARGET_POLYGON_COUNT=42
MATCHED_POLYGON_COUNT=28
BRIDGE_WINDOW_POLYGON_COUNT=26
VDD_MATCH_COUNT=18
VSS_MATCH_COUNT=19
INNOVUS_SWIRE_MATCH_COUNT=0
DEF_SPECIALNET_MATCH_COUNT=37
SWIRE_RECORDS_SCANNED=789
DEF_SPECIALNET_RECORDS_SCANNED=789
MATCH_RECORDS_SCANNED=1578
STREAMOUT_ONLY_SUSPECT=NO
ROOT_CAUSE_CLASS=EXPORTED_SPECIALNET_GEOMETRY
```

The important conclusion is `STREAMOUT_ONLY_SUSPECT=NO`: the PVS short polygons
match routed DEF special-net geometry. This is not a merge-only or
text-layer-only anomaly.

## Matched PG Path

The PVS path includes large, legitimate VDD/VSS rings and stripes plus a small
lower-left bridge chain. Representative matches:

```text
VDD METTP RING   16.160 16.160 18.160 785.760
VSS METTP RING   13.160 13.160 15.160 788.760
VDD MET3  STRIPE 16.160 600.160 1045.040 602.160
VSS MET3  STRIPE 13.160 684.160 1048.040 686.160
```

Those large rings/stripes are not deletion candidates. They explain how the
PVS labels become part of the same extracted connected component once a local
bridge is present.

The bounded local bridge candidates are:

```text
CANDIDATE_1_NET=VDD
CANDIDATE_1_LAYER=MET2
CANDIDATE_1_SHAPE=BLOCKWIRE
CANDIDATE_1_BOX=54.000 600.160 56.000 609.120
CANDIDATE_1_SPAN_UM=8.960

CANDIDATE_2_NET=VSS
CANDIDATE_2_LAYER=MET2
CANDIDATE_2_SHAPE=BLOCKWIRE
CANDIDATE_2_BOX=52.260 650.200 54.260 686.160
CANDIDATE_2_SPAN_UM=35.960

CANDIDATE_3_NET=VDD
CANDIDATE_3_LAYER=MET1
CANDIDATE_3_SHAPE=BLOCKWIRE
CANDIDATE_3_BOX=54.000 609.120 56.000 628.970
CANDIDATE_3_SPAN_UM=19.850
```

These three are the only current surgical proof candidates because they are:

```text
net in {VDD,VSS}
layer in {MET1,MET2,MET3,METTP}
shape=BLOCKWIRE
inside the lower-left bridge window
matched to PVS VDD/VSS short polygons
shorter than max_delete_span_um=90.0
```

The via shapes in the PVS path do not appear as DEF route records in this
parser, so they are not independently selected. The surgical proof removes the
short metal `BLOCKWIRE` links; if those are the true bridge, the vias become
irrelevant in the next PVS extraction.

## Root-Cause Interpretation

The most likely root cause is a local PG blockwire bridge around:

```text
x ~= 50.4 to 56.1 um
y ~= 600.1 to 686.2 um
```

The bridge connects a VDD lower-left vertical/stripe structure to a VSS
lower-left vertical/stripe structure through short MET2/MET1 blockwire pieces
and local vias. Once this local bridge exists, PVS sees the larger VDD/VSS
rings/stripes as one extracted net and reports both left and right VSS labels
shorted to VDD_LEFT.

This explains why Innovus can still show:

```text
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
```

while PVS LVS fails. Innovus route DRC/regular connectivity is not the same gate
as foundry extraction/LVS PG connectivity.

## Recommended Fix Path

### Fix 1 - Bounded Surgical Proof From Safe Copy

Run `surgical_proof` against the accepted source checkpoint through the safe
copy wrapper. This mode deletes only the current matched short `BLOCKWIRE`
candidates, one at a time, then runs the Innovus geometry/regular gate after
each deletion.

Acceptance for this step is narrow:

```text
DELETE_ATTEMPTS=3
DELETE_SUCCESSES=3
DIRTY_ABORT=0
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY or PASS_ROUTE_GATE
PVS_PG_SHORT_STATUS=SURGICAL_PROOF_EDITED_SAFE_COPY_NEEDS_DRYGDS_PVS
```

This does not prove final correctness. It only creates a safe-copy candidate
checkpoint for dryGDS/PVS confirmation.

### Fix 2 - Fresh dryGDS/PVS Confirmation

If the surgical proof passes the Innovus gate, rerun the same dryGDS/PVS debug
flow that created `drygds_oa_20260702_001608`, but use:

```text
CHK_DAT=<surgical_proof_run>/checkpoints/repaired_route.enc.dat
```

Acceptance for this step is:

```text
PVS LVS no VDD/VSS find-short entries
no Different labels collapse involving VDD_LEFT/VDD_RIGHT/VSS_LEFT/VSS_RIGHT
PVS DRC/LVS result explicitly captured under the new dryGDS directory
FINAL_SIGNOFF_READY remains NO until full signoff gates are clean
```

### Fix 3 - Generator-Level Repair If Surgical Proof Is Insufficient

If surgical proof either dirties Innovus geometry/regular connectivity or PVS
still reports the same short, do not broaden post-route `sroute`. The next
smart fix is to move upstream:

```text
1. identify which PG generation step creates the lower-left BLOCKWIRE chain;
2. prevent or clip those blockwires in the lower-left bridge window;
3. regenerate the checkpoint from the nearest safe pre-streamout or pre-route base;
4. rerun Innovus DRC/connectivity, dryGDS, and PVS.
```

Broad post-route PG repair remains a bad default because earlier post-route
`sroute` experiments connected some PG topology but created many route shorts.

## Commands - Surgical Proof

Use a fresh run id. Do not reuse the analysis directory.

```sh
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git pull --ff-only

export EXPECTED_HEAD=$(git rev-parse HEAD)
test "$(git rev-parse HEAD)" = "$EXPECTED_HEAD" || {
  echo "ERROR: HEAD mismatch, got $(git rev-parse HEAD), expected $EXPECTED_HEAD"
  exit 1
}

source /eda/cadence/eda_2023-2024
source .venv/bin/activate 2>/dev/null || true

export FP_RUN_ID=20260701_mptdc_211109_falsepath_nfast_risk_235618
export FP_DIR=/sim/ksabra/SPADMIC_work/innovus/$FP_RUN_ID
export DBG_DIR="$FP_DIR/drygds_oa_20260702_001608"
export LVS_RUN="$DBG_DIR/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_findshorts"

export PG_PROOF_RUN=20260702_mptdc_pvs_pg_short_surgical_proof_$(date +%H%M%S)

MPTDC/pnr/scripts/server_probe_mptdc_pvs_pg_short.sh \
  --checkpoint "$FP_DIR/checkpoints/repaired_route.enc.dat" \
  --source-def "$FP_DIR/def/repaired_route.def" \
  --pvs-shorts "$LVS_RUN/mptdc_axis_core_lvs.sum.shorts" \
  --run-id "$PG_PROOF_RUN" \
  --mode surgical_proof \
  --expected-head "$EXPECTED_HEAD"

export PG_PROOF_DIR=/sim/ksabra/SPADMIC_work/innovus/$PG_PROOF_RUN

sed -n '1,320p' "$PG_PROOF_DIR/reports/pvs_pg_short_root_cause_status.rpt"
grep -nE 'COMMAND_[0-9]+_STATUS=|DELETE_ATTEMPTS=|DELETE_SUCCESSES=|DIRTY_ABORT=|PVS_PG_SHORT_STATUS=|FINAL_SIGNOFF_READY=|READY_FOR_TAPEOUT=' \
  "$PG_PROOF_DIR/reports/pvs_pg_short_root_cause_status.rpt"
grep -nE 'FINAL_DRC=|FINAL_SHORTS=|FINAL_REGULAR_CONNECTIVITY_BAD=|FINAL_SPECIAL_CONNECTIVITY_BAD=|FINAL_CHECKPOINT_DAT=|CHECKPOINT_REPAIR_STATUS=' \
  "$PG_PROOF_DIR/reports/checkpoint_repair_status.rpt"
```

If the proof passes, the checkpoint to feed into the next dryGDS/PVS run is:

```text
$PG_PROOF_DIR/checkpoints/repaired_route.enc.dat
```

## Stop Rules

Stop and do not use the proof checkpoint if any of these happen:

```text
DIRTY_ABORT=1
FINAL_DRC != 0
FINAL_SHORTS != 0
FINAL_REGULAR_CONNECTIVITY_BAD != 0
CHECKPOINT_REPAIR_STATUS=FAIL_COMMAND
PVS_PG_SHORT_STATUS=FAIL_GEOMETRY_OR_REGULAR_DIRTY
```

Also stop if dryGDS/PVS still reports the same VDD/VSS short after a clean
surgical proof. In that case, use the new PVS report to extend the matched
bridge window or move to the generator-level repair path.

## Signoff Boundary

Even if the surgical proof and the next PVS short check pass, the block remains
not final until all independent gates are clean:

```text
Innovus DRC and route shorts
Innovus regular connectivity
Innovus special PG connectivity or documented foundry-acceptable waiver
PVS/Calibre/Assura DRC
PVS/Calibre/Assura LVS
antenna
timing without unacceptable risk exceptions
top-level integration contracts
```

The false-path nfast timing state, special-PG dangling state, and PVS VDD/VSS
short state must remain separate readiness labels.
