#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_tie1_insertion_trial.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_PNR_ID=failed_v6r
SOURCE_PVS_ID=physical_source_fillernorm
BOUNDARY_ID=boundary_step5r
PROBE_ID=tie1_probe_step6r
FAILED_TRIAL_ID=tie1_trial_step7i_zero_effect
SOURCE_PHYSICAL_ID=physical_baseline
DRIVER="$REPO/MPTDC/pnr/scripts/server_run_mptdc_tie1_insertion_trial.sh"
TRIAL_TCL="$REPO/MPTDC/pnr/scripts/innovus_mptdc_tie1_insertion_trial.tcl"
INNOVUS_STUB="$TMP_ROOT/innovus_stub.sh"
PUBLISHER_STUB="$TMP_ROOT/publisher_stub.sh"

tree_hash() {
  local root="$1"
  (
    cd "$root"
    find -L . -type f \
      ! -name '*.cdslck' ! -name '*.lock' ! -name '.*lock*' \
      -print0 |
      LC_ALL=C sort -z |
      while IFS= read -r -d '' file; do
        printf '%s\t' "$file"
        sha256sum "$file"
      done
  ) | sha256sum | awk '{print $1}'
}

mkdir -p \
  "$REPO/MPTDC/pnr/scripts" \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$PROBE_ID/reports" \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$PROBE_ID/manifests" \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$FAILED_TRIAL_ID/reports" \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$FAILED_TRIAL_ID/manifests" \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$SOURCE_PHYSICAL_ID/reports" \
  "$WORK/$SOURCE_PNR_ID/checkpoints/repaired_route.enc.dat" \
  "$WORK/$PROBE_ID/reports" \
  "$WORK/$PROBE_ID/manifests" \
  "$WORK/$FAILED_TRIAL_ID/reports" \
  "$WORK/$FAILED_TRIAL_ID/manifests"

cp -p "$PNR_DIR/server_run_mptdc_tie1_insertion_trial.sh" "$DRIVER"
cp -p "$PNR_DIR/innovus_mptdc_tie1_insertion_trial.tcl" "$TRIAL_TCL"
printf 'immutable checkpoint fixture\n' \
  > "$WORK/$SOURCE_PNR_ID/checkpoints/repaired_route.enc.dat/design.bin"
SOURCE_CHECKPOINT="$WORK/$SOURCE_PNR_ID/checkpoints/repaired_route.enc.dat"
SOURCE_CHECKPOINT_SHA="$(tree_hash "$SOURCE_CHECKPOINT")"

FILLER_REPORT="$REPO/MPTDC/docs/server_snapshots/innovus/$SOURCE_PHYSICAL_ID/reports/filler_status.rpt"
ROW_REPORT="$REPO/MPTDC/docs/server_snapshots/innovus/$SOURCE_PHYSICAL_ID/reports/row_infra_insertion.rpt"
cat > "$FILLER_REPORT" <<'EOF'
FILLER_INSERTION_STATUS=PASS
FILLER_CANDIDATES=FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD
FILLER_COUNT=24797
EOF
cat > "$ROW_REPORT" <<'EOF'
FILLER_CANDIDATES=FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD
TIE_HIGH_CANDIDATES=LOGIC1DJIHD LOGIC1LVJIHD
TIE_LOW_CANDIDATES=LOGIC0DJIHD LOGIC0LVJIHD
EOF
FILLER_SHA="$(sha256sum "$FILLER_REPORT" | awk '{print $1}')"
ROW_SHA="$(sha256sum "$ROW_REPORT" | awk '{print $1}')"

PROBE_GATE="$WORK/$PROBE_ID/reports/operator_gate_tie1_checkpoint_probe.rpt"
cat > "$PROBE_GATE" <<EOF
STEP=TIE1_CHECKPOINT_PROBE
BOUNDARY_PVS_RUN_ID=$BOUNDARY_ID
SOURCE_PVS_RUN_ID=$SOURCE_PVS_ID
SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT
CADENCE_ENV_STATUS=PASS
INNOVUS_RC=0
PROBE_STATUS=PASS
RESTORE_STATUS=PASS
CORE_QUERY_STATUS=PASS
CORE_QUERY_ERROR_COUNT=0
TIE1_SOURCE_TOKEN_COUNT=0
TIE_MASTER_SOURCE_TOKEN_COUNT=0
TIE1_NET_COUNT=0
TIE1_INST_TERM_COUNT=0
TIE1_REGULAR_WIRE_COUNT=0
TIE1_SPECIAL_WIRE_COUNT=0
TIE1_VIA_COUNT=0
TIE_AVAILABLE_MASTER_COUNT=4
PHYSICAL_TIE_MASTER_COUNT=0
PHYSICAL_TIE_INSTANCE_COUNT=0
FLAGGED_TIE_HIGH_TERM_COUNT=91
FLAGGED_TIE_LOW_TERM_COUNT=0
SOURCE_CHECKPOINT_HASH_STATUS=PASS
SAFE_COPY_MATCH_STATUS=PASS
SAFE_CHECKPOINT_HASH_STATUS=PASS
BOUNDARY_EVIDENCE_HASH_STATUS=PASS
PHYSICAL_SOURCE_HASH_STATUS=PASS
DESIGN_MUTATION_COUNT=0
READ_ONLY_STATUS=PASS
SIGNOFF_ELIGIBLE=NO
DECISION=PASS_REVIEW_TIE1_EVIDENCE
NEXT_STAGE=REVIEW_TIE1_EVIDENCE_BEFORE_HASH_GUARDED_TRIAL
EOF

