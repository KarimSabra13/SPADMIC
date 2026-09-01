#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVS_SOURCE="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_ro6_monolithic_driver.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_ID=source_raw_ro_mismatch
SOURCE_EVIDENCE_ID=source_raw_ro_mismatch_04_lvs
BOUNDARY_ID=boundary_top_match
STANDALONE_ID=ro6_standalone_match
RUN_ID=monolithic_full_top_match
SOURCE_LIVE="$WORK/$SOURCE_ID"
STANDALONE_LIVE="$WORK/$STANDALONE_ID"
SOURCE_SNAPSHOT="$REPO/MPTDC/docs/server_snapshots/pvs/$SOURCE_EVIDENCE_ID"
BOUNDARY_SNAPSHOT="$REPO/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_ID"
STANDALONE_SNAPSHOT="$REPO/MPTDC/docs/server_snapshots/pvs/$STANDALONE_ID"
DRIVER="$REPO/MPTDC/scripts/pvs/server_run_mptdc_ro6_monolithic_lvs.sh"

mkdir -p "$REPO/MPTDC/scripts/pvs" \
  "$SOURCE_SNAPSHOT/reports" "$SOURCE_SNAPSHOT/manifests" \
  "$SOURCE_SNAPSHOT/pvs_lvs/raw_script" \
  "$BOUNDARY_SNAPSHOT/reports" \
  "$STANDALONE_SNAPSHOT/reports" "$STANDALONE_SNAPSHOT/manifests" \
  "$SOURCE_LIVE/outputs" "$SOURCE_LIVE/manifests" "$SOURCE_LIVE/reports" \
  "$SOURCE_LIVE/pvs_lvs/raw_script" \
  "$STANDALONE_LIVE/inputs" "$STANDALONE_LIVE/manifests"
cp "$PVS_SOURCE/server_run_mptdc_ro6_monolithic_lvs.sh" "$DRIVER"

GDS="$SOURCE_LIVE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds"
PHYSICAL="$SOURCE_LIVE/outputs/mptdc_axis_core_pnr_lvs_phys_with_pg.v"
DCELL_CDL="$SOURCE_LIVE/inputs_dcells.cdl"
FILLER_REPORT="$SOURCE_LIVE/filler_status.rpt"
ROW_REPORT="$SOURCE_LIVE/row_infra_insertion.rpt"
RO_CDL="$STANDALONE_LIVE/inputs/RO_tune6.fresh.cdl"
printf 'merged gds fixture\n' > "$GDS"
printf 'module mptdc_axis_core; endmodule\n' > "$PHYSICAL"
printf '.SUBCKT CELL A Y\n.ENDS CELL\n' > "$DCELL_CDL"
printf 'filler fixture\n' > "$FILLER_REPORT"
printf 'row fixture\n' > "$ROW_REPORT"
printf '.SUBCKT RO_tune6 VDD VSS rstb\n.ENDS RO_tune6\n' > "$RO_CDL"
GDS_SHA="$(sha256sum "$GDS" | awk '{print $1}')"
PHYSICAL_SHA="$(sha256sum "$PHYSICAL" | awk '{print $1}')"
DCELL_SHA="$(sha256sum "$DCELL_CDL" | awk '{print $1}')"
FILLER_SHA="$(sha256sum "$FILLER_REPORT" | awk '{print $1}')"
ROW_SHA="$(sha256sum "$ROW_REPORT" | awk '{print $1}')"
RO_GDS_SHA="$(printf 'ro gds fixture\n' | sha256sum | awk '{print $1}')"
RO_CDL_SHA="$(sha256sum "$RO_CDL" | awk '{print $1}')"

