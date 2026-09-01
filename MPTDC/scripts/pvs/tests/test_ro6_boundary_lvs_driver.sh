#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_ro6_boundary_lvs_driver.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_ID=source_pvs_mismatch
SOURCE_EVIDENCE_ID=${SOURCE_ID}_04_lvs
STANDALONE_ID=ro6_standalone_match
SOURCE_BASE="$WORK/$SOURCE_ID"
STANDALONE_BASE="$WORK/$STANDALONE_ID"
SOURCE_LVS="$SOURCE_BASE/pvs_lvs/source_lvs_script"
DRIVER="$REPO/MPTDC/scripts/pvs/server_run_mptdc_ro6_boundary_lvs.sh"
REPLAY="$TMP_ROOT/replay_stub.sh"
PUBLISHER="$TMP_ROOT/publisher_stub.sh"
RAW_CLASSIFIER="$TMP_ROOT/raw_classifier_stub.py"
SOURCE_SNAPSHOT="$REPO/MPTDC/docs/server_snapshots/pvs/$SOURCE_EVIDENCE_ID"
STANDALONE_SNAPSHOT="$REPO/MPTDC/docs/server_snapshots/pvs/$STANDALONE_ID"

mkdir -p "$REPO/MPTDC/scripts/pvs" "$SOURCE_LVS/svdb" "$SOURCE_BASE/outputs" \
  "$SOURCE_BASE/manifests" "$SOURCE_BASE/reports" \
  "$STANDALONE_BASE/inputs" "$STANDALONE_BASE/manifests" "$STANDALONE_BASE/reports" \
  "$SOURCE_SNAPSHOT/manifests" "$SOURCE_SNAPSHOT/reports" \
  "$SOURCE_SNAPSHOT/pvs_lvs/source_lvs_script" \
  "$STANDALONE_SNAPSHOT/manifests" "$STANDALONE_SNAPSHOT/reports" \
  "$STANDALONE_SNAPSHOT/pvs_lvs/RO_tune6_standalone_script"
cp -p "$PVS_DIR/server_run_mptdc_ro6_boundary_lvs.sh" "$DRIVER"

printf 'merged gds\n' > "$SOURCE_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds"
cat > "$SOURCE_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v" <<'EOF'
module mptdc_axis_core; endmodule
module RO_tune6 (VDD, VSS, rstb, \code<0> , \code<1> , \code<2> , \code<3> , \code<4> , \code<5> , \code<6> , \code<7> , \S<0> , \S<1> , \S<2> , \S<3> , \S<4> , \S<5> , \S<6> , \S<7> );
  inout VDD;
  inout VSS;
  inout rstb;
  inout \code<0> , \code<1> , \code<2> , \code<3> , \code<4> , \code<5> , \code<6> , \code<7> ;
  inout \S<0> , \S<1> , \S<2> , \S<3> , \S<4> , \S<5> , \S<6> , \S<7> ;