cat > "$WORK/$PROBE_ID/reports/tie1_checkpoint_probe_status.rpt" <<'EOF'
STEP=TIE1_CHECKPOINT_PROBE
PROBE_STATUS=PASS
EOF
cat > "$WORK/$PROBE_ID/reports/tie1_candidate_master_inventory.tsv" <<'EOF'
master	polarity	library_master_count	physical_instance_count	library_status	instance_query_status
LOGIC1DJIHD	HIGH	1	0	PASS	PASS
LOGIC1LVJIHD	HIGH	1	0	PASS	PASS
LOGIC0DJIHD	LOW	1	0	PASS	PASS
LOGIC0LVJIHD	LOW	1	0	PASS	PASS
EOF
{
  printf 'polarity\tinst_term\tinstance\tmaster\tpin\tnet\n'
  for index in $(seq 1 91); do
    printf 'HIGH\t{u_sink[%03d]/SN}\t{u_sink[%03d]}\tDFRSJIHDX1\tSN\t0x0\n' \
      "$index" "$index"
  done
} > "$WORK/$PROBE_ID/reports/tie_flagged_term_inventory.tsv"
cat > "$WORK/$PROBE_ID/reports/tie_command_availability.rpt" <<'EOF'
addTieHiLo_STATUS=AVAILABLE
setTieHiLoMode_STATUS=AVAILABLE
EOF
cat > "$WORK/$PROBE_ID/manifests/tie1_checkpoint_probe_inputs.rpt" <<EOF
SOURCE_CHECKPOINT_SHA256_PRE=$SOURCE_CHECKPOINT_SHA
EOF
cat > "$WORK/$PROBE_ID/manifests/source_physical_lvs_contract.rpt" <<EOF
LVS_SOURCE_CONTRACT_STATUS=PASS
PHYSICAL_ONLY_INSTANCE_REMOVAL_POLICY=EXACT_TRACKED_FILLER_REPORT_MASTER_SET
FILLER_REPORT=$FILLER_REPORT
FILLER_REPORT_SHA256=$FILLER_SHA
ROW_INFRA_REPORT=$ROW_REPORT
ROW_INFRA_REPORT_SHA256=$ROW_SHA
PHYSICAL_ONLY_FILLER_MASTER_COUNT=8
PHYSICAL_ONLY_FILLER_MASTER_SET=FEED25JIHD,FEED15JIHD,FEED10JIHD,FEED7JIHD,FEED5JIHD,FEED3JIHD,FEED2JIHD,FEED1JIHD
PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_EXPECTED=24797
PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_INPUT=24797
PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_REMOVED=24797
PHYSICAL_ONLY_FILLER_REMOVAL_STATUS=PASS
PHYSICAL_TIE_CANDIDATE_COUNT=4
PHYSICAL_TIE_CANDIDATE_SET=LOGIC1DJIHD,LOGIC1LVJIHD,LOGIC0DJIHD,LOGIC0LVJIHD
PHYSICAL_TIE_MASTER_COUNT=0
PHYSICAL_TIE_INSTANCE_COUNT=0
PHYSICAL_TIE_PRESERVATION_STATUS=PASS
EOF

for rel in \
  reports/operator_gate_tie1_checkpoint_probe.rpt \
  reports/tie1_checkpoint_probe_status.rpt \
  reports/tie1_candidate_master_inventory.tsv \
  reports/tie_flagged_term_inventory.tsv \
  reports/tie_command_availability.rpt \
  manifests/tie1_checkpoint_probe_inputs.rpt \
  manifests/source_physical_lvs_contract.rpt; do
  cp -p "$WORK/$PROBE_ID/$rel" \
    "$REPO/MPTDC/docs/server_snapshots/innovus/$PROBE_ID/$rel"
done

FAILED_TRIAL_TARGETS="$WORK/$FAILED_TRIAL_ID/manifests/tie1_instance_pin_targets.txt"
awk -F '\t' '
  NR > 1 {
    target=$2
    if (target ~ /^\{.*\}$/) {
      target=substr(target, 2, length(target)-2)
    }
    print target
  }
' "$WORK/$PROBE_ID/reports/tie_flagged_term_inventory.tsv" \
  > "$FAILED_TRIAL_TARGETS"
TEST_TARGET_SHA="$(sha256sum "$FAILED_TRIAL_TARGETS" | awk '{print $1}')"

cat > "$WORK/$FAILED_TRIAL_ID/reports/operator_gate_tie1_insertion_trial.rpt" <<EOF
STEP=TIE1_INSERTION_TRIAL
PROBE_RUN_ID=$PROBE_ID
SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT
AUTHORIZATION=EXACT_MPTDC_TIE1_HIGH_TRIAL
INNOVUS_RC=1
TIE1_INSERTION_TRIAL_STATUS=FAIL
ADD_TIE_SELECTION_MODE=EXACT_INSTANCE_PIN_FILE
INSTANCE_PIN_INPUT_GENERATION_STATUS=PASS
INSTANCE_PIN_TARGET_COUNT=91
INSTANCE_PIN_TARGET_UNIQUE_COUNT=91
INSTANCE_PIN_TARGET_INVALID_COUNT=0
INSTANCE_PIN_TARGET_MATCH_STATUS=PASS
SET_TIE_MODE_STATUS=PASS
ADD_TIE_STATUS=PASS
ADD_TIE_EFFECT_STATUS=FAIL
ADD_TIE_EFFECT_REASON=NO_ELIGIBLE_TARGET_WAS_CONNECTED
FINAL_CONNECTED_HIGH_TERM_COUNT=0
FINAL_DISCONNECTED_HIGH_TERM_COUNT=91
FINAL_TIE_NET_COUNT=0
FILLER_COUNT_AFTER=24797
BASELINE_DRC=1
BASELINE_SHORTS=0
BASELINE_REGULAR_CONNECTIVITY_BAD=0
BASELINE_SPECIAL_CONNECTIVITY_BAD=1
BASELINE_UNROUTED_NETS=0
SOURCE_CHECKPOINT_HASH_STATUS=PASS
SAFE_INPUT_READ_ONLY_STATUS=PASS
INSTANCE_PIN_INPUT_READ_ONLY_STATUS=PASS
INSTANCE_PIN_TARGET_SHA256_PRE=$TEST_TARGET_SHA
INSTANCE_PIN_TARGET_SHA256_POST=$TEST_TARGET_SHA
CANDIDATE_CHECKPOINT_STATUS=FAIL
DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
EOF
cat > "$WORK/$FAILED_TRIAL_ID/reports/tie1_insertion_trial_status.rpt" <<'EOF'
STEP=TIE1_INSERTION_TRIAL_STATUS
TIE1_INSERTION_TRIAL_STATUS=FAIL
ADD_TIE_EFFECT_STATUS=FAIL
EOF
cat > "$WORK/$FAILED_TRIAL_ID/reports/tie1_insertion_trial_action.rpt" <<'EOF'
STEP=TIE1_INSERTION_TRIAL_ACTION
ADD_TIE_SELECTION_MODE=EXACT_INSTANCE_PIN_FILE
ADD_TIE_EFFECT_REASON=NO_ELIGIBLE_TARGET_WAS_CONNECTED
EOF
cat > "$WORK/$FAILED_TRIAL_ID/manifests/tie1_insertion_trial_inputs.rpt" <<EOF
STEP=TIE1_INSERTION_TRIAL_INPUTS
PROBE_RUN_ID=$PROBE_ID
SOURCE_CHECKPOINT_SHA256_PRE=$SOURCE_CHECKPOINT_SHA
INSTANCE_PIN_TARGET_SHA256=$TEST_TARGET_SHA
EOF
cat > "$WORK/$FAILED_TRIAL_ID/reports/tie1_trial_baseline_check_place.rpt" <<'EOF'
*info: Placed = 39089
*info: Unplaced = 0
Placement Density: 100.00%(907533/907533)
EOF

