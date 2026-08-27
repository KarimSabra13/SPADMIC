#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REAL_REPO="$(cd "$PVS_DIR/../../.." && pwd)"
REAL_PROBE="$REAL_REPO/MPTDC/docs/server_snapshots/pvs/20260827_mptdc_ro6_oa_vdd_export_probe_v2_141033"
TMP_ROOT="$(mktemp -d /tmp/mptdc_ro6_oa_vdd_repair.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

SKILL="$PVS_DIR/repair_ro6_oa_vdd_pin_label.il"
grep -Fq 'dbOpenCellViewByType(libName cellName viewName "" "a")' "$SKILL"
grep -Fq 'dbCreatePin(vddNet targetFig nil vddTerm)' "$SKILL"
grep -Fq 'cv list("MET3" "TEXT") list(-67.685 -31.0325)' "$SKILL"
grep -Fq 'EXACT_RO6_VDD_METTP_PIN_LABEL_BACKUP_VERIFIED' "$SKILL"
if grep -Eq 'db(CreateRect|CreatePolygon|CreatePath|DeleteObject|MoveFig)' "$SKILL"; then
  echo "ERROR: RO6 VDD repair contains a forbidden geometry mutation" >&2
  exit 1
fi

python3 "$PVS_DIR/11_classify_ro6_oa_vdd_pin_label_repair.py" \
  --operator-gate "$REAL_PROBE/reports/operator_gate_ro6_oa_vdd_export_probe.rpt" \
  --classification "$REAL_PROBE/reports/oa_ro6_vdd_export_classification.rpt" \
  --cell-summary "$REAL_PROBE/reports/oa_ro6_cell_summary.rpt" \
  --terminal-figs "$REAL_PROBE/reports/oa_ro6_terminal_pin_figs.tsv" \
  --label-shapes "$REAL_PROBE/reports/oa_ro6_label_shapes.tsv" \
  --supply-nets "$REAL_PROBE/reports/oa_ro6_supply_nets.tsv" \
  --supply-shapes "$REAL_PROBE/reports/oa_ro6_supply_top_shapes.tsv" \
  --out "$TMP_ROOT/real_repair_contract.rpt"
grep -qx 'REPAIR_CONTRACT_STATUS=PASS' "$TMP_ROOT/real_repair_contract.rpt"
grep -qx 'TARGET_SHAPE_COUNT=1' "$TMP_ROOT/real_repair_contract.rpt"
grep -qx 'TARGET_DRAWING_STACK_LAYER_SET=MET1,MET2,MET3' \
  "$TMP_ROOT/real_repair_contract.rpt"

cp -p "$REAL_PROBE/reports/oa_ro6_cell_summary.rpt" "$TMP_ROOT/readback_cell.rpt"
awk 'BEGIN {FS=OFS="\t"}
  $1 == "VDD" {$4=0; $5=0; $6="rect"; $7="METTP"; $8="pin";
                $9="-68.700000"; $10="-31.950000";
                $11="-66.670000"; $12="-30.115000"; $13="ABSENT"}
  {print}' "$REAL_PROBE/reports/oa_ro6_terminal_pin_figs.tsv" \
  > "$TMP_ROOT/readback_terminal_figs.tsv"
cp -p "$REAL_PROBE/reports/oa_ro6_label_shapes.tsv" "$TMP_ROOT/readback_labels.tsv"
printf 'label\tVDD\tABSENT\tMET3\tTEXT\t-67.824000\t-31.082500\t-67.546000\t-30.982500\n' \
  >> "$TMP_ROOT/readback_labels.tsv"
python3 "$PVS_DIR/10_classify_ro6_oa_vdd_export_probe.py" \
  --cell-summary "$TMP_ROOT/readback_cell.rpt" \
  --terminal-figs "$TMP_ROOT/readback_terminal_figs.tsv" \
  --label-shapes "$TMP_ROOT/readback_labels.tsv" \
  --supply-nets "$REAL_PROBE/reports/oa_ro6_supply_nets.tsv" \
  --supply-shapes "$REAL_PROBE/reports/oa_ro6_supply_top_shapes.tsv" \
  --candidate-shapes "$REAL_PROBE/reports/oa_ro6_vdd_candidate_shapes.tsv" \
  --out "$TMP_ROOT/readback_classification.rpt"
grep -qx 'OA_EMPTY_GLOBAL_ALIAS_STATUS=PASS' "$TMP_ROOT/readback_classification.rpt"
grep -qx 'OA_TERMINAL_CONTRACT_STATUS=PASS' "$TMP_ROOT/readback_classification.rpt"
grep -qx 'OA_VDD_EXPORT_DIAGNOSIS=VDD_PIN_LABEL_CONTRACT_PRESENT' \
  "$TMP_ROOT/readback_classification.rpt"

