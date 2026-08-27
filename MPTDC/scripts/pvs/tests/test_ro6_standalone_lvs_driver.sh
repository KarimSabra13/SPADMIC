#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_ro6_standalone_lvs.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_ID=source_pvs_template
SOURCE_LVS="$WORK/$SOURCE_ID/pvs_lvs/source_lvs_script"
DRIVER="$REPO/MPTDC/scripts/pvs/server_run_mptdc_ro6_standalone_lvs.sh"
PVS_BIN="$TMP_ROOT/cadence/bin/pvs"
PUBLISHER="$TMP_ROOT/publisher_stub.sh"
CADENCE_ENV="$TMP_ROOT/cadence_env.sh"
FAILING_CADENCE_ENV="$TMP_ROOT/failing_cadence_env.sh"
OA_LAYOUT="$TMP_ROOT/oa/RO_tune6/layout"
OA_SCHEMATIC="$TMP_ROOT/oa/RO_tune6/schematic"
EXPORT_DIR="$TMP_ROOT/exports"
RO_GDS="$EXPORT_DIR/RO_tune6.gds"
RO_CDL="$EXPORT_DIR/RO_tune6.cdl"

mkdir -p "$REPO/MPTDC/scripts/pvs" "$SOURCE_LVS" "$(dirname "$PVS_BIN")" \
  "$OA_LAYOUT" "$OA_SCHEMATIC" "$EXPORT_DIR"
cp -p "$PVS_DIR/server_run_mptdc_ro6_standalone_lvs.sh" "$DRIVER"
printf 'oa layout fixture\n' > "$OA_LAYOUT/master.tag"
printf 'oa schematic fixture\n' > "$OA_SCHEMATIC/master.tag"
printf 'fresh RO GDS fixture\n' > "$RO_GDS"
cat > "$RO_CDL" <<'EOF'
.SUBCKT RO_tune6 VDD VSS rstb code<0> code<1> code<2> code<3>
+ code<4> code<5> code<6> code<7> S<0> S<1> S<2> S<3>
+ S<4> S<5> S<6> S<7>
M0 n0 rstb VSS VSS nch
.ENDS RO_tune6
EOF

cat > "$PVS_BIN" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p svdb
if [[ "${MPTDC_TEST_STANDALONE_RESULT:-match}" == match ]]; then
  cat > RO_tune6_lvs.sum.cls <<'RPT'
#####  Run Result                    :     MATCH
Cells that have been blackboxed              |         0
RPT
  printf 'matched\n' > svdb/matched
  exit 0
fi
if [[ "${MPTDC_TEST_STANDALONE_RESULT:-match}" == match_no_blackbox_count ]]; then
  cat > RO_tune6_lvs.sum.cls <<'RPT'
#####  Run Result                    :     MATCH
RPT
  printf 'matched\n' > svdb/matched
  exit 0
fi
cat > RO_tune6_lvs.sum.cls <<'RPT'
#####  Run Result                    :     MISMATCH
Cells that have been blackboxed              |         0
RPT
printf 'mismatched\n' > svdb/mismatched
exit 8
EOF
chmod +x "$PVS_BIN"

cat > "$CADENCE_ENV" <<'EOF'
#!/usr/bin/env bash
# Reproduce a site setup that expects nounset to be disabled while sourced.
: "$MPTDC_TEST_UNSET_SITE_VARIABLE"
export MPTDC_TEST_CADENCE_ENV_LOADED=1
EOF
printf 'return 23\n' > "$FAILING_CADENCE_ENV"

cat > "$SOURCE_LVS/run.pvs" <<EOF
#!/bin/sh -f
cd "$SOURCE_LVS" || exit 3
$PVS_BIN \\
  -lvs
EOF
cat > "$SOURCE_LVS/pvslvsctl" <<'EOF'
lvs_report_file "old.sum";
layout_format gdsii;
schematic_path "/old/source.v" verilog;
schematic_path "/old/cells.cdl" cdl;
layout_path "/old/layout.gds";
EOF
: > "$SOURCE_LVS/.config.rul"
printf 'technology fixture\n' > "$SOURCE_LVS/.technology.rul"

cat > "$PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MPTDC_TEST_PUBLISH_ARGS:?}"
exit 0
EOF
chmod +x "$PUBLISHER"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC RO6 standalone LVS test'
git -C "$REPO" config user.email 'mptdc-ro6-standalone@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

RUN_ID=ro6_standalone_pass
MPTDC_RO6_STANDALONE_REPO_ROOT="$REPO" \
MPTDC_RO6_STANDALONE_PUBLISHER="$PUBLISHER" \
MPTDC_RO6_STANDALONE_PREP="$PVS_DIR/07_prepare_ro6_standalone_lvs.py" \
MPTDC_RO6_STANDALONE_GATE="$PVS_DIR/08_gate_ro6_standalone_lvs.py" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/pass.publish.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --run-id "$RUN_ID" \
  --ro-gds "$RO_GDS" \
  --ro-cdl "$RO_CDL" \
  --oa-layout-dir "$OA_LAYOUT" \
  --oa-schematic-dir "$OA_SCHEMATIC" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'PVS_RO6_STANDALONE_RECOVERY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'PVS_LVS=MATCH' "$TMP_ROOT/pass.stdout"