for rel in \
  reports/operator_gate_tie1_insertion_trial.rpt \
  reports/tie1_insertion_trial_status.rpt \
  reports/tie1_insertion_trial_action.rpt \
  reports/tie1_trial_baseline_check_place.rpt \
  manifests/tie1_instance_pin_targets.txt \
  manifests/tie1_insertion_trial_inputs.rpt; do
  cp -p "$WORK/$FAILED_TRIAL_ID/$rel" \
    "$REPO/MPTDC/docs/server_snapshots/innovus/$FAILED_TRIAL_ID/$rel"
done

export MPTDC_TIE1_TRIAL_EXPECTED_TARGET_SHA="$TEST_TARGET_SHA"

cat > "$INNOVUS_STUB" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
outdir="${MPTDC_TIE1_TRIAL_OUTDIR:?}"
checkpoint="${MPTDC_TIE1_TRIAL_CKPT:?}"
instance_pin_file="${MPTDC_TIE1_TRIAL_INSTANCE_PIN_FILE:?}"
mkdir -p "$outdir/reports"
test -s "$instance_pin_file"
test "$(awk 'NF {n++} END {print n+0}' "$instance_pin_file")" -eq 91

if [[ "${MPTDC_TEST_MUTATE_SAFE_COPY:-0}" == 1 ]]; then
  printf 'unexpected mutation\n' >> "$checkpoint/design.bin"
fi

if [[ "${MPTDC_TEST_TRIAL_FAIL:-0}" == 1 ]]; then
  cat > "$outdir/reports/tie1_insertion_trial_status.rpt" <<'RPT'
COMMAND_PRECHECK=PASS
ADD_TIE_SELECTION_MODE=EXACT_INSTANCE_PIN_FILE
INSTANCE_PIN_TARGET_FILE_STATUS=PASS
INSTANCE_PIN_TARGET_COUNT=91
INSTANCE_PIN_TARGET_UNIQUE_COUNT=91
INSTANCE_PIN_TARGET_INVALID_COUNT=0
INSTANCE_PIN_TARGET_MATCH_STATUS=PASS
SET_TIE_MODE_STATUS=PASS
ADD_TIE_STATUS=FAIL
ADD_TIE_EFFECT_STATUS=FAIL
ADD_TIE_EFFECT_REASON=COMMAND_FAILED
SELECTED_ROUTE_STATUS=NOT_RUN
BASELINE_PLACEMENT_STATUS=PASS
FINAL_PLACEMENT_STATUS=PASS
FINAL_CONNECTED_HIGH_TERM_COUNT=0
FINAL_DISCONNECTED_HIGH_TERM_COUNT=91
FINAL_FLAGGED_LOW_TERM_COUNT=0
FINAL_TIE_NET_COUNT=0
TIE_NET_SOURCE_CONTRACT_STATUS=FAIL
TIE_NET_ROUTE_STATUS=FAIL
TIE_FANOUT_STATUS=PASS
MAX_OBSERVED_TIE_FANOUT=0
TIE_HIGH_INSTANCE_DELTA=0
TARGET_HIGH_INSTANCE_DELTA=0
ALTERNATE_TIE_MASTER_DELTA=0
TIE_LOW_INSTANCE_DELTA=0
FILLER_COUNT_AFTER=24797
UNEXPLAINED_INSTANCE_DELTA=0
PHYSICAL_DEBT_PRESERVATION_STATUS=PASS
BASELINE_DRC=1
BASELINE_SHORTS=0
BASELINE_REGULAR_CONNECTIVITY_BAD=0
BASELINE_SPECIAL_CONNECTIVITY_BAD=1
BASELINE_UNROUTED_NETS=0
BASELINE_REPORT_ROUTE_ZERO_STATUS=PASS
BASELINE_DRC_MARKER_SIGNATURE_COUNT=1
BASELINE_DRC_MARKER_SIGNATURE={1 2 3 4}|MET1|Geometry|Minimal_Area|Net_n
FINAL_DRC=1
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
FINAL_UNROUTED_NETS=0
FINAL_REPORT_ROUTE_ZERO_STATUS=PASS
FINAL_DRC_MARKER_SIGNATURE_COUNT=1
FINAL_DRC_MARKER_SIGNATURE={1 2 3 4}|MET1|Geometry|Minimal_Area|Net_n
CHECKPOINT_SAVE_STATUS=NOT_RUN
CORE_QUERY_ERROR_COUNT=0
TIE1_INSERTION_TRIAL_STATUS=FAIL
RPT
  cat > "$outdir/reports/filler_status.rpt" <<'RPT'