endmodule
EOF
printf 'RO_tune6 RO_tune6\n' > "$SOURCE_BASE/outputs/pvs_hcell_ro6.txt"
cat > "$SOURCE_BASE/manifests/pvs_input_hashes.rpt" <<EOF
STRICT_ATTRIBUTION=1
MERGED_GDS_PATH=$SOURCE_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds
MERGED_GDS_SHA256=$(sha256sum "$SOURCE_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds" | awk '{print $1}')
LVS_SOURCE_FILTERED_PATH=$SOURCE_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v
LVS_SOURCE_FILTERED_SHA256=$(sha256sum "$SOURCE_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v" | awk '{print $1}')
LVS_HCELL_PATH=$SOURCE_BASE/outputs/pvs_hcell_ro6.txt
LVS_HCELL_SHA256=$(sha256sum "$SOURCE_BASE/outputs/pvs_hcell_ro6.txt" | awk '{print $1}')
RO_GDS_SHA256=$(sha256sum "$SOURCE_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds" | awk '{print $1}')
EOF
cat > "$SOURCE_BASE/reports/lvs_source_filter.rpt" <<'EOF'
LVS_SOURCE_CONTRACT_STATUS=PASS
SOURCE_KIND=INNOVUS_SAVE_NETLIST_PHYS_INCLUDE_POWER_GROUND
MODULE_REMOVAL_POLICY=EXACT_CANONICAL_CDL_MEMBERSHIP
PHYSICAL_ONLY_INSTANCE_REMOVAL_POLICY=EXACT_TRACKED_FILLER_REPORT_MASTER_SET
PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_EXPECTED=3
PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_INPUT=3
PHYSICAL_ONLY_FILLER_INSTANCE_COUNT_REMOVED=3
PHYSICAL_ONLY_FILLER_REMOVAL_STATUS=PASS
RO6_PIN_NORMALIZATION=EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS
RO_TUNE6_INSTANCE_COUNT=2
RO_TUNE6_INSTANCE_NAME_STATUS=PASS
PHYSICAL_TIE_INSTANCE_COUNT=1
PHYSICAL_TIE_PRESERVATION_STATUS=PASS
UNRESOLVED_ACTIVE_MASTER_COUNT=0
EOF
cat > "$STANDALONE_BASE/reports/operator_gate_pvs_ro6_standalone_lvs.rpt" <<'EOF'
STEP=PVS_RO6_STANDALONE_LVS
OA_READ_ONLY_STATUS=PASS
RO6_CDL_PIN_CONTRACT_STATUS=PASS
PVS_LVS=MATCH
CLS_RUN_RESULT=MATCH
BLACKBOXED_CELL_COUNT=0
SIGNOFF_ELIGIBLE=NO
DECISION=PASS_CONTINUE
EOF
printf 'merged gds\n' > "$STANDALONE_BASE/inputs/RO_tune6.fresh.gds"
printf 'RO CDL fixture\n' > "$STANDALONE_BASE/inputs/RO_tune6.fresh.cdl"
cat > "$STANDALONE_BASE/manifests/ro6_standalone_lvs_inputs.rpt" <<EOF
LOCAL_RO_GDS=$STANDALONE_BASE/inputs/RO_tune6.fresh.gds
LOCAL_RO_CDL=$STANDALONE_BASE/inputs/RO_tune6.fresh.cdl
RO_GDS_SHA256=$(sha256sum "$SOURCE_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds" | awk '{print $1}')
RO_CDL_SHA256=$(printf 'RO CDL fixture\n' | sha256sum | awk '{print $1}')
EOF
cat > "$SOURCE_BASE/reports/pvs_lvs_status.rpt" <<'EOF'
STATUS=FAIL
PVS_LVS_STATUS=NOT_PROVEN
ERROR=pvslvsctl Verilog schematic_path is not exactly the immutable source
EOF
printf 'PVS_LVS_RC=0\n' > "$SOURCE_BASE/reports/pvs_lvs_tool_status.rpt"
printf '#!/bin/sh\n' > "$SOURCE_LVS/run.pvs"
cat > "$SOURCE_LVS/source.cls" <<'EOF'
#####  Run Result                    :     MISMATCH
Cells that have been blackboxed              |         0
 (-, RO_tune6())         |        *0 :        2 |        *0 :        2
EOF
printf 'mismatch\n' > "$SOURCE_LVS/svdb/mismatched"
cat > "$SOURCE_BASE/reports/operator_gate_pvs_lvs.rpt" <<'EOF'
STEP=PVS_LVS
PVS_LVS_STATUS=MISMATCH
PVS_RC=0
EOF