cat > "$SOURCE_LIVE/manifests/pvs_input_hashes.rpt" <<EOF
MERGED_GDS_PATH=$GDS
MERGED_GDS_SHA256=$GDS_SHA
LVS_SOURCE_PHYSICAL_PG_PATH=$PHYSICAL
LVS_SOURCE_PHYSICAL_PG_SHA256=$PHYSICAL_SHA
DCELL_CDL_PATH=$DCELL_CDL
DCELL_CDL_SHA256=$DCELL_SHA
FILLER_REPORT_PATH=$FILLER_REPORT
FILLER_REPORT_SHA256=$FILLER_SHA
ROW_INFRA_REPORT_PATH=$ROW_REPORT
ROW_INFRA_REPORT_SHA256=$ROW_SHA
RO_GDS_SHA256=$RO_GDS_SHA
EOF
cat > "$SOURCE_LIVE/reports/lvs_source_filter.rpt" <<'EOF'
LVS_SOURCE_CONTRACT_STATUS=PASS
SOURCE_KIND=INNOVUS_SAVE_NETLIST_PHYS_INCLUDE_POWER_GROUND
PHYSICAL_ONLY_FILLER_REMOVAL_STATUS=PASS
RO6_PIN_NORMALIZATION=EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS
RO_TUNE6_INSTANCE_COUNT=2
RO_TUNE6_INSTANCE_NAME_STATUS=PASS
PHYSICAL_TIE_PRESERVATION_STATUS=PASS
UNRESOLVED_ACTIVE_MASTER_COUNT=0
EOF
printf 'PVS_LVS_STATUS=MISMATCH\n' > "$SOURCE_LIVE/reports/pvs_lvs_status.rpt"
printf 'PVS_LVS_RC=0\n' > "$SOURCE_LIVE/reports/pvs_lvs_tool_status.rpt"
printf '#!/bin/sh\n' > "$SOURCE_LIVE/pvs_lvs/raw_script/run.pvs"
printf 'lvs_report_file "raw.sum";\n' > "$SOURCE_LIVE/pvs_lvs/raw_script/pvslvsctl"
printf '' > "$SOURCE_LIVE/pvs_lvs/raw_script/.config.rul"
printf 'technology fixture\n' > "$SOURCE_LIVE/pvs_lvs/raw_script/.technology.rul"
cat > "$SOURCE_LIVE/pvs_lvs/raw_script/raw.cls" <<'EOF'
#####  Run Result                    :     MISMATCH
Cells that have been blackboxed              |         0
mptdc_axis_core     |       59 :        59 |       59 :        59 | mismatch     |
 (-, RO_tune6())         |        *0 :        2 |        *0 :        2
Total                    |   220,440 :  213,961 |   220,311 :  213,961 |   213,960 :  213,582 |    380 :     2
EOF
RAW_CLS_SHA="$(sha256sum "$SOURCE_LIVE/pvs_lvs/raw_script/raw.cls" | awk '{print $1}')"
cp "$SOURCE_LIVE/pvs_lvs/raw_script/raw.cls" \
  "$SOURCE_SNAPSHOT/pvs_lvs/raw_script/raw.cls"
cp "$SOURCE_LIVE/pvs_lvs/raw_script/run.pvs" \
  "$SOURCE_SNAPSHOT/pvs_lvs/raw_script/run.pvs"
cp "$SOURCE_LIVE/pvs_lvs/raw_script/pvslvsctl" \
  "$SOURCE_SNAPSHOT/pvs_lvs/raw_script/pvslvsctl"
cp "$SOURCE_LIVE/pvs_lvs/raw_script/.config.rul" \
  "$SOURCE_SNAPSHOT/pvs_lvs/raw_script/.config.rul"
cp "$SOURCE_LIVE/pvs_lvs/raw_script/.technology.rul" \
  "$SOURCE_SNAPSHOT/pvs_lvs/raw_script/.technology.rul"

