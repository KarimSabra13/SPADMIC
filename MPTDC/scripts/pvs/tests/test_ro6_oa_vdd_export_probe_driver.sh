#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_REPO="$(cd "$PVS_DIR/../../.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_ro6_oa_vdd_probe.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REAL_CLS="$REAL_REPO/MPTDC/docs/server_snapshots/pvs/20260827_mptdc_ro6_standalone_lvs_envfix_131803/pvs_lvs/RO_tune6_standalone_script/RO_tune6_lvs.sum.cls"
grep -Fq 'dbOpenCellViewByType(libName cellName viewName "" "r")' \
  "$PVS_DIR/probe_ro6_oa_vdd_export_contract.il"
grep -Fq 'OA_EDIT_AUTHORIZED=NO' \
  "$PVS_DIR/probe_ro6_oa_vdd_export_contract.il"
if grep -Eq 'db(Create|Delete|Move|Copy|Save)|dbReplaceProp|dbCreateProp' \
  "$PVS_DIR/probe_ro6_oa_vdd_export_contract.il"; then
  echo "ERROR: RO6 OA probe contains a write API" >&2
  exit 1
fi
python3 "$PVS_DIR/09_classify_ro6_vdd_pin_mismatch.py" \
  --cls "$REAL_CLS" --out "$TMP_ROOT/real_cls_classification.rpt"
grep -qx 'RO6_STANDALONE_MISMATCH_CLASSIFICATION=PASS' \
  "$TMP_ROOT/real_cls_classification.rpt"
grep -qx 'CLS_VDD_ONLY_MISSING_PIN_STATUS=PASS' \
  "$TMP_ROOT/real_cls_classification.rpt"

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_ID=ro6_standalone_source
SOURCE_DIR="$WORK/$SOURCE_ID"
SOURCE_LVS="$SOURCE_DIR/pvs_lvs/RO_tune6_standalone_script"
OA_ROOT="$TMP_ROOT/oa/RO_tune6"
OA_LAYOUT="$OA_ROOT/layout"
OA_SCHEMATIC="$OA_ROOT/schematic"
PROJECT_DIR="$TMP_ROOT/cds_V0"
MAP_DIR="$PROJECT_DIR/.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131"
LAYER_MAP="$MAP_DIR/strmInOut.layertable"
OBJECT_MAP="$MAP_DIR/strmOutObjects.map"
XSTREAM_LOG="$PROJECT_DIR/xstreamOut.log"
EXPORT_DIR="$TMP_ROOT/exports"
RO_GDS="$EXPORT_DIR/RO_tune6.gds"
RO_CDL="$EXPORT_DIR/RO_tune6.cdl"
BIN_DIR="$TMP_ROOT/bin"
CADENCE_ENV="$TMP_ROOT/cadence_env.sh"
PUBLISHER="$TMP_ROOT/publisher_stub.sh"
DRIVER="$REPO/MPTDC/scripts/pvs/server_probe_mptdc_ro6_oa_vdd_export_contract.sh"

mkdir -p "$REPO/MPTDC/scripts/pvs" "$SOURCE_LVS" "$SOURCE_DIR/reports" \
  "$SOURCE_DIR/manifests" "$OA_LAYOUT" "$OA_SCHEMATIC" "$MAP_DIR" \
  "$EXPORT_DIR" "$BIN_DIR"
cp -p "$PVS_DIR/server_probe_mptdc_ro6_oa_vdd_export_contract.sh" "$DRIVER"
printf 'layout fixture\n' > "$OA_LAYOUT/master.tag"
printf 'schematic fixture\n' > "$OA_SCHEMATIC/master.tag"
printf 'fresh GDS fixture\n' > "$RO_GDS"
printf '.SUBCKT RO_tune6 VDD VSS\n.ENDS\n' > "$RO_CDL"
GDS_SHA256="$(sha256sum "$RO_GDS" | awk '{print $1}')"
CDL_SHA256="$(sha256sum "$RO_CDL" | awk '{print $1}')"

cat > "$SOURCE_LVS/RO_tune6_lvs.sum.cls" <<'EOF'
#####  Top Cell                      :   RO_tune6  <vs>  RO_tune6
#####  Run Result                    :     MISMATCH
Cells that have been blackboxed              |         0
RO_tune6     |      *18 :        19 |      *18 :        19 | mismatch     | pin mismatches
Total                  |    1,218 :     1,154 |     1,212 :     1,154 |     190 :     190 |       0 :        0
Pins                   |          :           |           :           |     *18 :      19 |       0 :        0
Nets                   |          :           |           :           |     *45 :      44 |       0 :        0
INITIAL CORRESPONDENCES
Pin  | code<0> code<1> code<2> code<3> code<4> code<5> code<6> code<7> rstb S<0> S<1> S<2> S<3> S<4> S<5> S<6>
     | S<7> VSS
UNMATCHED SCHEMATIC PIN LABELS
Labeled Schematic Pin     | Matched Layout Pin     | Matched Layout Net
--------------------------+------------------------+-----------------------
VDD                       | ** missing pin **      | 12
END OF REPORT
EOF