cp -p "$SOURCE_BASE/manifests/pvs_input_hashes.rpt" "$SOURCE_SNAPSHOT/manifests/"
cp -p "$SOURCE_BASE/reports/lvs_source_filter.rpt" "$SOURCE_SNAPSHOT/reports/"
cp -p "$SOURCE_BASE/reports/pvs_lvs_status.rpt" "$SOURCE_SNAPSHOT/reports/"
cp -p "$SOURCE_BASE/reports/pvs_lvs_tool_status.rpt" "$SOURCE_SNAPSHOT/reports/"
cp -p "$SOURCE_BASE/reports/operator_gate_pvs_lvs.rpt" "$SOURCE_SNAPSHOT/reports/"
cp -p "$SOURCE_LVS/source.cls" "$SOURCE_SNAPSHOT/pvs_lvs/source_lvs_script/"
printf '#!/bin/sh\n' > "$SOURCE_SNAPSHOT/pvs_lvs/source_lvs_script/run.pvs"
printf 'lvs_report_file "source.sum";\n' > "$SOURCE_SNAPSHOT/pvs_lvs/source_lvs_script/pvslvsctl"
: > "$SOURCE_SNAPSHOT/pvs_lvs/source_lvs_script/.config.rul"
printf 'technology fixture\n' > "$SOURCE_SNAPSHOT/pvs_lvs/source_lvs_script/.technology.rul"

cp -p "$STANDALONE_BASE/reports/operator_gate_pvs_ro6_standalone_lvs.rpt" \
  "$STANDALONE_SNAPSHOT/reports/"
cp -p "$STANDALONE_BASE/manifests/ro6_standalone_lvs_inputs.rpt" \
  "$STANDALONE_SNAPSHOT/manifests/"
cat > "$STANDALONE_SNAPSHOT/pvs_lvs/RO_tune6_standalone_script/RO_tune6_lvs.sum.cls" <<'EOF'
#####  Run Result                    :   MATCH
Cells which mismatch                         |         0
Cells that have been blackboxed              |         0
RO_tune6     |       19 :        19 |       19 :        19 | match      |
EOF
printf '#!/bin/sh\n' > "$STANDALONE_SNAPSHOT/pvs_lvs/RO_tune6_standalone_script/run.pvs"
printf 'lvs_report_file "RO_tune6_lvs.sum";\n' > "$STANDALONE_SNAPSHOT/pvs_lvs/RO_tune6_standalone_script/pvslvsctl"
: > "$STANDALONE_SNAPSHOT/pvs_lvs/RO_tune6_standalone_script/.config.rul"
printf 'technology fixture\n' > "$STANDALONE_SNAPSHOT/pvs_lvs/RO_tune6_standalone_script/.technology.rul"

cat > "$RAW_CLASSIFIER" <<'PY'
#!/usr/bin/env python3
import argparse
import hashlib
import os
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--cls", type=Path, required=True)
parser.add_argument("--out", type=Path, required=True)
parser.add_argument("--expected-ro-instance", action="append")
args = parser.parse_args()
passed = os.environ.get("MPTDC_TEST_RAW_CLASSIFIER_STATUS", "pass") == "pass"
raw = args.cls.read_bytes()
lines = [
    "STATUS=" + ("PASS" if passed else "FAIL"),
    "CLS_SHA256=" + hashlib.sha256(raw).hexdigest(),
    "MISMATCH_ATTRIBUTION=" + ("EXACT_TWO_RO6_INTERNALS_ONLY" if passed else "REJECTED"),
    "HIERARCHICAL_COMPOSITION_ELIGIBLE=" + ("YES" if passed else "NO"),
    "SOURCE_ONLY_INSTANCE_COUNT=2",
    "LAYOUT_ONLY_INSTANCE_COUNT=380",
    "RO_LAYOUT_CLUSTER_COUNT=2",
]
args.out.write_text("\n".join(lines) + "\n", encoding="utf-8")
raise SystemExit(0 if passed else 10)
PY

cat > "$REPLAY" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
prepared=""
new_run=""
template_run=""
boundary=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prepared-dir) prepared="$2"; shift 2 ;;
    --new-run-dir) new_run="$2"; shift 2 ;;
    --template-run) template_run="$2"; shift 2 ;;
    --diagnostic-ro6-boundary-blackbox) boundary=1; shift ;;
    --old-base|--old-gds|--old-source|--old-hcell|--expected-head) shift 2 ;;
    *) echo "unexpected replay option: $1" >&2; exit 8 ;;
  esac