cat > "$SOURCE_SNAPSHOT/reports/pvs_recovery_base_drc_classification.rpt" <<'EOF'
CLASSIFICATION_STATUS=PASS
PVS_BASE_DRC_CLASS=ANTENNA_ONLY_MANAGER_EXCEPTION
DRC_TOTAL_PRIMARY=136
NONZERO_RULE_COUNT=4
NONZERO_RULE_SET=R1M2P1,R1M3P1,R2M2P1,R2M3P1
NON_ANTENNA_RULE_COUNT=0
ANTENNA_REPAIR_ATTEMPTED=NO
EOF
cat > "$SOURCE_SNAPSHOT/reports/pvs_drc_base_nonzero_rules.tsv" <<'EOF'
rule	primary	expanded
R1M2P1	6	6
R1M3P1	68	68
R2M2P1	7	7
R2M3P1	55	55
EOF
cat > "$SOURCE_SNAPSHOT/reports/connectivity_special_before_streamout.rpt" <<'EOF'
Begin Summary
    15 Problem(s) (IMPVFC-94): The net has dangling wire(s).
End Summary
EOF
cp "$SOURCE_LIVE/manifests/pvs_input_hashes.rpt" \
  "$SOURCE_SNAPSHOT/manifests/pvs_input_hashes.rpt"
cp "$SOURCE_LIVE/reports/lvs_source_filter.rpt" \
  "$SOURCE_SNAPSHOT/reports/lvs_source_filter.rpt"
cp "$SOURCE_LIVE/reports/pvs_lvs_status.rpt" \
  "$SOURCE_SNAPSHOT/reports/pvs_lvs_status.rpt"
cp "$SOURCE_LIVE/reports/pvs_lvs_tool_status.rpt" \
  "$SOURCE_SNAPSHOT/reports/pvs_lvs_tool_status.rpt"
cat > "$BOUNDARY_SNAPSHOT/reports/operator_gate_pvs_compositional_lvs.rpt" <<EOF
SOURCE_PVS_RUN_ID=$SOURCE_ID
BOUNDARY_PVS_RUN_ID=$BOUNDARY_ID
STANDALONE_PVS_RUN_ID=$STANDALONE_ID
RAW_FULL_TOP_LVS_STATUS=MISMATCH_RO_ABSTRACTION_ONLY
PVS_TOP_BOUNDARY_LVS=MATCH
PVS_RO6_STANDALONE_LVS=MATCH
COMPOSITIONAL_LVS_STATUS=PASS
RAW_FULL_TOP_CLS_SHA256=$RAW_CLS_SHA
MERGED_GDS_SHA256=$GDS_SHA
RO_GDS_SHA256=$RO_GDS_SHA
RO_CDL_SHA256=$RO_CDL_SHA
DECISION=PASS_MONOLITHIC_LVS_CONTINUE
NEXT_STAGE=PVS_RO6_MONOLITHIC_FULL_TOP_LVS
EOF
cat > "$BOUNDARY_SNAPSHOT/reports/operator_gate_pvs_ro6_boundary_lvs.rpt" <<EOF
SOURCE_PVS_RUN_ID=$SOURCE_ID
STANDALONE_PVS_RUN_ID=$STANDALONE_ID
PVS_LVS_STATUS=MATCH
BOUNDARY_REMAINDER_CLASS=NONE_MATCH
SIGNOFF_ELIGIBLE=NO
DECISION=PASS_COMPOSITIONAL_LVS
NEXT_STAGE=PVS_RO6_MONOLITHIC_FULL_TOP_LVS
EOF
cat > "$STANDALONE_SNAPSHOT/reports/operator_gate_pvs_ro6_standalone_lvs.rpt" <<'EOF'
PVS_LVS=MATCH
CLS_RUN_RESULT=MATCH
BLACKBOXED_CELL_COUNT=0
OA_READ_ONLY_STATUS=PASS
RO6_CDL_PIN_CONTRACT_STATUS=PASS
DECISION=PASS_CONTINUE
EOF
cat > "$STANDALONE_SNAPSHOT/manifests/ro6_standalone_lvs_inputs.rpt" <<EOF
RO_GDS_SHA256=$RO_GDS_SHA
RO_CDL_SHA256=$RO_CDL_SHA
EOF
cat > "$STANDALONE_LIVE/manifests/ro6_standalone_lvs_inputs.rpt" <<EOF
LOCAL_RO_CDL=$RO_CDL
RO_GDS_SHA256=$RO_GDS_SHA
RO_CDL_SHA256=$RO_CDL_SHA
EOF