FILLER_INSERTION_STATUS=FAIL
RPT
  exit 1
fi

mkdir -p "$outdir/checkpoints/repaired_route.enc.dat"
printf 'accepted candidate fixture\n' \
  > "$outdir/checkpoints/repaired_route.enc.dat/design.bin"
cat > "$outdir/reports/tie1_insertion_trial_status.rpt" <<'RPT'
COMMAND_PRECHECK=PASS
FILLER_RECYCLE_MODE=DELETE_INSERT_ROUTE_REFILL
FILLER_DELETE_SELECTION_MODE=EXACT_TRACKED_MASTER_LIST
FILLER_DELETE_MASTER_COUNT=8
FILLER_DELETE_MASTER_SET=FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD
FILLER_DELETE_STATUS=PASS
FILLER_DELETE_EFFECT_STATUS=PASS
FILLER_COUNT_POST_DELETE=0
POST_DELETE_NONFILLER_FINGERPRINT_STATUS=PASS
POST_DELETE_ROUTE_SIGNATURE_STATUS=PASS
ADD_TIE_SELECTION_MODE=EXACT_INSTANCE_PIN_FILE
INSTANCE_PIN_TARGET_FILE_STATUS=PASS
INSTANCE_PIN_TARGET_COUNT=91
INSTANCE_PIN_TARGET_UNIQUE_COUNT=91
INSTANCE_PIN_TARGET_INVALID_COUNT=0
INSTANCE_PIN_TARGET_MATCH_STATUS=PASS
SET_TIE_MODE_STATUS=PASS
ADD_TIE_STATUS=PASS
ADD_TIE_EFFECT_STATUS=PASS
ADD_TIE_EFFECT_REASON=NONE
SELECTED_ROUTE_STATUS=PASS
FILLER_MODE_STATUS=PASS
FILLER_REFILL_COMMAND_STATUS=PASS
PG_CONNECTIVITY_REBIND_STATUS=PASS
FILLER_REFILL_STATUS=PASS
BASELINE_PLACEMENT_STATUS=PASS
FINAL_PLACEMENT_STATUS=PASS
FINAL_CONNECTED_HIGH_TERM_COUNT=91
FINAL_DISCONNECTED_HIGH_TERM_COUNT=0
FINAL_FLAGGED_LOW_TERM_COUNT=0
FINAL_TIE_NET_COUNT=12
TIE_NET_SOURCE_CONTRACT_STATUS=PASS
TIE_NET_ROUTE_STATUS=PASS
TIE_FANOUT_STATUS=PASS
MAX_OBSERVED_TIE_FANOUT=8
TIE_HIGH_INSTANCE_DELTA=12
TARGET_HIGH_INSTANCE_DELTA=12
ALTERNATE_TIE_MASTER_DELTA=0
TIE_LOW_INSTANCE_DELTA=0
FILLER_COUNT_AFTER=24785
FINAL_FILLER_MASTER_SET_STATUS=PASS
NONFILLER_FINGERPRINT_STATUS=PASS
BASELINE_SITE_OCCUPANCY_STATUS=PASS
BASELINE_PLACEMENT_SITE_OCCUPIED=907533
BASELINE_PLACEMENT_SITE_CAPACITY=907533
FINAL_SITE_OCCUPANCY_STATUS=PASS
FINAL_PLACEMENT_SITE_OCCUPIED=907533
FINAL_PLACEMENT_SITE_CAPACITY=907533
UNEXPLAINED_INSTANCE_DELTA=0
PHYSICAL_DEBT_PRESERVATION_STATUS=PASS
BASELINE_DRC=1
BASELINE_SHORTS=0
BASELINE_REGULAR_CONNECTIVITY_BAD=0
BASELINE_SPECIAL_CONNECTIVITY_BAD=1
BASELINE_UNROUTED_NETS=0
BASELINE_REPORT_ROUTE_ZERO_STATUS=PASS
BASELINE_DRC_MARKER_SIGNATURE_COUNT=1
BASELINE_DRC_MARKER_SIGNATURE={1 2 3 4}|MET1|Geometry|Minimal_Area|Net_n
FINAL_DRC=1
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_BAD=1
FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
FINAL_UNROUTED_NETS=0
FINAL_REPORT_ROUTE_ZERO_STATUS=PASS
FINAL_DRC_MARKER_SIGNATURE_COUNT=1
FINAL_DRC_MARKER_SIGNATURE={1 2 3 4}|MET1|Geometry|Minimal_Area|Net_n
CHECKPOINT_SAVE_STATUS=PASS
CORE_QUERY_ERROR_COUNT=0
TIE1_INSERTION_TRIAL_STATUS=PASS
RPT
if [[ "${MPTDC_TEST_ALTERNATE_TIE:-0}" == 1 ]]; then
  sed -i \
    -e 's/^TARGET_HIGH_INSTANCE_DELTA=12$/TARGET_HIGH_INSTANCE_DELTA=11/' \
    -e 's/^ALTERNATE_TIE_MASTER_DELTA=0$/ALTERNATE_TIE_MASTER_DELTA=1/' \
    "$outdir/reports/tie1_insertion_trial_status.rpt"
fi
if [[ "${MPTDC_TEST_UNUSED_TARGET_TIE:-0}" == 1 ]]; then
  sed -i \
    -e 's/^TIE_HIGH_INSTANCE_DELTA=12$/TIE_HIGH_INSTANCE_DELTA=13/' \
    -e 's/^TARGET_HIGH_INSTANCE_DELTA=12$/TARGET_HIGH_INSTANCE_DELTA=13/' \
    "$outdir/reports/tie1_insertion_trial_status.rpt"
