#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_ro6_vss_via_trial.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_ID=20260831_175532_mptdc_tie1_minarea_clearance_v13_replay
BOUNDARY_ID=boundary_two_vss_opens
DRIVER="$REPO/MPTDC/pnr/scripts/server_run_mptdc_ro6_vss_via_trial.sh"
LAUNCHER="$TMP_ROOT/launcher_stub.sh"
PUBLISHER="$TMP_ROOT/publisher_stub.sh"
SOURCE_CHECKPOINT="$WORK/$SOURCE_ID/checkpoints/repaired_route.enc.dat"
SOURCE_GATE_NAME=operator_gate_tie1_minarea_endext_replay.rpt

tree_hash() {
  local root="$1"
  (
    cd "$root"
    find -L . -type f ! -name '*.cdslck' ! -name '*.lock' ! -name '.*lock*' \
      -print0 | LC_ALL=C sort -z |
      while IFS= read -r -d '' file; do
        printf '%s\t' "$file"
        sha256sum "$file"
      done
  ) | sha256sum | awk '{print $1}'
}

mkdir -p "$REPO/MPTDC/pnr/scripts/commands" \
  "$REPO/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_ID/reports" \
  "$REPO/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_ID/manifests" \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$SOURCE_ID/reports" \
  "$WORK/$BOUNDARY_ID/reports" "$WORK/$BOUNDARY_ID/manifests" \
  "$WORK/$SOURCE_ID/reports" "$SOURCE_CHECKPOINT"

cp -p "$PNR_DIR/server_run_mptdc_ro6_vss_via_trial.sh" "$DRIVER"
cp -p "$PNR_DIR/innovus_mptdc_ro6_vss_via_checkpoint_tools.tcl" \
  "$REPO/MPTDC/pnr/scripts/"
cp -p "$PNR_DIR/commands/mptdc_ro6_vss_via_trial.tcl" \
  "$REPO/MPTDC/pnr/scripts/commands/"
printf 'accepted V13 checkpoint fixture\n' > "$SOURCE_CHECKPOINT/design.bin"
SOURCE_SHA="$(tree_hash "$SOURCE_CHECKPOINT")"

cat > "$WORK/$SOURCE_ID/reports/$SOURCE_GATE_NAME" <<EOF
STEP=TIE1_MINAREA_ENDEXT_REPLAY
REPAIR_REVISION=V13
FINAL_DRC=0
FINAL_SHORTS=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
FINAL_SPECIAL_DANGLING_COUNT=15
CANDIDATE_CHECKPOINT=$SOURCE_CHECKPOINT
CANDIDATE_CHECKPOINT_SHA256=$SOURCE_SHA
CANDIDATE_CHECKPOINT_STATUS=PASS
DECISION=PASS_CONTINUE
EOF
cp -p "$WORK/$SOURCE_ID/reports/$SOURCE_GATE_NAME" \
  "$REPO/MPTDC/docs/server_snapshots/innovus/$SOURCE_ID/reports/"

cat > "$WORK/$BOUNDARY_ID/manifests/pvs_input_hashes.rpt" <<EOF
SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT
MERGED_GDS_SHA256=5420191274e657c0c02a019fc56d90f034ab48b76134692a5ff7918e53d7363d
EOF
cat > "$WORK/$BOUNDARY_ID/reports/operator_gate_pvs_ro6_boundary_lvs.rpt" <<'EOF'
STEP=PVS_RO6_BOUNDARY_LVS
STATUS=FAIL
PVS_LVS_STATUS=MISMATCH
PVS_RC=0
LVS_BLACKBOX_RULE_STATUS=PASS
LVS_BLACKBOX_APPLICATION_STATUS=PASS
LVS_BLACKBOXED_CELL_COUNT=1
LVS_BLACKBOX_CLS_PATH_STATUS=PASS
TOP_INITIAL_PINS=59:59
TOP_COMPARE_PINS=59:59
TOP_CELL_STATUS=mismatch
LVS_BUS_PIN_MAP_RULE_STATUS=NOT_USED_EXACT_SCALAR_SOURCE
LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=PASS
RO6_BLACKBOX_CELL_MATCH_STATUS=PASS
RO6_BLACKBOX_INITIAL_PINS=19:19
RO6_BLACKBOX_COMPARE_PINS=19:19
RO6_BLACKBOX_CELL_STATUS=match
RO6_ANGLE_BUS_MISSING_PIN_COUNT=0
RO6_SQUARE_BUS_MISSING_PIN_COUNT=0
TIE1_UNMATCHED_PIN_COUNT=0
TIE1_MISMATCHED_NET_COUNT=0
TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT=0
LAYOUT_OPEN_NET_COUNT=2
SHORTS_OPENS_RECORD_COUNT=1
MISMATCHED_NET_RECORD_COUNT=0
MISMATCHED_INSTANCE_RECORD_COUNT=0
VDD_OPEN_SECTION_COUNT=0
VSS_OPEN_SECTION_COUNT=1
BOUNDARY_REMAINDER_CLASS=TOP_CONNECTIVITY_MISMATCH
DECISION=FAIL_STOP
EOF
cp -p "$WORK/$BOUNDARY_ID/manifests/pvs_input_hashes.rpt" \
  "$REPO/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_ID/manifests/"
cp -p "$WORK/$BOUNDARY_ID/reports/operator_gate_pvs_ro6_boundary_lvs.rpt" \
  "$REPO/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_ID/reports/"

cat > "$LAUNCHER" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
run_id=""
work=""
checkpoint=""
commands=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) run_id="$2"; shift 2 ;;
    --innovus-work) work="$2"; shift 2 ;;
    --checkpoint) checkpoint="$2"; shift 2 ;;
    --commands-file) commands="$2"; shift 2 ;;
    --expected-head) shift 2 ;;
    *) echo "unexpected option: $1" >&2; exit 8 ;;
  esac