GENERATOR="$TMP_ROOT/source_generator.py"
cat > "$GENERATOR" <<'PY'
#!/usr/bin/env python3
import argparse
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("--output", type=Path, required=True)
p.add_argument("--report", type=Path, required=True)
p.add_argument("--ro-cdl", type=Path, required=True)
p.add_argument("--hcell", type=Path, required=True)
p.add_argument("--input")
p.add_argument("--cdl")
p.add_argument("--filler-report")
p.add_argument("--row-infra-report")
p.add_argument("--ro-model")
p.add_argument("--expected-ro-instance", action="append")
a = p.parse_args()
a.output.write_text("module mptdc_axis_core; endmodule\n")
import hashlib
digest = hashlib.sha256(a.ro_cdl.read_bytes()).hexdigest()
a.report.write_text(
    "LVS_SOURCE_CONTRACT_STATUS=PASS\n"
    "RO_MODEL_MODE=EXTERNAL_CDL\n"
    "RO_TUNE6_WRAPPER_MODULE_COUNT=0\n"
    "LVS_HCELL_STATUS=NOT_USED\n"
    "LVS_HCELL_ENTRY_COUNT=0\n"
    "RO_EXTERNAL_CDL_PIN_STATUS=PASS\n"
    f"RO_EXTERNAL_CDL_SHA256={digest}\n"
)
PY

PREP="$TMP_ROOT/prep.py"
cat > "$PREP" <<'PY'
#!/usr/bin/env python3
import argparse
from pathlib import Path
p = argparse.ArgumentParser()
p.add_argument("--run-dir", type=Path, required=True)
for name in ("template-run", "gds", "source", "dcell-cdl", "ro-cdl"):
    p.add_argument(f"--{name}")
a = p.parse_args()
a.run_dir.mkdir(parents=True)
(a.run_dir / "run.pvs").write_text("#!/bin/sh\nexit 0\n")
(a.run_dir / "pvslvsctl").write_text("control\n")
print("RO6_MONOLITHIC_PREP_STATUS=PASS")
PY

GATE="$TMP_ROOT/gate.py"
cat > "$GATE" <<'PY'
#!/usr/bin/env python3
import argparse
import hashlib
from pathlib import Path
p = argparse.ArgumentParser()
p.add_argument("--out", type=Path, required=True)
p.add_argument("--gds", type=Path, required=True)
p.add_argument("--source", type=Path, required=True)
p.add_argument("--dcell-cdl")
p.add_argument("--ro-cdl")
p.add_argument("--run-dir")
p.add_argument("--pvs-rc")
a = p.parse_args()
gds_sha = hashlib.sha256(a.gds.read_bytes()).hexdigest()
a.out.write_text(
    "STATUS=PASS\n"
    "MONOLITHIC_LVS_STATUS=MATCH\n"
    "LVS_BLACKBOXED_CELL_COUNT=0\n"
    "LVS_HCELL_STATUS=NOT_USED\n"
    "CLS_RUN_RESULT=MATCH\n"
    "CELLS_WHICH_MISMATCH=0\n"
    "TOP_59_PIN_MATCH_STATUS=PASS\n"
    "RO6_19_PIN_MATCH_STATUS=PASS\n"
    "MISSING_INSTANCE_EVIDENCE_COUNT=0\n"
    "SHORT_OPEN_EVIDENCE_STATUS=PASS\n"
    "LVS_SIGNOFF_ELIGIBLE=YES\n"
    f"MERGED_GDS_SHA256={gds_sha}\n"
)
PY