fi
if [[ "${MPTDC_TEST_MARKER_MISMATCH:-0}" == 1 ]]; then
  sed -i \
    's/^FINAL_DRC_MARKER_SIGNATURE=.*$/FINAL_DRC_MARKER_SIGNATURE={5 6 7 8}|MET2|Geometry|Minimal_Area|Net_m/' \
    "$outdir/reports/tie1_insertion_trial_status.rpt"
fi
if [[ "${MPTDC_TEST_ZERO_EFFECT:-0}" == 1 ]]; then
  sed -i \
    -e 's/^ADD_TIE_EFFECT_STATUS=PASS$/ADD_TIE_EFFECT_STATUS=FAIL/' \
    -e 's/^ADD_TIE_EFFECT_REASON=NONE$/ADD_TIE_EFFECT_REASON=NO_ELIGIBLE_TARGET_WAS_CONNECTED/' \
    -e 's/^SELECTED_ROUTE_STATUS=PASS$/SELECTED_ROUTE_STATUS=NOT_RUN/' \
    -e 's/^FINAL_CONNECTED_HIGH_TERM_COUNT=91$/FINAL_CONNECTED_HIGH_TERM_COUNT=0/' \
    -e 's/^FINAL_DISCONNECTED_HIGH_TERM_COUNT=0$/FINAL_DISCONNECTED_HIGH_TERM_COUNT=91/' \
    -e 's/^FINAL_TIE_NET_COUNT=12$/FINAL_TIE_NET_COUNT=0/' \
    -e 's/^MAX_OBSERVED_TIE_FANOUT=8$/MAX_OBSERVED_TIE_FANOUT=0/' \
    -e 's/^TIE_HIGH_INSTANCE_DELTA=12$/TIE_HIGH_INSTANCE_DELTA=0/' \
    -e 's/^TARGET_HIGH_INSTANCE_DELTA=12$/TARGET_HIGH_INSTANCE_DELTA=0/' \
    -e 's/^CHECKPOINT_SAVE_STATUS=PASS$/CHECKPOINT_SAVE_STATUS=NOT_RUN/' \
    -e 's/^TIE1_INSERTION_TRIAL_STATUS=PASS$/TIE1_INSERTION_TRIAL_STATUS=FAIL/' \
    "$outdir/reports/tie1_insertion_trial_status.rpt"
fi
if [[ "${MPTDC_TEST_DELETE_EFFECT:-0}" == 1 ]]; then
  sed -i \
    -e 's/^FILLER_DELETE_EFFECT_STATUS=PASS$/FILLER_DELETE_EFFECT_STATUS=FAIL/' \
    -e 's/^FILLER_COUNT_POST_DELETE=0$/FILLER_COUNT_POST_DELETE=1/' \
    "$outdir/reports/tie1_insertion_trial_status.rpt"
fi
if [[ "${MPTDC_TEST_REFILL_FAIL:-0}" == 1 ]]; then
  sed -i \
    -e 's/^FILLER_REFILL_COMMAND_STATUS=PASS$/FILLER_REFILL_COMMAND_STATUS=FAIL/' \
    -e 's/^FILLER_REFILL_STATUS=PASS$/FILLER_REFILL_STATUS=FAIL/' \
    -e 's/^FINAL_SITE_OCCUPANCY_STATUS=PASS$/FINAL_SITE_OCCUPANCY_STATUS=FAIL/' \
    -e 's/^FINAL_PLACEMENT_SITE_OCCUPIED=907533$/FINAL_PLACEMENT_SITE_OCCUPIED=907532/' \
    "$outdir/reports/tie1_insertion_trial_status.rpt"
fi
if [[ "${MPTDC_TEST_NONFILLER_CHANGE:-0}" == 1 ]]; then
  sed -i \
    's/^NONFILLER_FINGERPRINT_STATUS=PASS$/NONFILLER_FINGERPRINT_STATUS=FAIL/' \
    "$outdir/reports/tie1_insertion_trial_status.rpt"
fi
cat > "$outdir/reports/filler_status.rpt" <<'RPT'
FILLER_CANDIDATES=FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD
FILLER_COUNT=24785
FILLER_DELETE_SELECTION_MODE=EXACT_TRACKED_MASTER_LIST
FILLER_DELETE_MASTER_COUNT=8
FILLER_DELETE_MASTER_SET=FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD
FILLER_DELETE_STATUS=PASS
FILLER_DELETE_EFFECT_STATUS=PASS
FILLER_REFILL_COMMAND_STATUS=PASS
FILLER_REFILL_STATUS=PASS
FILLER_INSERTION_STATUS=PASS
FILLER_ADJUSTMENT_POLICY=EXACT_DELETE_INSERT_ROUTE_REFILL_PRIVATE_COPY
FINAL_FILLER_MASTER_SET_STATUS=PASS
NONFILLER_FINGERPRINT_STATUS=PASS
FINAL_SITE_OCCUPANCY_STATUS=PASS
FINAL_PLACEMENT_SITE_OCCUPIED=907533
FINAL_PLACEMENT_SITE_CAPACITY=907533
RPT
cat > "$outdir/reports/tie1_insertion_trial_action.rpt" <<'RPT'
STEP=TIE1_INSERTION_TRIAL_ACTION
TIE1_INSERTION_TRIAL_STATUS=PASS
RPT
cat > "$outdir/reports/tie1_inserted_net_inventory.tsv" <<'RPT'
net	sink_count	tie_high_source_count	inst_term_count	wire_count	via_count	contract_status	route_status
MPTDC_TIE1_0	8	1	9	1	0	PASS	PASS
RPT
if [[ "${MPTDC_TEST_ZERO_EFFECT:-0}" == 1 ]]; then
  exit 1
fi
exit 0
EOF

cat > "$PUBLISHER_STUB" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MPTDC_TEST_PUBLISH_ARGS:?}"
exit 0
EOF
chmod +x "$INNOVUS_STUB" "$PUBLISHER_STUB"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC tie1 trial test'
git -C "$REPO" config user.email 'mptdc-tie1-trial@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