done
[[ -d "$checkpoint" && -s "$commands" ]]
[[ "${MPTDC_RO6_VSS_VIA_AUTHORIZATION:-}" == EXACT_V13_TWO_RO6_VSS_MET1_METTP_VIA_STACKS_V1 ]]
mkdir -p "$work/$run_id/reports" "$work/$run_id/checkpoints/repaired_route.enc.dat"
printf 'candidate with two VSS via stacks\n' > "$work/$run_id/checkpoints/repaired_route.enc.dat/design.bin"
cat > "$work/$run_id/reports/ro6_vss_via_repair_status.rpt" <<'RPT'
AUTHORIZATION_STATUS=PASS
PREFLIGHT_STATUS=PASS
GEOMETRY_CONTRACT_STATUS=PASS
RESOLVED_SITE_COUNT=2
VIA_ATTEMPTS=2
VIA_SUCCESSES=2
VDD_SWIRE_FINGERPRINT_STATUS=UNCHANGED
VSS_SWIRE_FINGERPRINT_STATUS=UNCHANGED
VDD_VIA_FINGERPRINT_STATUS=UNCHANGED
VSS_VIA_ADDED_COUNT=6
VSS_VIA_REMOVED_COUNT=0
SITE_1_NEW_LOCAL_VIA_COUNT=3
SITE_1_VIA_EFFECT_STATUS=PASS
SITE_2_NEW_LOCAL_VIA_COUNT=3
SITE_2_VIA_EFFECT_STATUS=PASS
RO6_VSS_VIA_REPAIR_STATUS=PASS_PVS_CANDIDATE
RPT
cat > "$work/$run_id/reports/checkpoint_repair_status.rpt" <<'RPT'
COMMAND_1_STATUS=PASS
INITIAL_DRC=0
FINAL_DRC=0
INITIAL_SHORTS=0
FINAL_SHORTS=0
INITIAL_REGULAR_CONNECTIVITY_BAD=0
FINAL_REGULAR_CONNECTIVITY_BAD=0
INITIAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
FINAL_SPECIAL_CONNECTIVITY_RAW_BAD=1
INITIAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=0
CHECKPOINT_REPAIR_STATUS=PASS_GEOMETRY_REVIEW_CONNECTIVITY
FINAL_CHECKPOINT_DAT_EXISTS=1
RPT
EOF

cat > "$PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MPTDC_TEST_PUBLISH_ARGS:?}"
exit 0
EOF
chmod +x "$LAUNCHER" "$PUBLISHER" "$DRIVER"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC RO6 VSS via test'
git -C "$REPO" config user.email 'mptdc-ro6-vss-via@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"
git -C "$REPO" update-ref refs/remotes/origin/SPADMIC_test "$HEAD_SHA"

RUN_ID=ro6_vss_via_pass
MPTDC_RO6_VSS_VIA_REPO_ROOT="$REPO" \
MPTDC_RO6_VSS_VIA_LAUNCHER="$LAUNCHER" \
MPTDC_RO6_VSS_VIA_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish.args" \
bash "$DRIVER" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --run-id "$RUN_ID" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'RO6_VSS_VIA_TRIAL_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'VIA_ATTEMPTS=2' "$TMP_ROOT/pass.stdout"
grep -qx 'VIA_SUCCESSES=2' "$TMP_ROOT/pass.stdout"
grep -qx 'FINAL_DRC=0' "$TMP_ROOT/pass.stdout"
grep -qx 'FINAL_SHORTS=0' "$TMP_ROOT/pass.stdout"
grep -qx 'PVS_LVS_STATUS=NOT_RUN_BY_SCOPE' "$TMP_ROOT/pass.stdout"
grep -qx 'SIGNOFF_ELIGIBLE=NO' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_PVS_CANDIDATE' "$TMP_ROOT/pass.stdout"
grep -qx 'NEXT_STAGE=PVS_RO6_VSS_VIA_CANDIDATE' "$TMP_ROOT/pass.stdout"
grep -q "innovus $RUN_ID $WORK/$RUN_ID RO6_VSS_VIA_TRIAL" "$TMP_ROOT/publish.args"
GATE="$WORK/$RUN_ID/reports/operator_gate_ro6_vss_via_trial.rpt"
grep -qx 'BOUNDARY_CLASS_STATUS=PASS_LEGACY_EXACT_COUNTS' "$GATE"
grep -qx 'VSS_VIA_ADDED_COUNT=6' "$GATE"
grep -qx 'VSS_VIA_REMOVED_COUNT=0' "$GATE"
grep -qx 'CANDIDATE_CHECKPOINT_STATUS=PASS' "$GATE"
grep -Eq '^CANDIDATE_CHECKPOINT_SHA256=[0-9a-f]{64}$' "$GATE"

printf '\nLAYOUT_OPEN_NET_COUNT=3\n' >> "$WORK/$BOUNDARY_ID/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"
set +e
MPTDC_RO6_VSS_VIA_REPO_ROOT="$REPO" \
MPTDC_RO6_VSS_VIA_LAUNCHER="$LAUNCHER" \
MPTDC_RO6_VSS_VIA_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/bad.publish.args" \
bash "$DRIVER" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --run-id ro6_vss_via_bad_evidence \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/bad.stdout" 2>&1
BAD_RC=$?
set -e
test "$BAD_RC" -eq 4
grep -Fq 'live boundary gate differs from snapshot' "$TMP_ROOT/bad.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/bad.stdout"
test ! -e "$WORK/ro6_vss_via_bad_evidence"

echo "MPTDC_RO6_VSS_VIA_TRIAL_DRIVER_TEST=PASS"