RAW_CLASSIFIER="$TMP_ROOT/raw_classifier.py"
cat > "$RAW_CLASSIFIER" <<'PY'
#!/usr/bin/env python3
import argparse
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("--cls")
p.add_argument("--out", type=Path, required=True)
p.add_argument("--expected-ro-instance", action="append")
a = p.parse_args()
a.out.write_text(
    "STATUS=PASS\n"
    "MISMATCH_ATTRIBUTION=EXACT_TWO_RO6_INTERNALS_ONLY\n"
    "DIRECT_MONOLITHIC_ELIGIBLE=YES\n"
    "LAYOUT_ONLY_INSTANCE_COUNT=380\n"
    "SOURCE_ONLY_INSTANCE_COUNT=2\n"
)
print("RAW_LVS_MISMATCH_CLASSIFICATION_STATUS=PASS")
PY

PUBLISHER="$TMP_ROOT/publisher.sh"
cat > "$PUBLISHER" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${PUBLISH_ARGS:?}"
exit 0
EOF
CADENCE_ENV="$TMP_ROOT/cadence.env"
printf ':\n' > "$CADENCE_ENV"
chmod +x "$DRIVER" "$GENERATOR" "$PREP" "$GATE" "$RAW_CLASSIFIER" "$PUBLISHER"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC monolithic LVS test'
git -C "$REPO" config user.email 'mptdc-monolithic@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

MPTDC_MONOLITHIC_LVS_REPO_ROOT="$REPO" \
MPTDC_MONOLITHIC_LVS_SOURCE_GENERATOR="$GENERATOR" \
MPTDC_MONOLITHIC_LVS_PREP="$PREP" \
MPTDC_MONOLITHIC_LVS_GATE="$GATE" \
MPTDC_MONOLITHIC_LVS_RAW_CLASSIFIER="$RAW_CLASSIFIER" \
MPTDC_MONOLITHIC_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" PUBLISH_ARGS="$TMP_ROOT/publish.args" \
bash "$DRIVER" --source-pvs-run-id "$SOURCE_ID" \
  --source-pvs-evidence-id "$SOURCE_EVIDENCE_ID" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id "$RUN_ID" --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'PVS_RO6_MONOLITHIC_PREFLIGHT=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'PVS_RO6_MONOLITHIC_STATUS=MATCH' "$TMP_ROOT/pass.stdout"
grep -qx 'LVS_BLACKBOXED_CELL_COUNT=0' "$TMP_ROOT/pass.stdout"
grep -qx 'LVS_HCELL_STATUS=NOT_USED' "$TMP_ROOT/pass.stdout"
grep -qx 'CLS_RUN_RESULT=MATCH' \
  "$WORK/$RUN_ID/reports/operator_gate_pvs_monolithic_lvs.rpt"
grep -qx 'CELLS_WHICH_MISMATCH=0' \
  "$WORK/$RUN_ID/reports/operator_gate_pvs_monolithic_lvs.rpt"
grep -qx 'TOP_59_PIN_MATCH_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_pvs_monolithic_lvs.rpt"
grep -qx 'RO6_19_PIN_MATCH_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_pvs_monolithic_lvs.rpt"
grep -qx 'SHORT_OPEN_EVIDENCE_STATUS=PASS' \
  "$WORK/$RUN_ID/reports/operator_gate_pvs_monolithic_lvs.rpt"
grep -qx 'LVS_SIGNOFF_ELIGIBLE=YES' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_MONOLITHIC_LVS' "$TMP_ROOT/pass.stdout"
grep -qx 'FINAL_PHYSICAL_SIGNOFF_READY=NO' "$TMP_ROOT/pass.stdout"
grep -q "pvs $RUN_ID $WORK/$RUN_ID PVS_RO6_MONOLITHIC_LVS" "$TMP_ROOT/publish.args"
test ! -e "$WORK/$RUN_ID/outputs/pvs_hcell_ro6.NOT_USED"
grep -qx 'MONOLITHIC_LVS_STATUS=MATCH' \
  "$WORK/$RUN_ID/reports/mptdc_lvs_drc_handoff_status.rpt"
grep -qx 'ANTENNA_EXCEPTION_EVIDENCE_KIND=AUTO_CLASSIFIED_NOT_INDEPENDENTLY_SIGNED' \
  "$WORK/$RUN_ID/reports/mptdc_lvs_drc_handoff_status.rpt"
