#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_lvs_diagnostic_guard.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
REPLAY="$REPO/MPTDC/scripts/pvs/03_replay_pvs_lvs_from_template.sh"
PREPARED="$TMP_ROOT/prepared"
TEMPLATE="$TMP_ROOT/template"
OLD_BASE="$TMP_ROOT/old_base"
OLD_GDS="$OLD_BASE/old.gds"
OLD_SOURCE="$OLD_BASE/old.v"
OLD_HCELL="$OLD_BASE/old.hcell"
NEW_GDS="$PREPARED/outputs/mptdc_axis_core_merged_stdcell_ro6.gds"
NEW_SOURCE="$PREPARED/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v"
NEW_HCELL="$PREPARED/outputs/pvs_hcell_ro6.txt"
DCELL_CDL="$TMP_ROOT/xh018_D_CELLS_JIHD.cdl"
SCOPE="$PREPARED/manifests/pvs_diagnostic_scope.rpt"
DRC_STATUS="$PREPARED/reports/pvs_drc_base_status.rpt"
RULE_REPORT="$PREPARED/reports/pvs_drc_base_nonzero_rules.tsv"

mkdir -p "$REPO/MPTDC/scripts/pvs" "$PREPARED/outputs" "$PREPARED/manifests" \
  "$PREPARED/reports" "$TEMPLATE" "$OLD_BASE"
cp -p "$PVS_DIR/03_replay_pvs_lvs_from_template.sh" "$REPLAY"
cp -p "$PVS_DIR/lib_pvs_common.sh" "$REPO/MPTDC/scripts/pvs/lib_pvs_common.sh"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC LVS diagnostic guard test'
git -C "$REPO" config user.email 'mptdc-lvs-guard@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

printf 'new gds\n' > "$NEW_GDS"
printf 'module mptdc_axis_core; endmodule\n' > "$NEW_SOURCE"
printf 'RO_tune6 RO_tune6\n' > "$NEW_HCELL"
printf '.SUBCKT INV A Y VDD VSS\n.ENDS\n' > "$DCELL_CDL"
printf 'old gds\n' > "$OLD_GDS"
printf 'old source\n' > "$OLD_SOURCE"
printf 'old hcell\n' > "$OLD_HCELL"

cat > "$TEMPLATE/run.pvs" <<EOF
#!/bin/sh
echo "$OLD_BASE $OLD_GDS $OLD_SOURCE $OLD_HCELL"
EOF
cat > "$TEMPLATE/pvslvsctl" <<EOF
layout_path "$OLD_GDS";
schematic_path "$OLD_SOURCE" verilog;
EOF
printf 'config %s\n' "$OLD_BASE" > "$TEMPLATE/.config.rul"
printf 'technology %s\n' "$OLD_HCELL" > "$TEMPLATE/.technology.rul"

cat > "$SCOPE" <<'EOF'
PVS_RUN_CLASS=DIAGNOSTIC_NOT_SIGNOFF
DIAGNOSTIC_SCOPE=BASE_DRC_PLUS_LVS
DEFERRED_INNOVUS_DRC_COUNT=1
DEFERRED_INNOVUS_DRC_RULE=MET1_MINIMUM_AREA
DENSITY_DRC_STATUS=NOT_RUN_BY_SCOPE
SIGNOFF_ELIGIBLE=NO
EOF
printf 'rule\tprimary\texpanded\nM1.MIN.AREA\t3\t3\n' > "$RULE_REPORT"
RULE_HASH="$(sha256sum "$RULE_REPORT" | awk '{print $1}')"
cat > "$DRC_STATUS" <<EOF
STATUS=FAIL
PVS_DRC_STATUS=FAIL
PVS_DRC_VARIANT=BASE
PVS_RC=0
DRC_TOTAL_PRIMARY=3
DRC_TOTAL_EXPANDED=3
NONZERO_RULE_COUNT=1
NONZERO_RULE_REPORT=$RULE_REPORT
NONZERO_RULE_REPORT_SHA256=$RULE_HASH
EOF

run_dry() {
  local run_dir="$1"
  bash "$REPLAY" \
    --prepared-dir "$PREPARED" \
    --template-run "$TEMPLATE" \
    --new-gds "$NEW_GDS" \
    --new-source "$NEW_SOURCE" \
    --new-hcell "$NEW_HCELL" \
    --dcell-cdl "$DCELL_CDL" \
    --old-base "$OLD_BASE" \
    --old-gds "$OLD_GDS" \
    --old-source "$OLD_SOURCE" \
    --old-hcell "$OLD_HCELL" \
    --new-run-dir "$run_dir" \
    --expected-head "$HEAD_SHA" \
    --diagnostic-allow-base-drc-debt \
    --dry-run
}

run_dry "$TMP_ROOT/lvs_valid" > "$TMP_ROOT/valid.stdout"
grep -qx 'PVS_LVS_REPLAY_STATUS=DRY_RUN_READY' "$PREPARED/reports/pvs_lvs_status.rpt"

mv "$SCOPE" "${SCOPE}.saved"
set +e
run_dry "$TMP_ROOT/lvs_missing_scope" > "$TMP_ROOT/missing_scope.stdout" 2>&1
MISSING_SCOPE_RC=$?
set -e
mv "${SCOPE}.saved" "$SCOPE"
test "$MISSING_SCOPE_RC" -ne 0
grep -Fq 'required file does not exist' "$TMP_ROOT/missing_scope.stdout"

printf 'M2.MIN.AREA\t1\t1\n' >> "$RULE_REPORT"
set +e
run_dry "$TMP_ROOT/lvs_bad_hash" > "$TMP_ROOT/bad_hash.stdout" 2>&1
BAD_HASH_RC=$?
set -e
test "$BAD_HASH_RC" -ne 0
grep -Fq 'rule inventory hash mismatch' "$TMP_ROOT/bad_hash.stdout"

echo "MPTDC_PVS_LVS_DIAGNOSTIC_GUARD_TEST=PASS"