done
[[ "$boundary" == 1 && -n "$prepared" && -n "$new_run" && -n "$template_run" ]]
mkdir -p "$new_run" "$prepared/reports"
cat > "$new_run/run.pvs" <<'RUN'
#!/bin/sh -f
pvs \
  -lvs \
  -top_cell mptdc_axis_core \
  -source_top_cell mptdc_axis_core \
  -control pvslvsctl \
  .config.rul \
  .technology.rul
RUN
printf 'lvs_black_box RO_tune6;\n' > "$new_run/pvslvsctl"
: > "$new_run/.config.rul"
printf 'technology fixture\n' > "$new_run/.technology.rul"
printf 'TEMPLATE_RUN=%s\n' "$template_run" > "$prepared/reports/replay_template.rpt"
if [[ "${MPTDC_TEST_BOUNDARY_RESULT:-match}" == pg_open ]]; then
  cat > "$prepared/reports/pvs_lvs_status.rpt" <<'RPT'
STATUS=FAIL
PVS_LVS_STATUS=MISMATCH
PVS_RC=0
RPT
  replay_rc=8
  layout_open_count=4
  shorts_opens_count=2
  vdd_open_count=1
  vss_open_count=1
  cls_result=MISMATCH
else
  cat > "$prepared/reports/pvs_lvs_status.rpt" <<'RPT'
STATUS=PASS
PVS_LVS_STATUS=MATCH
PVS_RC=0
RPT
  replay_rc=0
  layout_open_count=0
  shorts_opens_count=0
  vdd_open_count=0
  vss_open_count=0
  cls_result=MATCH
fi
cat > "$new_run/boundary.cls" <<RPT
#####  Run Result                    :   $cls_result
Cells that have been blackboxed              |         1
mptdc_axis_core     |       59 :        59 |       59 :        59 | match      |
RO_tune6     |       19 :        19 |       19 :        19 | match      |
RPT
cat > "$prepared/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt" <<RPT
LVS_BLACKBOX_CLS_FILE_COUNT=1
LVS_BLACKBOX_CLS_FILE=$new_run/boundary.cls
LVS_BLACKBOX_RULE_STATUS=PASS
LVS_BLACKBOX_APPLICATION_STATUS=PASS
LVS_BLACKBOXED_CELL_COUNT=1
LVS_BUS_PIN_MAP_EFFECTIVE_VALUE=NO
LVS_BUS_PIN_MAP_RULE_STATUS=NOT_USED_EXACT_SCALAR_SOURCE
LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=PASS
RO6_BLACKBOX_INITIAL_PINS=19:19
RO6_BLACKBOX_COMPARE_PINS=19:19
RO6_BLACKBOX_CELL_STATUS=match
RO6_BLACKBOX_CELL_MATCH_STATUS=PASS
RO6_ANGLE_BUS_MISSING_PIN_COUNT=0
RO6_SQUARE_BUS_MISSING_PIN_COUNT=0
TIE1_UNMATCHED_PIN_COUNT=0
TIE1_MISMATCHED_NET_COUNT=0
TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT=0
LAYOUT_OPEN_NET_COUNT=$layout_open_count
SHORTS_OPENS_RECORD_COUNT=$shorts_opens_count
MISMATCHED_NET_RECORD_COUNT=0
MISMATCHED_INSTANCE_RECORD_COUNT=0
VDD_OPEN_SECTION_COUNT=$vdd_open_count
VSS_OPEN_SECTION_COUNT=$vss_open_count
RO6_STANDALONE_LVS_REQUIRED=YES
SIGNOFF_ELIGIBLE=NO
RPT
exit "$replay_rc"
EOF

cat > "$PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MPTDC_TEST_PUBLISH_ARGS:?}"
exit 0
EOF
chmod +x "$REPLAY" "$PUBLISHER"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC RO6 boundary LVS test'
git -C "$REPO" config user.email 'mptdc-ro6-boundary@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