grep -qx 'INNOVUS_SPECIAL_CONNECTIVITY_STATUS=FAIL_15_DANGLING' \
  "$WORK/$RUN_ID/reports/mptdc_lvs_drc_handoff_status.rpt"

DIRECT_RUN_ID=monolithic_direct_full_top_match
MPTDC_MONOLITHIC_LVS_REPO_ROOT="$REPO" \
MPTDC_MONOLITHIC_LVS_SOURCE_GENERATOR="$GENERATOR" \
MPTDC_MONOLITHIC_LVS_PREP="$PREP" \
MPTDC_MONOLITHIC_LVS_GATE="$GATE" \
MPTDC_MONOLITHIC_LVS_RAW_CLASSIFIER="$RAW_CLASSIFIER" \
MPTDC_MONOLITHIC_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" PUBLISH_ARGS="$TMP_ROOT/publish_direct.args" \
bash "$DRIVER" --source-pvs-run-id "$SOURCE_ID" \
  --source-pvs-evidence-id "$SOURCE_EVIDENCE_ID" \
  --direct-full-top \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id "$DIRECT_RUN_ID" --expected-head "$HEAD_SHA" > "$TMP_ROOT/direct.stdout"

grep -qx 'PVS_RO6_MONOLITHIC_PREFLIGHT=PASS' "$TMP_ROOT/direct.stdout"
grep -qx 'LVS_PREREQUISITE_MODE=DIRECT_FULL_TOP_WITH_STANDALONE_RO_PROOF' \
  "$TMP_ROOT/direct.stdout"
grep -qx 'BOUNDARY_PVS_RUN_ID=NOT_USED_DIRECT_FULL_TOP' "$TMP_ROOT/direct.stdout"
grep -qx 'BOUNDARY_PROOF_STATUS=NOT_REQUIRED_BY_DIRECT_MONOLITHIC_PROOF' \
  "$TMP_ROOT/direct.stdout"
grep -qx 'DECISION=PASS_MONOLITHIC_LVS' "$TMP_ROOT/direct.stdout"
grep -qx 'RAW_MISMATCH_ATTRIBUTION=EXACT_TWO_RO6_INTERNALS_ONLY' \
  "$WORK/$DIRECT_RUN_ID/reports/operator_gate_pvs_monolithic_lvs.rpt"
grep -qx 'STATUS=PASS' \
  "$WORK/$DIRECT_RUN_ID/reports/pvs_ro6_raw_mismatch_attribution.rpt"
grep -q "pvs $DIRECT_RUN_ID $WORK/$DIRECT_RUN_ID PVS_RO6_MONOLITHIC_LVS" \
  "$TMP_ROOT/publish_direct.args"

printf '# deliberate live CLS drift\n' >> "$SOURCE_LIVE/pvs_lvs/raw_script/raw.cls"
set +e
MPTDC_MONOLITHIC_LVS_REPO_ROOT="$REPO" \
MPTDC_MONOLITHIC_LVS_SOURCE_GENERATOR="$GENERATOR" \
MPTDC_MONOLITHIC_LVS_PREP="$PREP" \
MPTDC_MONOLITHIC_LVS_GATE="$GATE" \
MPTDC_MONOLITHIC_LVS_RAW_CLASSIFIER="$RAW_CLASSIFIER" \
MPTDC_MONOLITHIC_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" PUBLISH_ARGS="$TMP_ROOT/publish_cls_drift.args" \
bash "$DRIVER" --source-pvs-run-id "$SOURCE_ID" \
  --source-pvs-evidence-id "$SOURCE_EVIDENCE_ID" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id monolithic_live_cls_drift --expected-head "$HEAD_SHA" \
  > "$TMP_ROOT/cls_drift.stdout" 2>&1
CLS_DRIFT_RC=$?
set -e
test "$CLS_DRIFT_RC" -eq 4
grep -qx 'PVS_RO6_MONOLITHIC_PREFLIGHT=FAIL' "$TMP_ROOT/cls_drift.stdout"
grep -Fq 'live source CLS differs from its published snapshot' \
  "$TMP_ROOT/cls_drift.stdout"