SOURCE_HASH_BEFORE="$(tree_hash "$SOURCE_CHECKPOINT")"
RUN_ID=tie1_trial_pass
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/pass.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id "$RUN_ID" \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'TIE1_INSERTION_TRIAL_PREFLIGHT=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'RESTORE_COMMAND_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'DELETE_FILLER_COMMAND_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'DELETE_FILLER_MASTER_OPTION_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'SET_MODE_COMMAND_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'ADD_TIE_COMMAND_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'INSTANCE_PIN_OPTION_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'SET_FILLER_MODE_COMMAND_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'ADD_FILLER_COMMAND_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'PG_REBIND_CALL_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'SAVE_COMMAND_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'SELECTED_ROUTE_CALL_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'FORBIDDEN_MUTATION_COUNT=0' "$TMP_ROOT/pass.stdout"
grep -qx 'TIE1_INSERTION_TRIAL_RECOVERY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_TIE1_TRIAL_CONTINUE' "$TMP_ROOT/pass.stdout"
grep -qx 'NEXT_STAGE=DIAGNOSTIC_PHYSICAL_PVS_FROM_TIE1_TRIAL' "$TMP_ROOT/pass.stdout"
grep -qx 'NUMERIC_GATE_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'ADD_TIE_SELECTION_MODE=EXACT_INSTANCE_PIN_FILE' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'INSTANCE_PIN_INPUT_GENERATION_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'INSTANCE_PIN_TARGET_MATCH_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'INSTANCE_PIN_INPUT_READ_ONLY_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'ADD_TIE_EFFECT_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FILLER_DELETE_EFFECT_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FILLER_DELETE_SELECTION_MODE=EXACT_TRACKED_MASTER_LIST' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FILLER_DELETE_MASTER_COUNT=8' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FILLER_DELETE_MASTER_SET=FEED25JIHD FEED15JIHD FEED10JIHD FEED7JIHD FEED5JIHD FEED3JIHD FEED2JIHD FEED1JIHD' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FILLER_REFILL_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'NONFILLER_FINGERPRINT_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FINAL_SITE_OCCUPANCY_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FILLER_COUNT_AFTER=24785' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'TARGET_HIGH_INSTANCE_DELTA=12' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'ALTERNATE_TIE_MASTER_DELTA=0' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DRC_MARKER_SIGNATURE_MATCH_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FINAL_REPORT_ROUTE_ZERO_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'SOURCE_CHECKPOINT_HASH_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_tie1_insertion_trial.rpt"
grep -q "innovus $RUN_ID $WORK/$RUN_ID TIE1_INSERTION_TRIAL" \
  "$TMP_ROOT/pass.publish.args"
test -s "$WORK/$RUN_ID/checkpoints/repaired_route.enc.dat/design.bin"
test "$(wc -l < "$WORK/$RUN_ID/manifests/tie1_instance_pin_targets.txt")" -eq 91
grep -Fqx 'u_sink[001]/SN' \
  "$WORK/$RUN_ID/manifests/tie1_instance_pin_targets.txt"
if grep -Eq '[{}]' "$WORK/$RUN_ID/manifests/tie1_instance_pin_targets.txt"; then
  exit 1
fi
SOURCE_HASH_AFTER="$(tree_hash "$SOURCE_CHECKPOINT")"
test "$SOURCE_HASH_BEFORE" = "$SOURCE_HASH_AFTER"

set +e
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/auth.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_bad_auth \
  --authorization WRONG_TOKEN \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/auth.stdout" 2>&1
AUTH_RC=$?
set -e
test "$AUTH_RC" -eq 2
grep -q 'exact private-copy filler-recycle authorization is required' "$TMP_ROOT/auth.stdout"
test ! -e "$WORK/tie1_trial_bad_auth"

cp -p "$WORK/$PROBE_ID/reports/tie_flagged_term_inventory.tsv" \
  "$TMP_ROOT/tie_flagged_term_inventory.good.tsv"
sed -i '$d' "$WORK/$PROBE_ID/reports/tie_flagged_term_inventory.tsv"
set +e
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/stale.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_stale_probe \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/stale.stdout" 2>&1
STALE_RC=$?
set -e
test "$STALE_RC" -eq 4
grep -q 'live Step 6R artifact differs from published evidence' "$TMP_ROOT/stale.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/stale.stdout"
test ! -e "$WORK/tie1_trial_stale_probe"
cp -p "$TMP_ROOT/tie_flagged_term_inventory.good.tsv" \
  "$WORK/$PROBE_ID/reports/tie_flagged_term_inventory.tsv"

cp -p "$WORK/$FAILED_TRIAL_ID/reports/tie1_trial_baseline_check_place.rpt" \
  "$TMP_ROOT/tie1_trial_baseline_check_place.good.rpt"
sed -i 's/907533\/907533/907532\/907533/' \
  "$WORK/$FAILED_TRIAL_ID/reports/tie1_trial_baseline_check_place.rpt"
set +e
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/stale-failed-trial.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_stale_failed_trial \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/stale-failed-trial.stdout" 2>&1
STALE_FAILED_TRIAL_RC=$?
set -e
test "$STALE_FAILED_TRIAL_RC" -eq 4
grep -q 'live Step 7I artifact differs from published evidence' \
  "$TMP_ROOT/stale-failed-trial.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/stale-failed-trial.stdout"
test ! -e "$WORK/tie1_trial_stale_failed_trial"
cp -p "$TMP_ROOT/tie1_trial_baseline_check_place.good.rpt" \
  "$WORK/$FAILED_TRIAL_ID/reports/tie1_trial_baseline_check_place.rpt"

TRACKED_FLAGGED_REL="MPTDC/docs/server_snapshots/innovus/$PROBE_ID/reports/tie_flagged_term_inventory.tsv"
git -C "$REPO" update-index --assume-unchanged "$TRACKED_FLAGGED_REL"
sed -i '92cHIGH\t{u_sink[001]/SN}\t{u_sink[001]}\tDFRSJIHDX1\tSN\t0x0' \
  "$WORK/$PROBE_ID/reports/tie_flagged_term_inventory.tsv"
