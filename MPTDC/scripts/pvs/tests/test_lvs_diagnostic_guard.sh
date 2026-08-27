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
BOUNDARY_SCOPE="$PREPARED/manifests/pvs_ro6_boundary_blackbox_scope.rpt"
DRC_STATUS="$PREPARED/reports/pvs_drc_base_status.rpt"
RULE_REPORT="$PREPARED/reports/pvs_drc_base_nonzero_rules.tsv"

mkdir -p "$REPO/MPTDC/scripts/pvs" "$PREPARED/outputs" "$PREPARED/manifests" \
  "$PREPARED/reports" "$TEMPLATE" "$OLD_BASE"
cp -p "$PVS_DIR/03_replay_pvs_lvs_from_template.sh" "$REPLAY"
cp -p "$PVS_DIR/lib_pvs_common.sh" "$REPO/MPTDC/scripts/pvs/lib_pvs_common.sh"
cat > "$REPO/MPTDC/scripts/pvs/06_gate_pvs_lvs.py" <<'PY'
#!/usr/bin/env python3
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--out", required=True)
parser.add_argument("--inventory", required=True)
args, _ = parser.parse_known_args()
Path(args.out).write_text("STATUS=PASS\nPVS_LVS_STATUS=MATCH\nPVS_RC=0\n")
Path(args.inventory).write_text("path\tnegative\tpositive\treport_level\n")
PY

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC LVS diagnostic guard test'
git -C "$REPO" config user.email 'mptdc-lvs-guard@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

printf 'new gds\n' > "$NEW_GDS"
cat > "$NEW_SOURCE" <<'EOF'
module mptdc_axis_core;
  RO_tune6 u_fast (
    .VDD(VDD), .VSS(VSS), .rstb(rstb),
    .\code<0> (c0), .\code<1> (c1), .\code<2> (c2), .\code<3> (c3),
    .\code<4> (c4), .\code<5> (c5), .\code<6> (c6), .\code<7> (c7),
    .\S<0> (s0), .\S<1> (s1), .\S<2> (s2), .\S<3> (s3),
    .\S<4> (s4), .\S<5> (s5), .\S<6> (s6), .\S<7> (s7));
  RO_tune6 u_slow (
    .VDD(VDD), .VSS(VSS), .rstb(rstb),
    .\code<0> (c0), .\code<1> (c1), .\code<2> (c2), .\code<3> (c3),
    .\code<4> (c4), .\code<5> (c5), .\code<6> (c6), .\code<7> (c7),
    .\S<0> (s0), .\S<1> (s1), .\S<2> (s2), .\S<3> (s3),
    .\S<4> (s4), .\S<5> (s5), .\S<6> (s6), .\S<7> (s7));
endmodule
module RO_tune6 (VDD, VSS, rstb, \code<0> , \code<1> , \code<2> , \code<3> , \code<4> , \code<5> , \code<6> , \code<7> , \S<0> , \S<1> , \S<2> , \S<3> , \S<4> , \S<5> , \S<6> , \S<7> );
  inout VDD;
  inout VSS;
  inout rstb;
  inout \code<0> ;
  inout \code<1> ;
  inout \code<2> ;
  inout \code<3> ;
  inout \code<4> ;
  inout \code<5> ;
  inout \code<6> ;
  inout \code<7> ;
  inout \S<0> ;
  inout \S<1> ;
  inout \S<2> ;
  inout \S<3> ;
  inout \S<4> ;
  inout \S<5> ;
  inout \S<6> ;
  inout \S<7> ;
endmodule
EOF
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
cat > "$BOUNDARY_SCOPE" <<'EOF'
PVS_RUN_CLASS=DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX
DIAGNOSTIC_SCOPE=LVS_ONLY_RO6_BOUNDARY
BLACKBOX_CELL=RO_tune6
RO6_BUS_PIN_NORMALIZATION=EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS
VERILOG_GLOBAL_SIGNAL_PORT_POLICY=DO_NOT_PROMOTE
RO6_STANDALONE_LVS_REQUIRED=YES
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

run_boundary_dry() {
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
    --diagnostic-ro6-boundary-blackbox \
    --dry-run
}