test ! -e "$WORK/monolithic_live_cls_drift"
test ! -e "$TMP_ROOT/publish_cls_drift.args"
sed -i '$d' "$SOURCE_LIVE/pvs_lvs/raw_script/raw.cls"

printf '# deliberate live-evidence drift\n' >> \
  "$SOURCE_LIVE/reports/lvs_source_filter.rpt"
set +e
MPTDC_MONOLITHIC_LVS_REPO_ROOT="$REPO" \
MPTDC_MONOLITHIC_LVS_SOURCE_GENERATOR="$GENERATOR" \
MPTDC_MONOLITHIC_LVS_PREP="$PREP" \
MPTDC_MONOLITHIC_LVS_GATE="$GATE" \
MPTDC_MONOLITHIC_LVS_RAW_CLASSIFIER="$RAW_CLASSIFIER" \
MPTDC_MONOLITHIC_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" PUBLISH_ARGS="$TMP_ROOT/publish_live_drift.args" \
bash "$DRIVER" --source-pvs-run-id "$SOURCE_ID" \
  --source-pvs-evidence-id "$SOURCE_EVIDENCE_ID" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id monolithic_live_evidence_drift --expected-head "$HEAD_SHA" \
  > "$TMP_ROOT/live_drift.stdout" 2>&1
LIVE_DRIFT_RC=$?
set -e
test "$LIVE_DRIFT_RC" -eq 4
grep -qx 'PVS_RO6_MONOLITHIC_PREFLIGHT=FAIL' "$TMP_ROOT/live_drift.stdout"
grep -Fq 'live source evidence differs from its published snapshot' \
  "$TMP_ROOT/live_drift.stdout"
test ! -e "$WORK/monolithic_live_evidence_drift"
test ! -e "$TMP_ROOT/publish_live_drift.args"
sed -i '$d' "$SOURCE_LIVE/reports/lvs_source_filter.rpt"

sed -i 's/^RO_CDL_SHA256=.*/RO_CDL_SHA256=ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff/' \
  "$BOUNDARY_SNAPSHOT/reports/operator_gate_pvs_compositional_lvs.rpt"
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m boundary-hash-drift
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"
set +e
MPTDC_MONOLITHIC_LVS_REPO_ROOT="$REPO" \
MPTDC_MONOLITHIC_LVS_SOURCE_GENERATOR="$GENERATOR" \
MPTDC_MONOLITHIC_LVS_PREP="$PREP" \
MPTDC_MONOLITHIC_LVS_GATE="$GATE" \
MPTDC_MONOLITHIC_LVS_RAW_CLASSIFIER="$RAW_CLASSIFIER" \
MPTDC_MONOLITHIC_LVS_PUBLISHER="$PUBLISHER" \
MPTDC_CADENCE_ENV="$CADENCE_ENV" \
MPTDC_INNOVUS_WORK="$WORK" PUBLISH_ARGS="$TMP_ROOT/publish_drift.args" \
bash "$DRIVER" --source-pvs-run-id "$SOURCE_ID" \
  --source-pvs-evidence-id "$SOURCE_EVIDENCE_ID" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --standalone-pvs-run-id "$STANDALONE_ID" \
  --run-id monolithic_hash_drift --expected-head "$HEAD_SHA" \
  > "$TMP_ROOT/drift.stdout" 2>&1
DRIFT_RC=$?
set -e
test "$DRIFT_RC" -eq 4
grep -qx 'PVS_RO6_MONOLITHIC_PREFLIGHT=FAIL' "$TMP_ROOT/drift.stdout"
grep -Fq 'boundary hashes disagree with source and standalone evidence' "$TMP_ROOT/drift.stdout"
test ! -e "$WORK/monolithic_hash_drift"
test ! -e "$TMP_ROOT/publish_drift.args"

echo 'MPTDC_RO6_MONOLITHIC_LVS_DRIVER_TEST=PASS'