HIERARCHICAL_RUN_ID=boundary_lvs_hierarchical_match
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_BOUNDARY_RAW_CLASSIFIER="$RAW_CLASSIFIER" \
MPTDC_BOUNDARY_ALLOW_TEST_OVERRIDES=1 \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish_hierarchical.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --source-pvs-evidence-id "$SOURCE_EVIDENCE_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --hierarchical-lvs-signoff \
  --run-id "$HIERARCHICAL_RUN_ID" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/hierarchical.stdout"

HIERARCHICAL_GATE="$WORK/$HIERARCHICAL_RUN_ID/reports/operator_gate_pvs_hierarchical_lvs.rpt"
grep -qx 'PVS_BOUNDARY_RECOVERY_STATUS=PASS' "$TMP_ROOT/hierarchical.stdout"
grep -qx 'PVS_HIERARCHICAL_LVS_STATUS=MATCH' "$TMP_ROOT/hierarchical.stdout"
grep -qx 'LVS_PROOF_METHOD=HIERARCHICAL_TOP_BLACKBOX_PLUS_STANDALONE_RO' \
  "$TMP_ROOT/hierarchical.stdout"
grep -qx 'DECISION=PASS_HIERARCHICAL_LVS' "$TMP_ROOT/hierarchical.stdout"
grep -qx 'NEXT_STAGE=PVS_DENSITY_DRC' "$TMP_ROOT/hierarchical.stdout"
grep -qx 'PVS_RUN_CLASS=SIGNOFF_HIERARCHICAL_LVS_COMPOSITION' "$HIERARCHICAL_GATE"
grep -qx 'BOUNDARY_TOP_INITIAL_PINS=59:59' "$HIERARCHICAL_GATE"
grep -qx 'BOUNDARY_TOP_COMPARE_PINS=59:59' "$HIERARCHICAL_GATE"
grep -qx 'BOUNDARY_TOP_CELL_STATUS=match' "$HIERARCHICAL_GATE"
grep -Eq '^BOUNDARY_RUN_PVS_SHA256=[0-9a-f]{64}$' "$HIERARCHICAL_GATE"
grep -Eq '^BOUNDARY_LVS_CONTROL_SHA256=[0-9a-f]{64}$' "$HIERARCHICAL_GATE"
grep -qx "TEMPLATE_RUN=$SOURCE_SNAPSHOT/pvs_lvs/source_lvs_script" \
  "$WORK/$HIERARCHICAL_RUN_ID/reports/replay_template.rpt"
grep -qx 'LVS_TEMPLATE_SOURCE=TRACKED_SOURCE_SNAPSHOT' \
  "$WORK/$HIERARCHICAL_RUN_ID/manifests/pvs_ro6_boundary_blackbox_scope.rpt"
grep -qx 'RAW_MISMATCH_ATTRIBUTION=EXACT_TWO_RO6_INTERNALS_ONLY' "$HIERARCHICAL_GATE"
grep -qx 'PVS_TOP_BOUNDARY_LVS=MATCH' "$HIERARCHICAL_GATE"
grep -qx 'PVS_RO6_STANDALONE_LVS=MATCH' "$HIERARCHICAL_GATE"
grep -qx 'BOUNDARY_BLACKBOXED_CELL_COUNT=1' "$HIERARCHICAL_GATE"
grep -qx 'STANDALONE_BLACKBOXED_CELL_COUNT=0' "$HIERARCHICAL_GATE"
grep -qx 'BLOCK_LVS_CLOSED=YES' "$HIERARCHICAL_GATE"
grep -qx 'LVS_SIGNOFF_ELIGIBLE=YES' "$HIERARCHICAL_GATE"
grep -qx 'MONOLITHIC_LVS_REQUIRED=NO_BY_SELECTED_METHOD' "$HIERARCHICAL_GATE"
grep -qx 'FINAL_PHYSICAL_SIGNOFF_READY=NO' "$HIERARCHICAL_GATE"