run_boundary() {
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
    --diagnostic-ro6-boundary-blackbox
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

run_boundary_dry "$TMP_ROOT/lvs_boundary_valid" > "$TMP_ROOT/boundary_valid.stdout"
grep -qx 'PVS_LVS_REPLAY_STATUS=DRY_RUN_READY' "$PREPARED/reports/pvs_lvs_status.rpt"
grep -qx 'lvs_black_box RO_tune6;' "$TMP_ROOT/lvs_boundary_valid/pvslvsctl"
! grep -q 'lvs_verilog_bus_map_by_position' "$TMP_ROOT/lvs_boundary_valid/pvslvsctl"
grep -qx 'lvs_global_sigs_are_ports no;' "$TMP_ROOT/lvs_boundary_valid/pvslvsctl"
grep -qx 'diagnostic_ro6_boundary_blackbox: 1' "$PREPARED/manifests/pvs_lvs_replay_manifest.txt"
grep -qx 'blackbox_cell: RO_tune6' "$PREPARED/manifests/pvs_lvs_replay_manifest.txt"
grep -qx 'ro6_bus_pin_normalization: EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS' "$PREPARED/manifests/pvs_lvs_replay_manifest.txt"
grep -qx 'verilog_global_signal_port_policy: DO_NOT_PROMOTE' "$PREPARED/manifests/pvs_lvs_replay_manifest.txt"

mv "$BOUNDARY_SCOPE" "${BOUNDARY_SCOPE}.saved"
set +e
run_boundary_dry "$TMP_ROOT/lvs_boundary_missing_scope" > "$TMP_ROOT/boundary_missing_scope.stdout" 2>&1
BOUNDARY_MISSING_SCOPE_RC=$?
set -e
mv "${BOUNDARY_SCOPE}.saved" "$BOUNDARY_SCOPE"
test "$BOUNDARY_MISSING_SCOPE_RC" -ne 0
grep -Fq 'required file does not exist' "$TMP_ROOT/boundary_missing_scope.stdout"

printf 'RO_tune6 RO_tune6\nEXTRA EXTRA\n' > "$NEW_HCELL"
set +e
run_boundary_dry "$TMP_ROOT/lvs_boundary_bad_hcell" > "$TMP_ROOT/boundary_bad_hcell.stdout" 2>&1
BOUNDARY_BAD_HCELL_RC=$?
set -e
test "$BOUNDARY_BAD_HCELL_RC" -ne 0
grep -Fq "requires exactly one 'RO_tune6 RO_tune6' HCell mapping" "$TMP_ROOT/boundary_bad_hcell.stdout"

printf 'RO_tune6 RO_tune6\n' > "$NEW_HCELL"
cat > "$TEMPLATE/run.pvs" <<'EOF'
#!/bin/sh
if [ "${MPTDC_TEST_BLACKBOX_EFFECTIVE:-1}" = 1 ]; then
  blackboxed=1
else
  blackboxed=0
fi
cat > boundary_lvs.sum.cls <<CLS
LVS Rules Given in the Rules File
    lvs_black_box RO_tune6
    lvs_global_sigs_are_ports no
Cells that have been blackboxed              |         $blackboxed
RO_tune6 | 19 : 19 | 19 : 19 | match | black box
#####  Run Result                    :     MATCH
CLS
exit 0
EOF

MPTDC_TEST_BLACKBOX_EFFECTIVE=1 \
run_boundary "$TMP_ROOT/lvs_boundary_effective" > "$TMP_ROOT/boundary_effective.stdout"
grep -qx 'LVS_BLACKBOX_RULE_STATUS=PASS' "$PREPARED/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"
grep -qx 'LVS_BUS_PIN_MAP_RULE_STATUS=NOT_USED_EXACT_SCALAR_SOURCE' "$PREPARED/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"
grep -qx 'LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=PASS' "$PREPARED/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"
grep -qx 'LVS_BLACKBOXED_CELL_COUNT=1' "$PREPARED/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"
grep -qx 'LVS_BLACKBOX_APPLICATION_STATUS=PASS' "$PREPARED/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"
grep -qx 'RO6_BLACKBOX_CELL_MATCH_STATUS=PASS' "$PREPARED/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"

set +e
MPTDC_TEST_BLACKBOX_EFFECTIVE=0 \
run_boundary "$TMP_ROOT/lvs_boundary_ineffective" > "$TMP_ROOT/boundary_ineffective.stdout" 2>&1
BOUNDARY_INEFFECTIVE_RC=$?
set -e
test "$BOUNDARY_INEFFECTIVE_RC" -ne 0
grep -qx 'LVS_BLACKBOX_RULE_STATUS=PASS' "$PREPARED/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"
grep -qx 'LVS_BLACKBOXED_CELL_COUNT=0' "$PREPARED/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"
grep -qx 'LVS_BLACKBOX_APPLICATION_STATUS=FAIL' "$PREPARED/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"

echo "MPTDC_PVS_LVS_DIAGNOSTIC_GUARD_TEST=PASS"