cat > "$SOURCE_DIR/reports/operator_gate_pvs_ro6_standalone_lvs.rpt" <<'EOF'
PVS_RC=0
PVS_LVS=NOT_PROVEN
CLS_RUN_RESULT=MISMATCH
BLACKBOXED_CELL_COUNT=0
OA_READ_ONLY_STATUS=PASS
RO6_CDL_PIN_CONTRACT_STATUS=PASS
EOF

cat > "$SOURCE_DIR/manifests/ro6_standalone_lvs_inputs.rpt" <<EOF
ORIGINAL_RO_GDS=$RO_GDS
ORIGINAL_RO_CDL=$RO_CDL
RO_GDS_SHA256=$GDS_SHA256
RO_CDL_SHA256=$CDL_SHA256
OA_LAYOUT_DIR=$OA_LAYOUT
OA_SCHEMATIC_DIR=$OA_SCHEMATIC
EOF

cat > "$LAYER_MAP" <<'EOF'
MET1 drawing 10 0
MET1 pin 10 1
MET2 drawing 12 0
MET2 pin 12 1
MET3 drawing 14 0
MET3 pin 14 1
METTP drawing 16 0
METTP pin 16 1
EOF
cat > "$OBJECT_MAP" <<'EOF'
label drawing text
terminal pin text
EOF
cat > "$XSTREAM_LOG" <<EOF
strmFile                                $RO_GDS
topCell                                 RO_tune6
layerMap                                $LAYER_MAP
objectMap                               $OBJECT_MAP
WARNING (XSTRM-35): The objects in the layer-purpose pair 'MET3:pin' are ignored.
INFO (XSTRM-234): Translation completed. '0' error(s) and '1' warning(s) found.
strmout completed.
EOF

cat > "$BIN_DIR/virtuoso" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
root="${MPTDC_RO6_OA_PROBE_ROOT:?}"
cat > "$root/oa_ro6_cell_summary.rpt" <<'RPT'
STEP=RO6_OA_VDD_EXPORT_PROBE
OA_OPEN_MODE=READ_ONLY
OA_EDIT_AUTHORIZED=NO
LIBRARY=Prj_xh018_ksabra
CELL=RO_tune6
VIEW=layout
TERMINAL_COUNT=19
RPT
for index in 0 1 2 3 4 5 6 7; do
  printf 'TERMINAL_NAME=code<%s>\n' "$index" >> "$root/oa_ro6_cell_summary.rpt"
  printf 'TERMINAL_NAME=S<%s>\n' "$index" >> "$root/oa_ro6_cell_summary.rpt"
done
printf '%s\n' 'TERMINAL_NAME=rstb' 'TERMINAL_NAME=VDD' 'TERMINAL_NAME=VSS' \
  >> "$root/oa_ro6_cell_summary.rpt"

printf 'terminal\tdirection\tnet\tpin_index\tfig_index\tobj_type\tlayer\tpurpose\tllx\tlly\turx\tury\ttext\n' \
  > "$root/oa_ro6_terminal_pin_figs.tsv"
for index in 0 1 2 3 4 5 6 7; do
  printf 'code<%s>\tinput\tcode<%s>\t0\t0\trect\tMET3\tpin\t0\t0\t1\t1\tABSENT\n' "$index" "$index" \
    >> "$root/oa_ro6_terminal_pin_figs.tsv"
  printf 'S<%s>\toutput\tS<%s>\t0\t0\trect\tMET3\tpin\t0\t0\t1\t1\tABSENT\n' "$index" "$index" \
    >> "$root/oa_ro6_terminal_pin_figs.tsv"
done
printf 'rstb\tinput\trstb\t0\t0\trect\tMET3\tpin\t0\t0\t1\t1\tABSENT\n' \
  >> "$root/oa_ro6_terminal_pin_figs.tsv"
printf 'VDD\tinputOutput\tVDD\t0\t0\trect\tMET3\tpin\t-68.7\t-31.95\t-66.67\t-30.115\tABSENT\n' \
  >> "$root/oa_ro6_terminal_pin_figs.tsv"
printf 'VSS\tinputOutput\tVSS\t0\t0\trect\tMETTP\tpin\t-68.695\t-47.32\t-67.015\t-45.65\tABSENT\n' \
  >> "$root/oa_ro6_terminal_pin_figs.tsv"

cat > "$root/oa_ro6_label_shapes.tsv" <<'TSV'
obj_type	text	net	layer	purpose	llx	lly	urx	ury
label	VSS	VSS	METTP	label	-68.695	-47.32	-67.015	-45.65
TSV
cat > "$root/oa_ro6_probe_status.rpt" <<'RPT'
STEP=RO6_OA_VDD_EXPORT_PROBE
OA_OPEN_MODE=READ_ONLY
OA_EDIT_AUTHORIZED=NO
OA_PROBE_STATUS=PASS
RPT
exit 0
EOF
chmod +x "$BIN_DIR/virtuoso"