set +e
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_BOUNDARY_RAW_CLASSIFIER="$RAW_CLASSIFIER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish_override_rejected.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --source-pvs-evidence-id "$SOURCE_EVIDENCE_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --hierarchical-lvs-signoff \
  --run-id boundary_lvs_hierarchical_override_rejected \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/hierarchical_override_rejected.stdout" 2>&1
HIERARCHICAL_OVERRIDE_RC=$?
set -e
test "$HIERARCHICAL_OVERRIDE_RC" -eq 4
grep -Fq 'hierarchical signoff forbids classifier, replay, or publisher overrides' \
  "$TMP_ROOT/hierarchical_override_rejected.stdout"
test ! -e "$WORK/boundary_lvs_hierarchical_override_rejected"

set +e
MPTDC_TEST_RAW_CLASSIFIER_STATUS=fail \
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_BOUNDARY_RAW_CLASSIFIER="$RAW_CLASSIFIER" \
MPTDC_BOUNDARY_ALLOW_TEST_OVERRIDES=1 \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish_bad_raw.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --source-pvs-evidence-id "$SOURCE_EVIDENCE_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --hierarchical-lvs-signoff \
  --run-id boundary_lvs_hierarchical_bad_raw \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/hierarchical_bad_raw.stdout" 2>&1
HIERARCHICAL_BAD_RAW_RC=$?
set -e
test "$HIERARCHICAL_BAD_RAW_RC" -eq 4
grep -Fq 'raw mismatch is not exactly attributable to the two RO_tune6 interiors' \
  "$TMP_ROOT/hierarchical_bad_raw.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/hierarchical_bad_raw.stdout"

RUN_ID=boundary_lvs_pass
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id "$RUN_ID" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'PVS_BOUNDARY_RECOVERY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'SOURCE_GATE_LVS_STATUS=NOT_PROVEN' "$TMP_ROOT/pass.stdout"
grep -qx 'SOURCE_CLS_RUN_RESULT=MISMATCH' "$TMP_ROOT/pass.stdout"
grep -qx 'SOURCE_PVS_RC=0' "$TMP_ROOT/pass.stdout"
grep -qx 'SOURCE_CONTRACT_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'SOURCE_PHYSICAL_TIE_INSTANCE_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'PVS_LVS=MATCH' "$TMP_ROOT/pass.stdout"
grep -qx 'LVS_BUS_PIN_MAP_EFFECTIVE_VALUE=NO' "$TMP_ROOT/pass.stdout"
grep -qx 'LVS_BUS_PIN_MAP_RULE_STATUS=NOT_USED_EXACT_SCALAR_SOURCE' "$TMP_ROOT/pass.stdout"
grep -qx 'LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'RO6_BLACKBOX_CELL_MATCH_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'BOUNDARY_REMAINDER_CLASS=NONE_MATCH' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_COMPOSITIONAL_LVS' "$TMP_ROOT/pass.stdout"
grep -qx 'PUBLISH_RC=0' "$TMP_ROOT/pass.stdout"
grep -qx 'NEXT_STAGE=PVS_RO6_MONOLITHIC_FULL_TOP_LVS' "$TMP_ROOT/pass.stdout"
grep -q "pvs $RUN_ID $WORK/$RUN_ID PVS_RO6_BOUNDARY_LVS" "$TMP_ROOT/publish.args"
test -L "$WORK/$RUN_ID/outputs"
grep -qx 'SIGNOFF_ELIGIBLE=NO' "$WORK/$RUN_ID/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"
grep -qx 'RAW_FULL_TOP_LVS_STATUS=MISMATCH_RO_ABSTRACTION_ONLY' \
  "$WORK/$RUN_ID/reports/operator_gate_pvs_compositional_lvs.rpt"
grep -qx 'COMPOSITIONAL_LVS_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_pvs_compositional_lvs.rpt"
grep -qx 'DECISION=PASS_MONOLITHIC_LVS_CONTINUE' \
  "$WORK/$RUN_ID/reports/operator_gate_pvs_compositional_lvs.rpt"
grep -qx 'NEXT_STAGE=PVS_RO6_MONOLITHIC_FULL_TOP_LVS' \
  "$WORK/$RUN_ID/reports/operator_gate_pvs_compositional_lvs.rpt"