REPO="$TMP_ROOT/repo"
WORK_ROOT="$TMP_ROOT/work_root"
WORK="$WORK_ROOT/innovus"
SOURCE_ID=ro6_oa_vdd_probe_source
SOURCE_DIR="$WORK/$SOURCE_ID"
OA_ROOT="$TMP_ROOT/oa/RO_tune6"
OA_LAYOUT="$OA_ROOT/layout"
OA_SCHEMATIC="$OA_ROOT/schematic"
PROJECT_DIR="$TMP_ROOT/cds_V0"
EXPORT_DIR="$TMP_ROOT/exports"
RO_GDS="$EXPORT_DIR/RO_tune6.gds"
RO_CDL="$EXPORT_DIR/RO_tune6.cdl"
BIN_DIR="$TMP_ROOT/bin"
CADENCE_ENV="$TMP_ROOT/cadence_env.sh"
PUBLISHER="$TMP_ROOT/publisher_stub.sh"
DRIVER="$REPO/MPTDC/scripts/pvs/server_apply_mptdc_ro6_oa_vdd_pin_label_repair.sh"

mkdir -p "$REPO/MPTDC/scripts/pvs" "$SOURCE_DIR/reports" \
  "$SOURCE_DIR/manifests" "$OA_LAYOUT" "$OA_SCHEMATIC" "$PROJECT_DIR" \
  "$EXPORT_DIR" "$BIN_DIR"
cp -p "$PVS_DIR/server_apply_mptdc_ro6_oa_vdd_pin_label_repair.sh" "$DRIVER"
cp -p "$PVS_DIR/10_classify_ro6_oa_vdd_export_probe.py" \
  "$PVS_DIR/11_classify_ro6_oa_vdd_pin_label_repair.py" \
  "$PVS_DIR/repair_ro6_oa_vdd_pin_label.il" \
  "$PVS_DIR/probe_ro6_oa_vdd_export_contract.il" \
  "$REPO/MPTDC/scripts/pvs/"
cp -p "$REAL_PROBE/reports/operator_gate_ro6_oa_vdd_export_probe.rpt" \
  "$REAL_PROBE/reports/oa_ro6_vdd_export_classification.rpt" \
  "$REAL_PROBE/reports/oa_ro6_cell_summary.rpt" \
  "$REAL_PROBE/reports/oa_ro6_terminal_pin_figs.tsv" \
  "$REAL_PROBE/reports/oa_ro6_label_shapes.tsv" \
  "$REAL_PROBE/reports/oa_ro6_supply_nets.tsv" \
  "$REAL_PROBE/reports/oa_ro6_supply_top_shapes.tsv" \
  "$REAL_PROBE/reports/stream_layer_map_ro6_excerpt.rpt" \
  "$SOURCE_DIR/reports/"
printf 'layout fixture before repair\n' > "$OA_LAYOUT/master.tag"
printf 'schematic fixture remains immutable\n' > "$OA_SCHEMATIC/master.tag"
printf 'immutable source GDS\n' > "$RO_GDS"
printf '.SUBCKT RO_tune6 VDD VSS\n.ENDS\n' > "$RO_CDL"

oa_content_fingerprint() {
  local root="$1"
  (
    cd "$root"
    find . -type f -print0 | LC_ALL=C sort -z \
      | while IFS= read -r -d '' file; do
          printf '%s\t' "$file"
          sha256sum "$file"
        done
  ) | sha256sum | awk '{print $1}'
}
LAYOUT_HASH="$(oa_content_fingerprint "$OA_LAYOUT")"
SCHEMATIC_HASH="$(oa_content_fingerprint "$OA_SCHEMATIC")"
GDS_HASH="$(sha256sum "$RO_GDS" | awk '{print $1}')"
CDL_HASH="$(sha256sum "$RO_CDL" | awk '{print $1}')"
cat > "$SOURCE_DIR/manifests/ro6_oa_vdd_export_probe_inputs.rpt" <<EOF
OA_LAYOUT_CONTENT_POST=$LAYOUT_HASH
OA_SCHEMATIC_CONTENT_POST=$SCHEMATIC_HASH
SOURCE_GDS=$RO_GDS
SOURCE_GDS_SHA256=$GDS_HASH
SOURCE_CDL=$RO_CDL
SOURCE_CDL_SHA256=$CDL_HASH
EOF

cat > "$BIN_DIR/virtuoso" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if printf '%s\n' "$*" | grep -q 'repair_ro6_oa_vdd_pin_label.il'; then
  printf 'layout fixture repaired\n' >> "${MPTDC_TEST_OA_LAYOUT:?}/master.tag"
  cat > "${MPTDC_RO6_OA_REPAIR_REPORT:?}" <<'RPT'