cat > "$CADENCE_ENV" <<EOF
#!/usr/bin/env bash
: "\$MPTDC_TEST_UNSET_SITE_VARIABLE"
export PATH="$BIN_DIR:\$PATH"
EOF

cat > "$PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MPTDC_TEST_PUBLISH_ARGS:?}"
exit 0
EOF
chmod +x "$PUBLISHER"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC RO6 OA VDD probe test'
git -C "$REPO" config user.email 'mptdc-ro6-oa-probe@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

RUN_ID=ro6_oa_vdd_probe_pass
MPTDC_RO6_OA_PROBE_REPO_ROOT="$REPO" \
MPTDC_RO6_OA_PROBE_PUBLISHER="$PUBLISHER" \
MPTDC_RO6_VDD_MISMATCH_CLASSIFIER="$PVS_DIR/09_classify_ro6_vdd_pin_mismatch.py" \
MPTDC_RO6_OA_PROBE_CLASSIFIER="$PVS_DIR/10_classify_ro6_oa_vdd_export_probe.py" \
MPTDC_RO6_OA_PROBE_SKILL="$PVS_DIR/probe_ro6_oa_vdd_export_contract.il" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/pass.publish.args" \
bash "$DRIVER" \
  --source-standalone-run-id "$SOURCE_ID" \
  --run-id "$RUN_ID" \
  --oa-project-dir "$PROJECT_DIR" \
  --oa-layout-dir "$OA_LAYOUT" \
  --oa-schematic-dir "$OA_SCHEMATIC" \
  --stream-layer-map "$LAYER_MAP" \
  --stream-object-map "$OBJECT_MAP" \
  --xstream-log "$XSTREAM_LOG" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'RO6_OA_VDD_EXPORT_PROBE_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'SOURCE_MISMATCH_CLASSIFICATION=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'OA_PROBE_CLASSIFICATION_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'OA_READ_ONLY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'SOURCE_EXPORT_READ_ONLY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'STREAM_COLLATERAL_READ_ONLY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'OA_VDD_EXPORT_DIAGNOSIS=VDD_EXPLICIT_LABEL_ABSENT_WHILE_VSS_LABEL_PRESENT' \
  "$TMP_ROOT/pass.stdout"
grep -qx 'OA_VDD_PIN_IGNORED_LPP_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_REVIEW_EXPORT_CONTRACT' "$TMP_ROOT/pass.stdout"
grep -qx 'NEXT_STAGE=REVIEW_ONE_VDD_LABEL_CONTRACT_REPAIR' "$TMP_ROOT/pass.stdout"
grep -q "pvs $RUN_ID $WORK/$RUN_ID RO6_OA_VDD_EXPORT_PROBE" \
  "$TMP_ROOT/pass.publish.args"
grep -qx 'OA_EXPECTED_TERMINAL_SET_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/oa_ro6_vdd_export_classification.rpt"
grep -qx 'SIGNOFF_ELIGIBLE=NO' \
  "$WORK/$RUN_ID/reports/operator_gate_ro6_oa_vdd_export_probe.rpt"

BAD_SOURCE_ID=ro6_standalone_wrong_mismatch
cp -a "$SOURCE_DIR" "$WORK/$BAD_SOURCE_ID"
sed -i 's/| 12$/| 13/' \
  "$WORK/$BAD_SOURCE_ID/pvs_lvs/RO_tune6_standalone_script/RO_tune6_lvs.sum.cls"
set +e
MPTDC_RO6_OA_PROBE_REPO_ROOT="$REPO" \
MPTDC_RO6_OA_PROBE_PUBLISHER="$PUBLISHER" \
MPTDC_RO6_VDD_MISMATCH_CLASSIFIER="$PVS_DIR/09_classify_ro6_vdd_pin_mismatch.py" \
MPTDC_RO6_OA_PROBE_CLASSIFIER="$PVS_DIR/10_classify_ro6_oa_vdd_export_probe.py" \
MPTDC_RO6_OA_PROBE_SKILL="$PVS_DIR/probe_ro6_oa_vdd_export_contract.il" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/fail.publish.args" \
bash "$DRIVER" \
  --source-standalone-run-id "$BAD_SOURCE_ID" \
  --run-id ro6_oa_vdd_probe_wrong_source \
  --oa-project-dir "$PROJECT_DIR" \
  --oa-layout-dir "$OA_LAYOUT" \
  --oa-schematic-dir "$OA_SCHEMATIC" \
  --stream-layer-map "$LAYER_MAP" \
  --stream-object-map "$OBJECT_MAP" \
  --xstream-log "$XSTREAM_LOG" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/fail.stdout" 2>&1
FAIL_RC=$?
set -e
test "$FAIL_RC" -ne 0
grep -qx 'SOURCE_MISMATCH_CLASSIFICATION=FAIL' "$TMP_ROOT/fail.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/fail.stdout"

echo "MPTDC_RO6_OA_VDD_EXPORT_PROBE_DRIVER_TEST=PASS"