set +e
MPTDC_TEST_BOUNDARY_RESULT=pg_open \
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish_pg_open.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id boundary_lvs_pg_open \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pg_open.stdout" 2>&1
PG_OPEN_RC=$?
set -e
test "$PG_OPEN_RC" -eq 0
grep -qx 'PVS_BOUNDARY_RECOVERY_STATUS=PASS' "$TMP_ROOT/pg_open.stdout"
grep -qx 'PVS_LVS=MISMATCH' "$TMP_ROOT/pg_open.stdout"
grep -qx 'BOUNDARY_REMAINDER_CLASS=RO6_PG_OPEN_ONLY' "$TMP_ROOT/pg_open.stdout"
grep -qx 'DECISION=PASS_PG_REPAIR_REQUIRED' "$TMP_ROOT/pg_open.stdout"
grep -qx 'NEXT_STAGE=RO6_PG_ENDPOINT_PROBE' "$TMP_ROOT/pg_open.stdout"

cat > "$SOURCE_LVS/source.cls" <<'EOF'
#####  Run Result                    :     MISMATCH
Cells that have been blackboxed              |         1
 (-, RO_tune6())         |        *0 :        2 |        *0 :        2
EOF
set +e
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish_bad.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id boundary_lvs_bad_source \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/bad_source.stdout" 2>&1
BAD_SOURCE_RC=$?
set -e
test "$BAD_SOURCE_RC" -ne 0
grep -Fq 'source mismatch is not the expected un-blackboxed RO_tune6 boundary signature' "$TMP_ROOT/bad_source.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/bad_source.stdout"

cat > "$SOURCE_LVS/source.cls" <<'EOF'
#####  Run Result                    :     MISMATCH
Cells that have been blackboxed              |         0
 (-, RO_tune6())         |        *0 :        2 |        *0 :        2
EOF
printf 'PVS_LVS_RC=1\n' > "$SOURCE_BASE/reports/pvs_lvs_tool_status.rpt"
set +e
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish_bad_rc.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id boundary_lvs_bad_tool_rc \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/bad_tool_rc.stdout" 2>&1
BAD_TOOL_RC=$?
set -e
test "$BAD_TOOL_RC" -ne 0
grep -Fq 'source must have raw CLS MISMATCH and tool RC zero' "$TMP_ROOT/bad_tool_rc.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/bad_tool_rc.stdout"

printf 'PVS_LVS_RC=0\n' > "$SOURCE_BASE/reports/pvs_lvs_tool_status.rpt"
sed -i 's/^PHYSICAL_TIE_INSTANCE_COUNT=1$/PHYSICAL_TIE_INSTANCE_COUNT=0/' \
  "$SOURCE_BASE/reports/lvs_source_filter.rpt"
set +e
MPTDC_BOUNDARY_LVS_REPO_ROOT="$REPO" \
MPTDC_BOUNDARY_LVS_REPLAY="$REPLAY" \
MPTDC_BOUNDARY_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/publish_no_ties.args" \
bash "$DRIVER" \
  --source-pvs-run-id "$SOURCE_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id boundary_lvs_missing_physical_ties \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/no_ties.stdout" 2>&1
NO_TIES_RC=$?
set -e
test "$NO_TIES_RC" -eq 0
grep -qx 'SOURCE_PHYSICAL_TIE_INSTANCE_COUNT=0' "$TMP_ROOT/no_ties.stdout"
grep -qx 'PVS_BOUNDARY_RECOVERY_STATUS=PASS' "$TMP_ROOT/no_ties.stdout"
grep -qx 'DECISION=PASS_COMPOSITIONAL_LVS' "$TMP_ROOT/no_ties.stdout"
grep -qx 'NEXT_STAGE=PVS_RO6_MONOLITHIC_FULL_TOP_LVS' "$TMP_ROOT/no_ties.stdout"

echo "MPTDC_RO6_BOUNDARY_LVS_DRIVER_TEST=PASS"
