#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DRIVER_SOURCE="$SOURCE_DIR/server_run_mptdc_ro6_density_after_boundary.sh"
CLASSIFIER_SOURCE="$SOURCE_DIR/12_classify_mptdc_density_delta.py"
TMP_ROOT="$(mktemp -d /tmp/mptdc_ro6_density_driver.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_ID=source_compositional
SOURCE_EVIDENCE_ID=source_compositional_04_lvs
BOUNDARY_ID=boundary_match
STANDALONE_ID=ro6_standalone_match
SOURCE_LIVE="$WORK/$SOURCE_ID"
SOURCE_SNAPSHOT="$REPO/MPTDC/docs/server_snapshots/pvs/$SOURCE_EVIDENCE_ID"
BOUNDARY_SNAPSHOT="$REPO/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_ID"
STANDALONE_SNAPSHOT="$REPO/MPTDC/docs/server_snapshots/pvs/$STANDALONE_ID"
DRIVER="$REPO/MPTDC/scripts/pvs/server_run_mptdc_ro6_density_after_boundary.sh"
CLASSIFIER="$REPO/MPTDC/scripts/pvs/12_classify_mptdc_density_delta.py"

mkdir -p "$REPO/MPTDC/scripts/pvs" \
  "$SOURCE_SNAPSHOT/reports" \
  "$SOURCE_SNAPSHOT/manifests" \
  "$BOUNDARY_SNAPSHOT/reports" \
  "$STANDALONE_SNAPSHOT/reports" \
  "$STANDALONE_SNAPSHOT/manifests" \
  "$SOURCE_LIVE/outputs" "$SOURCE_LIVE/manifests" "$SOURCE_LIVE/reports" \
  "$SOURCE_LIVE/pvs_drc/base_script"
cp "$DRIVER_SOURCE" "$DRIVER"
cp "$CLASSIFIER_SOURCE" "$CLASSIFIER"
printf 'density fixture gds\n' > \
  "$SOURCE_LIVE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds"
GDS_SHA="$(sha256sum "$SOURCE_LIVE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds" | awk '{print $1}')"
RO_SHA="$(printf 'ro gds\n' | sha256sum | awk '{print $1}')"
RO_CDL_SHA="$(printf 'ro cdl\n' | sha256sum | awk '{print $1}')"

cat > "$SOURCE_LIVE/reports/pvs_drc_base_nonzero_rules.tsv" <<'EOF'
rule	primary	expanded
R1M2P1	6	6
R1M3P1	34	34
R2M2P1	41	41
R2M3P1	55	55
EOF
BASE_RULE_SHA="$(sha256sum "$SOURCE_LIVE/reports/pvs_drc_base_nonzero_rules.tsv" | awk '{print $1}')"
cat > "$SOURCE_LIVE/reports/pvs_drc_base_status.rpt" <<EOF
STATUS=FAIL
PVS_DRC_STATUS=FAIL
PVS_DRC_VARIANT=BASE
PVS_RC=0
DRC_TOTAL_PRIMARY=136
DRC_TOTAL_EXPANDED=136
NONZERO_RULE_COUNT=4
NONZERO_RULE_REPORT=$SOURCE_LIVE/reports/pvs_drc_base_nonzero_rules.tsv
NONZERO_RULE_REPORT_SHA256=$BASE_RULE_SHA
LAYOUT_INPUT_SHA256=$GDS_SHA
EOF
cat > "$SOURCE_LIVE/manifests/pvs_input_hashes.rpt" <<EOF
MERGED_GDS=$SOURCE_LIVE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds
MERGED_GDS_SHA256=$GDS_SHA
EOF
printf 'density template\n' > "$SOURCE_LIVE/pvs_drc/base_script/run.pvs"