cp -p "$WORK/$PROBE_ID/reports/tie_flagged_term_inventory.tsv" \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$PROBE_ID/reports/tie_flagged_term_inventory.tsv"
set +e
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/duplicate.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_duplicate_targets \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/duplicate.stdout" 2>&1
DUPLICATE_RC=$?
set -e
test "$DUPLICATE_RC" -eq 1
grep -qx 'INSTANCE_PIN_INPUT_GENERATION_STATUS=FAIL' \
  "$WORK/tie1_trial_duplicate_targets/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/duplicate.stdout"
cp -p "$TMP_ROOT/tie_flagged_term_inventory.good.tsv" \
  "$WORK/$PROBE_ID/reports/tie_flagged_term_inventory.tsv"
cp -p "$TMP_ROOT/tie_flagged_term_inventory.good.tsv" \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$PROBE_ID/reports/tie_flagged_term_inventory.tsv"
git -C "$REPO" update-index --no-assume-unchanged "$TRACKED_FLAGGED_REL"

set +e
MPTDC_TEST_MUTATE_SAFE_COPY=1 \
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/mutation.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_mutated_copy \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/mutation.stdout" 2>&1
MUTATION_RC=$?
set -e
test "$MUTATION_RC" -eq 1
grep -qx 'SAFE_INPUT_READ_ONLY_STATUS=FAIL' \
  "$WORK/tie1_trial_mutated_copy/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/mutation.stdout"
test "$SOURCE_HASH_BEFORE" = "$(tree_hash "$SOURCE_CHECKPOINT")"

set +e
MPTDC_TEST_ZERO_EFFECT=1 \
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/zero-effect.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_zero_effect \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/zero-effect.stdout" 2>&1
ZERO_EFFECT_RC=$?
set -e
test "$ZERO_EFFECT_RC" -eq 1
grep -qx 'ADD_TIE_STATUS=PASS' \
  "$WORK/tie1_trial_zero_effect/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'ADD_TIE_EFFECT_STATUS=FAIL' \
  "$WORK/tie1_trial_zero_effect/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/zero-effect.stdout"
test "$SOURCE_HASH_BEFORE" = "$(tree_hash "$SOURCE_CHECKPOINT")"

set +e
MPTDC_TEST_DELETE_EFFECT=1 \
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/delete-effect.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_bad_delete_effect \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/delete-effect.stdout" 2>&1
DELETE_EFFECT_RC=$?
set -e
test "$DELETE_EFFECT_RC" -eq 1
grep -qx 'FILLER_DELETE_EFFECT_STATUS=FAIL' \
  "$WORK/tie1_trial_bad_delete_effect/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FILLER_COUNT_POST_DELETE=1' \
  "$WORK/tie1_trial_bad_delete_effect/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/delete-effect.stdout"
test "$SOURCE_HASH_BEFORE" = "$(tree_hash "$SOURCE_CHECKPOINT")"

set +e
MPTDC_TEST_REFILL_FAIL=1 \
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/refill-fail.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_refill_fail \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/refill-fail.stdout" 2>&1
REFILL_FAIL_RC=$?
set -e
test "$REFILL_FAIL_RC" -eq 1
grep -qx 'FILLER_REFILL_STATUS=FAIL' \
  "$WORK/tie1_trial_refill_fail/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'FINAL_SITE_OCCUPANCY_STATUS=FAIL' \
  "$WORK/tie1_trial_refill_fail/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/refill-fail.stdout"
test "$SOURCE_HASH_BEFORE" = "$(tree_hash "$SOURCE_CHECKPOINT")"

set +e
MPTDC_TEST_NONFILLER_CHANGE=1 \
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/nonfiller-change.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_nonfiller_change \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/nonfiller-change.stdout" 2>&1
NONFILLER_CHANGE_RC=$?
set -e
test "$NONFILLER_CHANGE_RC" -eq 1
grep -qx 'NONFILLER_FINGERPRINT_STATUS=FAIL' \
  "$WORK/tie1_trial_nonfiller_change/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/nonfiller-change.stdout"
test "$SOURCE_HASH_BEFORE" = "$(tree_hash "$SOURCE_CHECKPOINT")"

set +e
MPTDC_TEST_ALTERNATE_TIE=1 \
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/alternate.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_alternate_master \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/alternate.stdout" 2>&1
ALTERNATE_RC=$?
set -e
test "$ALTERNATE_RC" -eq 1
grep -qx 'TARGET_HIGH_INSTANCE_DELTA=11' \
  "$WORK/tie1_trial_alternate_master/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'ALTERNATE_TIE_MASTER_DELTA=1' \
  "$WORK/tie1_trial_alternate_master/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/alternate.stdout"
test "$SOURCE_HASH_BEFORE" = "$(tree_hash "$SOURCE_CHECKPOINT")"

set +e
MPTDC_TEST_UNUSED_TARGET_TIE=1 \
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/unused-target.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_unused_target_cell \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/unused-target.stdout" 2>&1
UNUSED_TARGET_RC=$?
set -e
test "$UNUSED_TARGET_RC" -eq 1
grep -qx 'FINAL_TIE_NET_COUNT=12' \
  "$WORK/tie1_trial_unused_target_cell/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'TARGET_HIGH_INSTANCE_DELTA=13' \
  "$WORK/tie1_trial_unused_target_cell/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/unused-target.stdout"
test "$SOURCE_HASH_BEFORE" = "$(tree_hash "$SOURCE_CHECKPOINT")"

set +e
MPTDC_TEST_MARKER_MISMATCH=1 \
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/marker-mismatch.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_marker_mismatch \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/marker-mismatch.stdout" 2>&1
MARKER_MISMATCH_RC=$?
set -e
test "$MARKER_MISMATCH_RC" -eq 1
grep -qx 'DRC_MARKER_SIGNATURE_MATCH_STATUS=FAIL' \
  "$WORK/tie1_trial_marker_mismatch/reports/operator_gate_tie1_insertion_trial.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/marker-mismatch.stdout"