STEP=RO6_OA_VDD_PIN_LABEL_REPAIR
STATUS=PASS
TARGET=Prj_xh018_ksabra/RO_tune6/layout
TARGET_NET=VDD
TARGET_LAYER=METTP
TARGET_PURPOSE=pin
TARGET_BOX=-68.700000,-31.950000,-66.670000,-30.115000
LABEL_LAYER=MET3
LABEL_PURPOSE=TEXT
LABEL_TEXT=VDD
LABEL_ORIGIN=-67.685000,-31.032500
PRE_VDD_PIN_COUNT=0
POST_VDD_PIN_COUNT=1
PRE_VDD_LABEL_COUNT=0
POST_VDD_LABEL_COUNT=1
CREATED_METAL_SHAPE_COUNT=0
DELETED_OBJECT_COUNT=0
MOVED_OBJECT_COUNT=0
RENAMED_NET_COUNT=0
RENAMED_TERMINAL_COUNT=0
GLOBAL_ALIAS_EDIT_COUNT=0
SCHEMATIC_EDIT_COUNT=0
OA_REPAIR_STATUS=PASS
RPT
  printf 'STEP=RO6_OA_VDD_PIN_LABEL_REPAIR\nOA_REPAIR_STATUS=PASS\n' \
    > "${MPTDC_RO6_OA_REPAIR_STATUS:?}"
  exit 0
fi

root="${MPTDC_RO6_OA_PROBE_ROOT:?}"
cat > "$root/oa_ro6_cell_summary.rpt" <<'RPT'
STEP=RO6_OA_VDD_EXPORT_PROBE
OA_OPEN_MODE=READ_ONLY
OA_EDIT_AUTHORIZED=NO
LIBRARY=Prj_xh018_ksabra
CELL=RO_tune6
VIEW=layout
TERMINAL_COUNT=21
TERMINAL_NAME=S<0>
TERMINAL_NAME=S<1>
TERMINAL_NAME=S<2>
TERMINAL_NAME=S<3>
TERMINAL_NAME=S<4>
TERMINAL_NAME=S<5>
TERMINAL_NAME=S<6>
TERMINAL_NAME=S<7>
TERMINAL_NAME=code<0>
TERMINAL_NAME=code<1>
TERMINAL_NAME=code<2>
TERMINAL_NAME=code<3>
TERMINAL_NAME=code<4>
TERMINAL_NAME=code<5>
TERMINAL_NAME=code<6>
TERMINAL_NAME=code<7>
TERMINAL_NAME=rstb
TERMINAL_NAME=VDD
TERMINAL_NAME=VSS
TERMINAL_NAME=gnd!
TERMINAL_NAME=vdd!
RPT
printf 'terminal\tdirection\tnet\tpin_index\tfig_index\tobj_type\tlayer\tpurpose\tllx\tlly\turx\tury\ttext\n' \
  > "$root/oa_ro6_terminal_pin_figs.tsv"
for index in 0 1 2 3 4 5 6 7; do
  printf 'code<%s>\tinput\tcode<%s>\t0\t0\trect\tMET1\tpin\t0\t0\t1\t1\tABSENT\n' "$index" "$index" \
    >> "$root/oa_ro6_terminal_pin_figs.tsv"
  printf 'S<%s>\toutput\tS<%s>\t0\t0\trect\tMET2\tpin\t0\t0\t1\t1\tABSENT\n' "$index" "$index" \
    >> "$root/oa_ro6_terminal_pin_figs.tsv"
done
cat >> "$root/oa_ro6_terminal_pin_figs.tsv" <<'TSV'
rstb	input	rstb	0	0	rect	MET2	pin	0	0	1	1	ABSENT
VDD	inputOutput	VDD	0	0	rect	METTP	pin	-68.700000	-31.950000	-66.670000	-30.115000	ABSENT
VSS	inputOutput	VSS	0	0	rect	METTP	pin	-68.695000	-53.315000	-67.015000	-45.650000	ABSENT
VSS	inputOutput	VSS	1	0	rect	MET1	pin	-68.695000	-53.315000	-67.015000	-45.650000	ABSENT
gnd!	inputOutput	gnd!	-1	-1	ABSENT	ABSENT	ABSENT	UNKNOWN	UNKNOWN	UNKNOWN	UNKNOWN	ABSENT
vdd!	inputOutput	vdd!	-1	-1	ABSENT	ABSENT	ABSENT	UNKNOWN	UNKNOWN	UNKNOWN	UNKNOWN	ABSENT
TSV
cat > "$root/oa_ro6_label_shapes.tsv" <<'TSV'
obj_type	text	net	layer	purpose	llx	lly	urx	ury
label	VSS	ABSENT	MET1	TEXT	-68.594	-53.235	-68.316	-53.135
label	VDD	ABSENT	MET3	TEXT	-67.824	-31.0825	-67.546	-30.9825
TSV
cat > "$root/oa_ro6_supply_nets.tsv" <<'TSV'
net	top_terminal_count	instance_terminal_count
vdd!	10	10
gnd!	9	9
VDD	1	1
VSS	1	1
TSV
cat > "$root/oa_ro6_supply_top_shapes.tsv" <<'TSV'
obj_type	net	layer	purpose	llx	lly	urx	ury	text
rect	VDD	MET1	drawing	-68.700000	-31.950000	-66.670000	-30.115000	ABSENT
rect	VDD	MET2	drawing	-68.700000	-31.950000	-66.670000	-30.115000	ABSENT
rect	VDD	MET3	drawing	-68.700000	-31.950000	-66.670000	-30.115000	ABSENT
rect	VDD	METTP	pin	-68.700000	-31.950000	-66.670000	-30.115000	ABSENT
rect	VSS	MET1	pin	-68.695000	-53.315000	-67.015000	-45.650000	ABSENT
TSV
cat > "$root/oa_ro6_vdd_candidate_shapes.tsv" <<'TSV'
obj_type	net	layer	purpose	llx	lly	urx	ury	text
rect	ABSENT	prBoundary	boundary	-68.700000	-88.515000	100.245000	-18.015000	ABSENT
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
git -C "$REPO" config user.name 'MPTDC RO6 OA VDD repair test'
git -C "$REPO" config user.email 'mptdc-ro6-oa-repair@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