cat > "$SOURCE_SNAPSHOT/reports/pvs_recovery_base_drc_classification.rpt" <<EOF
STEP=MPTDC_RECOVERY_BASE_DRC_CLASSIFICATION
CLASSIFICATION_CONTEXT=RECOVERY_ANTENNA_EXCEPTION
CLASSIFICATION_STATUS=PASS
PVS_BASE_DRC_CLASS=ANTENNA_ONLY_MANAGER_EXCEPTION
NON_ANTENNA_RULE_COUNT=0
LAYOUT_INPUT_SHA256=$GDS_SHA
RULE_REPORT_SHA256=$BASE_RULE_SHA
ANTENNA_REPAIR_ATTEMPTED=NO
SIGNOFF_ELIGIBLE=NO
EOF
cat > "$SOURCE_SNAPSHOT/manifests/pvs_recovery_base_drc_classification_scope.rpt" <<EOF
PVS_RUN_CLASS=DIAGNOSTIC_COMPOSITIONAL_NOT_SIGNOFF
DIAGNOSTIC_SCOPE=BASE_DRC_PLUS_RAW_LVS_FOR_COMPOSITIONAL_PROOF
CLASSIFICATION_CONTEXT=RECOVERY_ANTENNA_EXCEPTION
BASE_DRC_CLASS=ANTENNA_ONLY_MANAGER_EXCEPTION
DENSITY_DRC_STATUS=NOT_RUN_BY_SCOPE
ANTENNA_REPAIR_ATTEMPTED=NO
ALLOWED_ANTENNA_RULE_SET=R1M2P1,R1M3P1,R2M2P1,R2M3P1
BASE_DRC_LAYOUT_SHA256=$GDS_SHA
BASE_DRC_RULE_REPORT_SHA256=$BASE_RULE_SHA
SIGNOFF_ELIGIBLE=NO
EOF
cat > "$SOURCE_SNAPSHOT/manifests/pvs_diagnostic_scope.rpt" <<'EOF'
PVS_RUN_CLASS=DIAGNOSTIC_COMPOSITIONAL_NOT_SIGNOFF
DIAGNOSTIC_SCOPE=BASE_DRC_PLUS_RAW_LVS
DIAGNOSTIC_ANTENNA_EXCEPTION=1
DIAGNOSTIC_RO_COMPOSITIONAL=1
RUN_DENSITY_AFTER_LVS=0
DEFERRED_INNOVUS_DRC_COUNT=0
DEFERRED_INNOVUS_DRC_RULE=NONE
DEFERRED_INNOVUS_DRC_NET=NONE
DENSITY_DRC_STATUS=NOT_RUN_BY_SCOPE
SIGNOFF_ELIGIBLE=NO
EOF
cat > "$SOURCE_SNAPSHOT/reports/operator_gate_pvs_lvs.rpt" <<'EOF'
PVS_RUN_CLASS=DIAGNOSTIC_COMPOSITIONAL_NOT_SIGNOFF
DIAGNOSTIC_RO_COMPOSITIONAL=1
LVS_RC=8
STATUS=FAIL
PVS_LVS_STATUS=MISMATCH
PVS_RC=0
RAW_FULL_TOP_LVS_STATUS=MISMATCH_PENDING_BOUNDARY_PROOF
SIGNOFF_ELIGIBLE=NO
DECISION=DIAGNOSTIC_RAW_MISMATCH_COLLECTED
EOF
cat > "$SOURCE_SNAPSHOT/README.md" <<EOF
- Run ID: \`$SOURCE_EVIDENCE_ID\`
- Source directory: \`$SOURCE_LIVE\`
EOF
cat > "$BOUNDARY_SNAPSHOT/reports/operator_gate_pvs_compositional_lvs.rpt" <<EOF
PVS_RUN_CLASS=DIAGNOSTIC_COMPOSITIONAL_NOT_SIGNOFF
SOURCE_PVS_RUN_ID=$SOURCE_ID
BOUNDARY_PVS_RUN_ID=$BOUNDARY_ID
STANDALONE_PVS_RUN_ID=$STANDALONE_ID
RAW_FULL_TOP_LVS_STATUS=MISMATCH_RO_ABSTRACTION_ONLY
PVS_TOP_BOUNDARY_LVS=MATCH
PVS_RO6_STANDALONE_LVS=MATCH
COMPOSITIONAL_LVS_STATUS=PASS
MERGED_GDS_SHA256=$GDS_SHA
RO_GDS_SHA256=$RO_SHA
RO_CDL_SHA256=$RO_CDL_SHA
ANTENNA_REPAIR_ATTEMPTED=NO
SIGNOFF_ELIGIBLE=NO
FINAL_SIGNOFF=NO
READY_FOR_TAPEOUT=NO
DECISION=PASS_DENSITY_CONTINUE
NEXT_STAGE=PVS_DRC_DENSITY
EOF
cat > "$STANDALONE_SNAPSHOT/reports/operator_gate_pvs_ro6_standalone_lvs.rpt" <<'EOF'
PVS_LVS=MATCH
DECISION=PASS_CONTINUE
OA_READ_ONLY_STATUS=PASS
RO6_CDL_PIN_CONTRACT_STATUS=PASS
SIGNOFF_ELIGIBLE=NO
EOF
cat > "$STANDALONE_SNAPSHOT/manifests/ro6_standalone_lvs_inputs.rpt" <<EOF
RO_GDS_SHA256=$RO_SHA
RO_CDL_SHA256=$RO_CDL_SHA
EOF

FAKE_DRC="$TMP_ROOT/fake_drc.sh"
cat > "$FAKE_DRC" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
prepared=""
variant=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prepared-dir) prepared="$2"; shift 2 ;;
    --variant) variant="$2"; shift 2 ;;
    *) shift ;;
  esac
done
test "$variant" = density
printf '%s\n' "$variant" >> "$FAKE_DRC_CALLS"
rules="$prepared/reports/pvs_drc_density_nonzero_rules.tsv"
cat > "$rules" <<'RULES'
rule	primary	expanded
R1M2P1	6	6
R1M3P1	34	34
R2M2P1	41	41
R2M3P1	55	55
RULES
if [[ "${FAKE_DENSITY_DEBT:-0}" == 1 ]]; then
  printf 'DENSITY.M1\t3\t3\n' >> "$rules"
fi
if [[ "${FAKE_ANTENNA_DRIFT:-0}" == 1 ]]; then
  sed -i 's/^R1M2P1\t6\t6$/R1M2P1\t7\t7/' "$rules"
fi
rule_sha="$(sha256sum "$rules" | awk '{print $1}')"
primary="$(awk -F '\t' 'NR > 1 { total += $2 } END { print total + 0 }' "$rules")"
expanded="$(awk -F '\t' 'NR > 1 { total += $3 } END { print total + 0 }' "$rules")"
count="$(awk 'END { print NR - 1 }' "$rules")"
layout_sha="$(sed -n 's/^MERGED_GDS_SHA256=//p' "$prepared/manifests/pvs_input_hashes.rpt")"
cat > "$prepared/reports/pvs_drc_density_status.rpt" <<RPT
STATUS=FAIL
PVS_DRC_STATUS=FAIL
PVS_DRC_VARIANT=DENSITY
PVS_RC=0
DRC_TOTAL_PRIMARY=$primary
DRC_TOTAL_EXPANDED=$expanded
NONZERO_RULE_COUNT=$count
NONZERO_RULE_REPORT=$rules
NONZERO_RULE_REPORT_SHA256=$rule_sha
LAYOUT_INPUT_SHA256=$layout_sha
RPT
exit 9
EOF

FAKE_PUBLISHER="$TMP_ROOT/fake_publisher.sh"
cat > "$FAKE_PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FAKE_PUBLISH_CALLS"
exit 0
EOF
chmod +x "$DRIVER" "$CLASSIFIER" "$FAKE_DRC" "$FAKE_PUBLISHER"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC density test'
git -C "$REPO" config user.email 'mptdc-density@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

run_density() {
  local run_id="$1" drc_calls="$2" publish_calls="$3"
  shift 3
  env MPTDC_DENSITY_REPO_ROOT="$REPO" \
    MPTDC_DENSITY_DRC_REPLAY="$FAKE_DRC" \
    MPTDC_DENSITY_CLASSIFIER="$CLASSIFIER" \
    MPTDC_DENSITY_PUBLISHER="$FAKE_PUBLISHER" \
    MPTDC_INNOVUS_WORK="$WORK" \
    FAKE_DRC_CALLS="$drc_calls" FAKE_PUBLISH_CALLS="$publish_calls" \
    "$@" \
    bash "$DRIVER" --source-pvs-run-id "$SOURCE_ID" \
      --source-pvs-evidence-id "$SOURCE_EVIDENCE_ID" \
      --boundary-pvs-run-id "$BOUNDARY_ID" \
      --standalone-pvs-run-id "$STANDALONE_ID" \
      --run-id "$run_id" --expected-head "$HEAD_SHA"
}

CLEAN_DRC_CALLS="$TMP_ROOT/clean.drc.calls"
CLEAN_PUBLISH_CALLS="$TMP_ROOT/clean.publish.calls"
run_density density_clean "$CLEAN_DRC_CALLS" "$CLEAN_PUBLISH_CALLS" \
  > "$TMP_ROOT/clean.stdout"
grep -qx 'PVS_DENSITY_PREFLIGHT=PASS' "$TMP_ROOT/clean.stdout"
grep -qx 'PVS_DRC_DENSITY_RAW_STATUS=FAIL' \
  "$WORK/density_clean/reports/operator_gate_pvs_drc_density.rpt"
grep -qx 'DENSITY_NON_ANTENNA_RULE_COUNT=0' \
  "$WORK/density_clean/reports/operator_gate_pvs_drc_density.rpt"
grep -qx 'DECISION=PASS_NON_ANTENNA_DENSITY_CLEAN' \
  "$WORK/density_clean/reports/operator_gate_pvs_drc_density.rpt"
grep -qx 'ANTENNA_REPAIR_ATTEMPTED=NO' \
  "$WORK/density_clean/reports/operator_gate_pvs_drc_density.rpt"
test "$(cat "$CLEAN_DRC_CALLS")" = density
test "$(wc -l < "$CLEAN_PUBLISH_CALLS")" -eq 1

DEBT_DRC_CALLS="$TMP_ROOT/debt.drc.calls"
DEBT_PUBLISH_CALLS="$TMP_ROOT/debt.publish.calls"
set +e
run_density density_debt "$DEBT_DRC_CALLS" "$DEBT_PUBLISH_CALLS" \
  FAKE_DENSITY_DEBT=1 > "$TMP_ROOT/debt.stdout"
DEBT_RC=$?
set -e
test "$DEBT_RC" -eq 1
grep -qx 'DENSITY_NON_ANTENNA_RULE_SET=DENSITY.M1' \
  "$WORK/density_debt/reports/operator_gate_pvs_drc_density.rpt"
grep -qx 'DECISION=FAIL_REVIEW_ATTRIBUTABLE_DENSITY_DEBT' \
  "$WORK/density_debt/reports/operator_gate_pvs_drc_density.rpt"
test "$(cat "$DEBT_DRC_CALLS")" = density
test "$(wc -l < "$DEBT_PUBLISH_CALLS")" -eq 1

sed -i "s/^MERGED_GDS_SHA256=$GDS_SHA$/MERGED_GDS_SHA256=$(printf drift | sha256sum | awk '{print $1}')/" \
  "$BOUNDARY_SNAPSHOT/reports/operator_gate_pvs_compositional_lvs.rpt"
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m boundary-hash-drift
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"
DRIFT_DRC_CALLS="$TMP_ROOT/drift.drc.calls"
DRIFT_PUBLISH_CALLS="$TMP_ROOT/drift.publish.calls"
set +e
run_density density_drift "$DRIFT_DRC_CALLS" "$DRIFT_PUBLISH_CALLS" \
  > "$TMP_ROOT/drift.stdout"
DRIFT_RC=$?
set -e
test "$DRIFT_RC" -eq 4
grep -qx 'PVS_DENSITY_PREFLIGHT=FAIL' "$TMP_ROOT/drift.stdout"
test ! -e "$DRIFT_DRC_CALLS"
test ! -e "$DRIFT_PUBLISH_CALLS"

echo 'MPTDC_RO6_DENSITY_AFTER_BOUNDARY_DRIVER_TEST=PASS'