test "$SOURCE_HASH_BEFORE" = "$(tree_hash "$SOURCE_CHECKPOINT")"

set +e
MPTDC_TEST_TRIAL_FAIL=1 \
MPTDC_TIE1_TRIAL_REPO_ROOT="$REPO" \
MPTDC_TIE1_TRIAL_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_TRIAL_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/fail.publish.args" \
bash "$DRIVER" \
  --probe-run-id "$PROBE_ID" \
  --source-failed-trial-run-id "$FAILED_TRIAL_ID" \
  --run-id tie1_trial_tool_fail \
  --authorization EXACT_MPTDC_TIE1_FILLER_RECYCLE_TRIAL \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/fail.stdout" 2>&1
FAIL_RC=$?
set -e
test "$FAIL_RC" -eq 1
grep -qx 'INNOVUS_RC=1' "$TMP_ROOT/fail.stdout"
grep -qx 'TIE1_INSERTION_TRIAL_STATUS=FAIL' "$TMP_ROOT/fail.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/fail.stdout"
grep -q 'TIE1_INSERTION_TRIAL' "$TMP_ROOT/fail.publish.args"
test "$SOURCE_HASH_BEFORE" = "$(tree_hash "$SOURCE_CHECKPOINT")"

tclsh <<EOF
set fh [open "$TRIAL_TCL" r]
set data [read \$fh]
close \$fh
if {![info complete \$data]} { exit 1 }
EOF

MPTDC_TEST_TRIAL_TCL="$TRIAL_TCL" \
MPTDC_TEST_INSTANCE_TARGETS="$WORK/$RUN_ID/manifests/tie1_instance_pin_targets.txt" \
tclsh <<'EOF'
set fh [open $::env(MPTDC_TEST_TRIAL_TCL) r]
set data [read $fh]
close $fh
set start [string first "proc mptdc_tie1_trial_canonical_name" $data]
set end [string first "\nproc mptdc_tie1_trial_master_instances" $data $start]
eval [string range $data $start [expr {$end - 1}]]
if {[mptdc_tie1_trial_canonical_name {{u_sink[001]/D}}] ne
    {u_sink[001]/D}} { exit 1 }
set targets [mptdc_tie1_trial_read_instance_pin_targets \
    $::env(MPTDC_TEST_INSTANCE_TARGETS)]
if {[dict get $targets status] ne "PASS" ||
    [dict get $targets count] != 91 ||
    [dict get $targets unique_count] != 91 ||
    [dict get $targets invalid_count] != 0} { exit 1 }
EOF

cat > "$TMP_ROOT/marker_a.tsv" <<'EOF'
idx	marker_handle	box	layer	type	subType	message
1	0xaaa	{9 9 9 9}	MET3	Antenna	AntSAreaRatio	Ignored antenna A
2	0xaab	{1 2 3 4}	MET1	Geometry	Minimal_Area	Net n
EOF
cat > "$TMP_ROOT/marker_b.tsv" <<'EOF'
idx	marker_handle	box	layer	type	subType	message
8	0xbba	{8 8 8 8}	METTP	Connectivity	ConnectivityAntenna	Ignored connectivity B
9	0xbbb	{1 2 3 4}	MET1	Geometry	Minimal_Area	Net n
EOF
cat > "$TMP_ROOT/report_route_zero.rpt" <<'EOF'
#num needed restored net=0
#need_extraction net=0 (total=16329)
EOF
cat > "$TMP_ROOT/report_route_nonzero.rpt" <<'EOF'
#num needed restored net=1
#need_extraction net=0 (total=16329)
EOF
MPTDC_TEST_TRIAL_TCL="$TRIAL_TCL" \
MPTDC_TEST_MARKER_A="$TMP_ROOT/marker_a.tsv" \
MPTDC_TEST_MARKER_B="$TMP_ROOT/marker_b.tsv" \
MPTDC_TEST_REPORT_ROUTE="$TMP_ROOT/report_route_zero.rpt" \
MPTDC_TEST_REPORT_ROUTE_NONZERO="$TMP_ROOT/report_route_nonzero.rpt" \
tclsh <<'EOF'
set fh [open $::env(MPTDC_TEST_TRIAL_TCL) r]
set data [read $fh]
close $fh
set start [string first "proc mptdc_tie1_trial_marker_signature" $data]
set end [string first "\nproc mptdc_tie1_trial_snapshot_equal_debt" $data $start]
eval [string range $data $start [expr {$end - 1}]]
set a [mptdc_tie1_trial_marker_signature $::env(MPTDC_TEST_MARKER_A)]
set b [mptdc_tie1_trial_marker_signature $::env(MPTDC_TEST_MARKER_B)]
if {$a ne $b || [llength $a] != 1} { exit 1 }
set snapshot [dict create \
    report_route_rpt $::env(MPTDC_TEST_REPORT_ROUTE) \
    unrouted UNKNOWN \
    regular_bad 0 \
    special_bad 1 \
    special_raw_bad 1 \
    special_non_ro_failures 0]
set normalized [mptdc_tie1_trial_normalize_snapshot_unrouted $snapshot]
if {[dict get $normalized unrouted] ne "0" ||
    [dict get $normalized report_route_zero] != 1} { exit 1 }
dict set snapshot report_route_rpt $::env(MPTDC_TEST_REPORT_ROUTE_NONZERO)
set rejected [mptdc_tie1_trial_normalize_snapshot_unrouted $snapshot]
if {[dict get $rejected unrouted] ne "UNKNOWN" ||
    [dict get $rejected report_route_zero] != 0} { exit 1 }
EOF

echo "MPTDC_TIE1_INSERTION_TRIAL_DRIVER_TEST=PASS"