grep -qx 'OA_READ_ONLY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'RO6_CDL_PIN_CONTRACT_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'CADENCE_ENV_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_CONTINUE' "$TMP_ROOT/pass.stdout"
grep -qx 'NEXT_STAGE=DIAGNOSTIC_PHYSICAL_PVS_WITH_FRESH_RO_GDS' "$TMP_ROOT/pass.stdout"
grep -q "pvs $RUN_ID $WORK/$RUN_ID PVS_RO6_STANDALONE_LVS" "$TMP_ROOT/pass.publish.args"
grep -qx 'SIGNOFF_ELIGIBLE=NO' "$WORK/$RUN_ID/reports/operator_gate_pvs_ro6_standalone_lvs.rpt"
cmp "$RO_GDS" "$WORK/$RUN_ID/inputs/RO_tune6.fresh.gds"
cmp "$RO_CDL" "$WORK/$RUN_ID/inputs/RO_tune6.fresh.cdl"

set +e
MPTDC_TEST_STANDALONE_RESULT=mismatch \
MPTDC_RO6_STANDALONE_REPO_ROOT="$REPO" \
MPTDC_RO6_STANDALONE_PUBLISHER="$PUBLISHER" \
MPTDC_RO6_STANDALONE_PREP="$PVS_DIR/07_prepare_ro6_standalone_lvs.py" \
MPTDC_RO6_STANDALONE_GATE="$PVS_DIR/08_gate_ro6_standalone_lvs.py" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/fail.publish.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --run-id ro6_standalone_mismatch \
  --ro-gds "$RO_GDS" \
  --ro-cdl "$RO_CDL" \
  --oa-layout-dir "$OA_LAYOUT" \
  --oa-schematic-dir "$OA_SCHEMATIC" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/fail.stdout" 2>&1
FAIL_RC=$?
set -e
test "$FAIL_RC" -ne 0
grep -qx 'PVS_RO6_STANDALONE_RECOVERY_STATUS=FAIL' "$TMP_ROOT/fail.stdout"
grep -qx 'PVS_LVS=NOT_PROVEN' "$TMP_ROOT/fail.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/fail.stdout"
grep -qx 'NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE' "$TMP_ROOT/fail.stdout"
grep -q 'PVS_RO6_STANDALONE_LVS' "$TMP_ROOT/fail.publish.args"

set +e
MPTDC_TEST_STANDALONE_RESULT=match_no_blackbox_count \
MPTDC_RO6_STANDALONE_REPO_ROOT="$REPO" \
MPTDC_RO6_STANDALONE_PUBLISHER="$PUBLISHER" \
MPTDC_RO6_STANDALONE_PREP="$PVS_DIR/07_prepare_ro6_standalone_lvs.py" \
MPTDC_RO6_STANDALONE_GATE="$PVS_DIR/08_gate_ro6_standalone_lvs.py" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/missing_blackbox.publish.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --run-id ro6_standalone_missing_blackbox_count \
  --ro-gds "$RO_GDS" \
  --ro-cdl "$RO_CDL" \
  --oa-layout-dir "$OA_LAYOUT" \
  --oa-schematic-dir "$OA_SCHEMATIC" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/missing_blackbox.stdout" 2>&1
MISSING_BLACKBOX_RC=$?
set -e
test "$MISSING_BLACKBOX_RC" -ne 0
grep -qx 'BLACKBOXED_CELL_COUNT=MISSING' \
  "$WORK/ro6_standalone_missing_blackbox_count/reports/pvs_ro6_standalone_lvs_status.rpt"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/missing_blackbox.stdout"

set +e
MPTDC_RO6_STANDALONE_REPO_ROOT="$REPO" \
MPTDC_RO6_STANDALONE_PUBLISHER="$PUBLISHER" \
MPTDC_RO6_STANDALONE_PREP="$PVS_DIR/07_prepare_ro6_standalone_lvs.py" \
MPTDC_RO6_STANDALONE_GATE="$PVS_DIR/08_gate_ro6_standalone_lvs.py" \
MPTDC_CADENCE_ENV="$FAILING_CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/env_fail.publish.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --run-id ro6_standalone_env_fail \
  --ro-gds "$RO_GDS" \
  --ro-cdl "$RO_CDL" \
  --oa-layout-dir "$OA_LAYOUT" \
  --oa-schematic-dir "$OA_SCHEMATIC" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/env_fail.stdout" 2>&1
ENV_FAIL_RC=$?
set -e
test "$ENV_FAIL_RC" -ne 0
grep -qx 'CADENCE_ENV_RC=23' "$TMP_ROOT/env_fail.stdout"
grep -qx 'CADENCE_ENV_STATUS=FAIL' "$TMP_ROOT/env_fail.stdout"
grep -qx 'PVS_RC=99' "$TMP_ROOT/env_fail.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/env_fail.stdout"
grep -qx 'CADENCE_ENV_STATUS=FAIL' \
  "$WORK/ro6_standalone_env_fail/reports/operator_gate_pvs_ro6_standalone_lvs.rpt"
grep -q 'PVS_RO6_STANDALONE_LVS' "$TMP_ROOT/env_fail.publish.args"

echo "MPTDC_RO6_STANDALONE_LVS_DRIVER_TEST=PASS"