set +e
MPTDC_RO6_OA_REPAIR_REPO_ROOT="$REPO" \
MPTDC_RO6_OA_REPAIR_PUBLISHER="$PUBLISHER" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_WORK_ROOT="$WORK_ROOT" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_OA_LAYOUT="$OA_LAYOUT" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/unauthorized.publish.args" \
bash "$DRIVER" \
  --source-probe-run-id "$SOURCE_ID" \
  --run-id unauthorized_repair \
  --authorization NO \
  --oa-project-dir "$PROJECT_DIR" \
  --oa-layout-dir "$OA_LAYOUT" \
  --oa-schematic-dir "$OA_SCHEMATIC" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/unauthorized.stdout" 2>&1
UNAUTHORIZED_RC=$?
set -e
test "$UNAUTHORIZED_RC" -eq 4
grep -qx 'RO6_OA_VDD_PIN_LABEL_REPAIR_PREFLIGHT=FAIL' "$TMP_ROOT/unauthorized.stdout"
test "$(wc -l < "$OA_LAYOUT/master.tag")" -eq 1
test ! -e "$WORK_ROOT/handoff/oa_backups/RO_tune6/unauthorized_repair_pre_repair"

RUN_ID=ro6_oa_vdd_pin_label_repair_pass
MPTDC_RO6_OA_REPAIR_REPO_ROOT="$REPO" \
MPTDC_RO6_OA_REPAIR_PUBLISHER="$PUBLISHER" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_WORK_ROOT="$WORK_ROOT" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_OA_LAYOUT="$OA_LAYOUT" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/pass.publish.args" \
bash "$DRIVER" \
  --source-probe-run-id "$SOURCE_ID" \
  --run-id "$RUN_ID" \
  --authorization EXACT_RO6_VDD_METTP_PIN_LABEL_REPAIR \
  --oa-project-dir "$PROJECT_DIR" \
  --oa-layout-dir "$OA_LAYOUT" \
  --oa-schematic-dir "$OA_SCHEMATIC" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'RO6_OA_VDD_PIN_LABEL_REPAIR_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'BACKUP_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'OA_REPAIR_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'OA_REPAIR_ACTION_CONTRACT_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'READBACK_TERMINAL_CONTRACT_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'READBACK_VDD_EXPORT_DIAGNOSIS=VDD_PIN_LABEL_CONTRACT_PRESENT' \
  "$TMP_ROOT/pass.stdout"
grep -qx 'OA_MUTATION_SCOPE_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_CONTINUE' "$TMP_ROOT/pass.stdout"
grep -qx 'NEXT_STAGE=EXPORT_FRESH_RO6_GDS_AND_RERUN_STANDALONE_LVS' \
  "$TMP_ROOT/pass.stdout"
grep -q "pvs $RUN_ID $WORK/$RUN_ID RO6_OA_VDD_PIN_LABEL_REPAIR" \
  "$TMP_ROOT/pass.publish.args"
BACKUP_ROOT="$WORK_ROOT/handoff/oa_backups/RO_tune6/${RUN_ID}_pre_repair"
grep -qx 'layout fixture before repair' "$BACKUP_ROOT/oa/RO_tune6/layout/master.tag"
grep -qx 'layout fixture repaired' "$OA_LAYOUT/master.tag"
grep -qx 'STATUS=PASS' "$BACKUP_ROOT/manifests/backup_status.rpt"

echo "MPTDC_RO6_OA_VDD_PIN_LABEL_REPAIR_DRIVER_TEST=PASS"
