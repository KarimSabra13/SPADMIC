#!/usr/bin/env bash
# Run density DRC only after attributable monolithic full-top LVS proof.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_DENSITY_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
DRC_REPLAY="${MPTDC_DENSITY_DRC_REPLAY:-$SCRIPT_DIR/02_replay_pvs_drc_from_template.sh}"
CLASSIFIER="${MPTDC_DENSITY_CLASSIFIER:-$SCRIPT_DIR/12_classify_mptdc_density_delta.py}"
PUBLISHER="${MPTDC_DENSITY_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"

SOURCE_PVS_RUN_ID=""
SOURCE_PVS_EVIDENCE_ID=""
BOUNDARY_PVS_RUN_ID=""
STANDALONE_PVS_RUN_ID=""
MONOLITHIC_PVS_RUN_ID=""
PVS_RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
DIRECT_FULL_TOP=0

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_ro6_density_after_boundary.sh \
    --source-pvs-run-id <id> --source-pvs-evidence-id <id> \
    [--boundary-pvs-run-id <id> | --direct-full-top] \
    --standalone-pvs-run-id <id> \
    --monolithic-pvs-run-id <id> [options]

Options:
  --run-id <id>          New density-only result directory.
  --direct-full-top      Accept a monolithic proof produced by the direct
                         no-HCell full-top path, without a boundary run.
  --source-pvs-evidence-id <id>
                         Published final source snapshot. Defaults to
                         <source-pvs-run-id>_04_lvs.
  --expected-head <sha>  Require repository HEAD.
  --innovus-work <path>  Innovus/PVS result root.

The source base DRC, standalone RO LVS, monolithic full-top LVS, GDS/CDL
hashes, and antenna signature must all agree. Boundary LVS is mandatory only
for legacy-mode monolithic evidence. This stage never attempts antenna or
density repair.
USAGE
}

report_value() {
  local report="$1" key="$2" value
  value="$(sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1)"
  [[ -n "$value" ]] && printf '%s\n' "$value" || printf 'MISSING\n'
}

tracked_report() {
  local report="$1" rel="${1#"$REPO_ROOT"/}"
  git -C "$REPO_ROOT" ls-files --error-unmatch "$rel" >/dev/null 2>&1 && [[ -s "$report" ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-pvs-run-id) SOURCE_PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --source-pvs-evidence-id) SOURCE_PVS_EVIDENCE_ID="${2:?missing value}"; shift 2 ;;
    --boundary-pvs-run-id) BOUNDARY_PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --standalone-pvs-run-id) STANDALONE_PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --monolithic-pvs-run-id) MONOLITHIC_PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --direct-full-top) DIRECT_FULL_TOP=1; shift ;;
    --run-id) PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_PVS_EVIDENCE_ID" ]] || SOURCE_PVS_EVIDENCE_ID="${SOURCE_PVS_RUN_ID}_04_lvs"
for id in "$SOURCE_PVS_RUN_ID" "$SOURCE_PVS_EVIDENCE_ID" "$BOUNDARY_PVS_RUN_ID" \
          "$STANDALONE_PVS_RUN_ID" "$MONOLITHIC_PVS_RUN_ID" "$PVS_RUN_ID"; do
  [[ -z "$id" || "$id" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ERROR: unsafe run id: $id" >&2; exit 2; }
done
[[ -n "$SOURCE_PVS_RUN_ID" && -n "$STANDALONE_PVS_RUN_ID" && \
   -n "$MONOLITHIC_PVS_RUN_ID" ]] || {
  echo "ERROR: source, standalone, and monolithic run ids are required" >&2
  exit 2
}
if [[ "$DIRECT_FULL_TOP" -eq 1 ]]; then
  [[ -z "$BOUNDARY_PVS_RUN_ID" ]] || {
    echo "ERROR: --boundary-pvs-run-id cannot be combined with --direct-full-top" >&2
    exit 2
  }
  LVS_PREREQUISITE_MODE=DIRECT_FULL_TOP_WITH_STANDALONE_RO_PROOF
  BOUNDARY_PVS_RUN_ID_VALUE=NOT_USED_DIRECT_FULL_TOP
  BOUNDARY_PROOF_STATUS=NOT_REQUIRED_BY_DIRECT_MONOLITHIC_PROOF
else
  [[ -n "$BOUNDARY_PVS_RUN_ID" ]] || {
    echo "ERROR: --boundary-pvs-run-id is required unless --direct-full-top is used" >&2
    exit 2
  }
  LVS_PREREQUISITE_MODE=BOUNDARY_MATCH_PLUS_STANDALONE_RO_PROOF
  BOUNDARY_PVS_RUN_ID_VALUE="$BOUNDARY_PVS_RUN_ID"
  BOUNDARY_PROOF_STATUS=PASS
fi
[[ -n "$PVS_RUN_ID" ]] || PVS_RUN_ID="$(date +%Y%m%d)_mptdc_ro6_density_$(date +%H%M%S)"

SOURCE_DIR="$INNOVUS_WORK/$SOURCE_PVS_RUN_ID"
STANDALONE_DIR="$INNOVUS_WORK/$STANDALONE_PVS_RUN_ID"
MONOLITHIC_DIR="$INNOVUS_WORK/$MONOLITHIC_PVS_RUN_ID"
PVS_DIR="$INNOVUS_WORK/$PVS_RUN_ID"
SOURCE_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$SOURCE_PVS_EVIDENCE_ID"
BOUNDARY_SNAPSHOT=""
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  BOUNDARY_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_PVS_RUN_ID"
fi
STANDALONE_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$STANDALONE_PVS_RUN_ID"
MONOLITHIC_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$MONOLITHIC_PVS_RUN_ID"
BASE_CLASS="$SOURCE_SNAPSHOT/reports/pvs_recovery_base_drc_classification.rpt"
BASE_CLASS_SCOPE="$SOURCE_SNAPSHOT/manifests/pvs_recovery_base_drc_classification_scope.rpt"
SOURCE_DIAGNOSTIC_SCOPE="$SOURCE_SNAPSHOT/manifests/pvs_diagnostic_scope.rpt"
SOURCE_LVS_GATE="$SOURCE_SNAPSHOT/reports/operator_gate_pvs_lvs.rpt"
SOURCE_README="$SOURCE_SNAPSHOT/README.md"
BOUNDARY_GATE=""
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  BOUNDARY_GATE="$BOUNDARY_SNAPSHOT/reports/operator_gate_pvs_compositional_lvs.rpt"
fi
STANDALONE_GATE="$STANDALONE_SNAPSHOT/reports/operator_gate_pvs_ro6_standalone_lvs.rpt"
STANDALONE_INPUTS="$STANDALONE_SNAPSHOT/manifests/ro6_standalone_lvs_inputs.rpt"
MONOLITHIC_GATE="$MONOLITHIC_SNAPSHOT/reports/operator_gate_pvs_monolithic_lvs.rpt"
MONOLITHIC_HANDOFF="$MONOLITHIC_SNAPSHOT/reports/mptdc_lvs_drc_handoff_status.rpt"
MONOLITHIC_INPUTS="$MONOLITHIC_SNAPSHOT/manifests/pvs_ro6_monolithic_lvs_inputs.rpt"
SOURCE_HASHES="$SOURCE_DIR/manifests/pvs_input_hashes.rpt"
SOURCE_BASE_STATUS="$SOURCE_DIR/reports/pvs_drc_base_status.rpt"
SOURCE_BASE_RULES="$SOURCE_DIR/reports/pvs_drc_base_nonzero_rules.tsv"
SOURCE_GDS="$SOURCE_DIR/outputs/mptdc_axis_core_merged_stdcell_ro6.gds"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
PREFLIGHT=PASS
[[ "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" == SPADMIC_test ]] || PREFLIGHT=FAIL
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || PREFLIGHT=FAIL
[[ -z "$(git status --short --untracked-files=no 2>/dev/null)" ]] || PREFLIGHT=FAIL
for path in "$BASE_CLASS" "$BASE_CLASS_SCOPE" "$SOURCE_DIAGNOSTIC_SCOPE" \
            "$SOURCE_LVS_GATE" "$SOURCE_README" \
            "$STANDALONE_GATE" "$STANDALONE_INPUTS" "$MONOLITHIC_GATE" \
            "$MONOLITHIC_HANDOFF" "$MONOLITHIC_INPUTS"; do
  tracked_report "$path" || PREFLIGHT=FAIL
done
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  tracked_report "$BOUNDARY_GATE" || PREFLIGHT=FAIL
fi
for path in "$SOURCE_HASHES" "$SOURCE_BASE_STATUS" "$SOURCE_BASE_RULES" "$SOURCE_GDS" \
            "$DRC_REPLAY" "$CLASSIFIER" "$PUBLISHER"; do
  [[ -s "$path" ]] || PREFLIGHT=FAIL
done
[[ ! -e "$PVS_DIR" ]] || PREFLIGHT=FAIL

SOURCE_GDS_SHA="$(sha256sum "$SOURCE_GDS" 2>/dev/null | awk '{print $1}')"
SOURCE_BASE_RULE_SHA="$(sha256sum "$SOURCE_BASE_RULES" 2>/dev/null | awk '{print $1}')"
MANIFEST_GDS_SHA="$(report_value "$SOURCE_HASHES" MERGED_GDS_SHA256)"
BASE_LAYOUT_SHA="$(report_value "$SOURCE_BASE_STATUS" LAYOUT_INPUT_SHA256)"
BASE_CLASS_LAYOUT_SHA="$(report_value "$BASE_CLASS" LAYOUT_INPUT_SHA256)"
BASE_CLASS_RULE_SHA="$(report_value "$BASE_CLASS" RULE_REPORT_SHA256)"
BASE_SCOPE_LAYOUT_SHA="$(report_value "$BASE_CLASS_SCOPE" BASE_DRC_LAYOUT_SHA256)"
BASE_SCOPE_RULE_SHA="$(report_value "$BASE_CLASS_SCOPE" BASE_DRC_RULE_REPORT_SHA256)"
SOURCE_RO_GDS_SHA="$(report_value "$SOURCE_HASHES" RO_GDS_SHA256)"
BOUNDARY_GDS_SHA=MISSING
BOUNDARY_RO_GDS_SHA=MISSING
BOUNDARY_RO_CDL_SHA=MISSING
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  BOUNDARY_GDS_SHA="$(report_value "$BOUNDARY_GATE" MERGED_GDS_SHA256)"
  BOUNDARY_RO_GDS_SHA="$(report_value "$BOUNDARY_GATE" RO_GDS_SHA256)"
  BOUNDARY_RO_CDL_SHA="$(report_value "$BOUNDARY_GATE" RO_CDL_SHA256)"
fi
STANDALONE_RO_GDS_SHA="$(report_value "$STANDALONE_INPUTS" RO_GDS_SHA256)"
STANDALONE_RO_CDL_SHA="$(report_value "$STANDALONE_INPUTS" RO_CDL_SHA256)"
MONOLITHIC_GDS_SHA="$(report_value "$MONOLITHIC_GATE" MERGED_GDS_SHA256)"
MONOLITHIC_RO_GDS_SHA="$(report_value "$MONOLITHIC_GATE" RO_GDS_SHA256)"
MONOLITHIC_RO_CDL_SHA="$(report_value "$MONOLITHIC_GATE" RO_CDL_SHA256)"
MONOLITHIC_INPUT_GDS_SHA="$(report_value "$MONOLITHIC_INPUTS" MERGED_GDS_SHA256)"
MONOLITHIC_INPUT_RO_GDS_SHA="$(report_value "$MONOLITHIC_INPUTS" RO_GDS_SHA256)"
MONOLITHIC_INPUT_RO_CDL_SHA="$(report_value "$MONOLITHIC_INPUTS" RO_CDL_SHA256)"
[[ "$(report_value "$BASE_CLASS" STEP)" == MPTDC_RECOVERY_BASE_DRC_CLASSIFICATION &&
   "$(report_value "$BASE_CLASS" CLASSIFICATION_CONTEXT)" == RECOVERY_ANTENNA_EXCEPTION &&
   "$(report_value "$BASE_CLASS" CLASSIFICATION_STATUS)" == PASS &&
   "$(report_value "$BASE_CLASS" PVS_BASE_DRC_CLASS)" =~ ^(CLEAN|ANTENNA_ONLY_MANAGER_EXCEPTION)$ &&
   "$(report_value "$BASE_CLASS" NON_ANTENNA_RULE_COUNT)" == 0 &&
   "$(report_value "$BASE_CLASS" ANTENNA_REPAIR_ATTEMPTED)" == NO &&
   "$(report_value "$BASE_CLASS" SIGNOFF_ELIGIBLE)" == NO ]] || PREFLIGHT=FAIL
[[ "$(report_value "$BASE_CLASS_SCOPE" PVS_RUN_CLASS)" == DIAGNOSTIC_COMPOSITIONAL_NOT_SIGNOFF &&
   "$(report_value "$BASE_CLASS_SCOPE" DIAGNOSTIC_SCOPE)" == BASE_DRC_PLUS_RAW_LVS_FOR_COMPOSITIONAL_PROOF &&
   "$(report_value "$BASE_CLASS_SCOPE" CLASSIFICATION_CONTEXT)" == RECOVERY_ANTENNA_EXCEPTION &&
   "$(report_value "$BASE_CLASS_SCOPE" BASE_DRC_CLASS)" == "$(report_value "$BASE_CLASS" PVS_BASE_DRC_CLASS)" &&
   "$(report_value "$BASE_CLASS_SCOPE" DENSITY_DRC_STATUS)" == NOT_RUN_BY_SCOPE &&
   "$(report_value "$BASE_CLASS_SCOPE" ANTENNA_REPAIR_ATTEMPTED)" == NO &&
   "$(report_value "$BASE_CLASS_SCOPE" ALLOWED_ANTENNA_RULE_SET)" == R1M2P1,R1M3P1,R2M2P1,R2M3P1 &&
   "$(report_value "$BASE_CLASS_SCOPE" SIGNOFF_ELIGIBLE)" == NO ]] || PREFLIGHT=FAIL
[[ "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" PVS_RUN_CLASS)" == DIAGNOSTIC_COMPOSITIONAL_NOT_SIGNOFF &&
   "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" DIAGNOSTIC_SCOPE)" == BASE_DRC_PLUS_RAW_LVS &&
   "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" DIAGNOSTIC_ANTENNA_EXCEPTION)" == 1 &&
   "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" DIAGNOSTIC_RO_COMPOSITIONAL)" == 1 &&
   "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" RUN_DENSITY_AFTER_LVS)" == 0 &&
   "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" DEFERRED_INNOVUS_DRC_COUNT)" == 0 &&
   "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" DEFERRED_INNOVUS_DRC_RULE)" == NONE &&
   "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" DEFERRED_INNOVUS_DRC_NET)" == NONE &&
   "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" DENSITY_DRC_STATUS)" == NOT_RUN_BY_SCOPE &&
   "$(report_value "$SOURCE_DIAGNOSTIC_SCOPE" SIGNOFF_ELIGIBLE)" == NO ]] || PREFLIGHT=FAIL
[[ "$(report_value "$SOURCE_LVS_GATE" PVS_RUN_CLASS)" == DIAGNOSTIC_COMPOSITIONAL_NOT_SIGNOFF &&
   "$(report_value "$SOURCE_LVS_GATE" DIAGNOSTIC_RO_COMPOSITIONAL)" == 1 &&
   "$(report_value "$SOURCE_LVS_GATE" STATUS)" == FAIL &&
   "$(report_value "$SOURCE_LVS_GATE" PVS_LVS_STATUS)" == MISMATCH &&
   "$(report_value "$SOURCE_LVS_GATE" PVS_RC)" == 0 &&
   "$(report_value "$SOURCE_LVS_GATE" LVS_RC)" == 8 &&
   "$(report_value "$SOURCE_LVS_GATE" RAW_FULL_TOP_LVS_STATUS)" == MISMATCH_PENDING_BOUNDARY_PROOF &&
   "$(report_value "$SOURCE_LVS_GATE" SIGNOFF_ELIGIBLE)" == NO &&
   "$(report_value "$SOURCE_LVS_GATE" DECISION)" == DIAGNOSTIC_RAW_MISMATCH_COLLECTED ]] || PREFLIGHT=FAIL
grep -Fqx -- "- Run ID: \`$SOURCE_PVS_EVIDENCE_ID\`" "$SOURCE_README" || PREFLIGHT=FAIL
grep -Fqx -- "- Source directory: \`$SOURCE_DIR\`" "$SOURCE_README" || PREFLIGHT=FAIL
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  [[ "$(report_value "$BOUNDARY_GATE" SOURCE_PVS_RUN_ID)" == "$SOURCE_PVS_RUN_ID" &&
     "$(report_value "$BOUNDARY_GATE" PVS_RUN_CLASS)" == DIAGNOSTIC_COMPOSITIONAL_NOT_SIGNOFF &&
     "$(report_value "$BOUNDARY_GATE" BOUNDARY_PVS_RUN_ID)" == "$BOUNDARY_PVS_RUN_ID" &&
     "$(report_value "$BOUNDARY_GATE" STANDALONE_PVS_RUN_ID)" == "$STANDALONE_PVS_RUN_ID" &&
     "$(report_value "$BOUNDARY_GATE" RAW_FULL_TOP_LVS_STATUS)" == MISMATCH_RO_ABSTRACTION_ONLY &&
     "$(report_value "$BOUNDARY_GATE" PVS_TOP_BOUNDARY_LVS)" == MATCH &&
     "$(report_value "$BOUNDARY_GATE" PVS_RO6_STANDALONE_LVS)" == MATCH &&
     "$(report_value "$BOUNDARY_GATE" COMPOSITIONAL_LVS_STATUS)" == PASS &&
     "$(report_value "$BOUNDARY_GATE" ANTENNA_REPAIR_ATTEMPTED)" == NO &&
     "$(report_value "$BOUNDARY_GATE" SIGNOFF_ELIGIBLE)" == NO &&
     "$(report_value "$BOUNDARY_GATE" FINAL_SIGNOFF)" == NO &&
     "$(report_value "$BOUNDARY_GATE" READY_FOR_TAPEOUT)" == NO &&
     "$(report_value "$BOUNDARY_GATE" NEXT_STAGE)" == PVS_RO6_MONOLITHIC_FULL_TOP_LVS &&
     "$(report_value "$BOUNDARY_GATE" DECISION)" == PASS_MONOLITHIC_LVS_CONTINUE ]] || PREFLIGHT=FAIL
fi
[[ "$(report_value "$STANDALONE_GATE" PVS_LVS)" == MATCH &&
   "$(report_value "$STANDALONE_GATE" DECISION)" == PASS_CONTINUE &&
   "$(report_value "$STANDALONE_GATE" OA_READ_ONLY_STATUS)" == PASS &&
   "$(report_value "$STANDALONE_GATE" RO6_CDL_PIN_CONTRACT_STATUS)" == PASS &&
   "$(report_value "$STANDALONE_GATE" SIGNOFF_ELIGIBLE)" == NO ]] || PREFLIGHT=FAIL
[[ "$(report_value "$MONOLITHIC_GATE" STEP)" == PVS_RO6_MONOLITHIC_FULL_TOP_LVS &&
   "$(report_value "$MONOLITHIC_GATE" PVS_RUN_CLASS)" == MONOLITHIC_FULL_TOP_LVS_PROOF &&
   "$(report_value "$MONOLITHIC_GATE" LVS_PREREQUISITE_MODE)" == "$LVS_PREREQUISITE_MODE" &&
   "$(report_value "$MONOLITHIC_GATE" SOURCE_PVS_RUN_ID)" == "$SOURCE_PVS_RUN_ID" &&
   "$(report_value "$MONOLITHIC_GATE" SOURCE_PVS_EVIDENCE_ID)" == "$SOURCE_PVS_EVIDENCE_ID" &&
   "$(report_value "$MONOLITHIC_GATE" BOUNDARY_PVS_RUN_ID)" == "$BOUNDARY_PVS_RUN_ID_VALUE" &&
   "$(report_value "$MONOLITHIC_GATE" BOUNDARY_PROOF_STATUS)" == "$BOUNDARY_PROOF_STATUS" &&
   "$(report_value "$MONOLITHIC_GATE" RAW_MISMATCH_ATTRIBUTION)" == EXACT_TWO_RO6_INTERNALS_ONLY &&
   "$(report_value "$MONOLITHIC_GATE" RAW_CLASSIFIER_RC)" == 0 &&
   "$(report_value "$MONOLITHIC_GATE" STANDALONE_PVS_RUN_ID)" == "$STANDALONE_PVS_RUN_ID" &&
   "$(report_value "$MONOLITHIC_GATE" MONOLITHIC_LVS_STATUS)" == MATCH &&
   "$(report_value "$MONOLITHIC_GATE" LVS_BLACKBOXED_CELL_COUNT)" == 0 &&
   "$(report_value "$MONOLITHIC_GATE" LVS_HCELL_STATUS)" == NOT_USED &&
   "$(report_value "$MONOLITHIC_GATE" CLS_RUN_RESULT)" == MATCH &&
   "$(report_value "$MONOLITHIC_GATE" CELLS_WHICH_MISMATCH)" == 0 &&
   "$(report_value "$MONOLITHIC_GATE" TOP_59_PIN_MATCH_STATUS)" == PASS &&
   "$(report_value "$MONOLITHIC_GATE" RO6_19_PIN_MATCH_STATUS)" == PASS &&
   "$(report_value "$MONOLITHIC_GATE" MISSING_INSTANCE_EVIDENCE_COUNT)" == 0 &&
   "$(report_value "$MONOLITHIC_GATE" SHORT_OPEN_EVIDENCE_STATUS)" == PASS &&
   "$(report_value "$MONOLITHIC_GATE" LVS_SIGNOFF_ELIGIBLE)" == YES &&
   "$(report_value "$MONOLITHIC_GATE" FINAL_PHYSICAL_SIGNOFF_READY)" == NO &&
   "$(report_value "$MONOLITHIC_GATE" DECISION)" == PASS_MONOLITHIC_LVS ]] || PREFLIGHT=FAIL
[[ "$(report_value "$MONOLITHIC_HANDOFF" MONOLITHIC_LVS_STATUS)" == MATCH &&
   "$(report_value "$MONOLITHIC_HANDOFF" NON_ANTENNA_DRC_STATUS)" == PASS &&
   "$(report_value "$MONOLITHIC_HANDOFF" ANTENNA_EXCEPTION_STATUS)" == ACCEPTED_PROJECT_POLICY &&
   "$(report_value "$MONOLITHIC_HANDOFF" ANTENNA_EXCEPTION_EVIDENCE_KIND)" == AUTO_CLASSIFIED_NOT_INDEPENDENTLY_SIGNED &&
   "$(report_value "$MONOLITHIC_HANDOFF" TOOL_CLEAN_DRC)" == NO &&
   "$(report_value "$MONOLITHIC_HANDOFF" INNOVUS_SPECIAL_CONNECTIVITY_STATUS)" == FAIL_15_DANGLING &&
   "$(report_value "$MONOLITHIC_HANDOFF" FINAL_PHYSICAL_SIGNOFF_READY)" == NO ]] || PREFLIGHT=FAIL
[[ "$(report_value "$MONOLITHIC_INPUTS" PVS_RUN_CLASS)" == MONOLITHIC_FULL_TOP_LVS_PROOF &&
   "$(report_value "$MONOLITHIC_INPUTS" LVS_PREREQUISITE_MODE)" == "$LVS_PREREQUISITE_MODE" &&
   "$(report_value "$MONOLITHIC_INPUTS" SOURCE_PVS_RUN_ID)" == "$SOURCE_PVS_RUN_ID" &&
   "$(report_value "$MONOLITHIC_INPUTS" BOUNDARY_PVS_RUN_ID)" == "$BOUNDARY_PVS_RUN_ID_VALUE" &&
   "$(report_value "$MONOLITHIC_INPUTS" BOUNDARY_PROOF_STATUS)" == "$BOUNDARY_PROOF_STATUS" &&
   "$(report_value "$MONOLITHIC_INPUTS" STANDALONE_PVS_RUN_ID)" == "$STANDALONE_PVS_RUN_ID" &&
   "$(report_value "$MONOLITHIC_INPUTS" RO_MODEL_MODE)" == EXTERNAL_CDL &&
   "$(report_value "$MONOLITHIC_INPUTS" LVS_HCELL_STATUS)" == NOT_USED &&
   "$(report_value "$MONOLITHIC_INPUTS" LVS_BLACKBOX_STATUS)" == NOT_USED &&
   "$(report_value "$MONOLITHIC_INPUTS" LVS_POSITION_BUS_MAPPING_STATUS)" == NOT_USED ]] || PREFLIGHT=FAIL
[[ "$SOURCE_GDS_SHA" =~ ^[0-9a-f]{64}$ && "$SOURCE_GDS_SHA" == "$MANIFEST_GDS_SHA" &&
   "$SOURCE_GDS_SHA" == "$BASE_LAYOUT_SHA" && "$SOURCE_GDS_SHA" == "$BASE_CLASS_LAYOUT_SHA" &&
   "$SOURCE_GDS_SHA" == "$BASE_SCOPE_LAYOUT_SHA" && "$SOURCE_GDS_SHA" == "$MONOLITHIC_GDS_SHA" &&
   "$SOURCE_GDS_SHA" == "$MONOLITHIC_INPUT_GDS_SHA" &&
   "$SOURCE_BASE_RULE_SHA" =~ ^[0-9a-f]{64}$ &&
   "$SOURCE_BASE_RULE_SHA" == "$BASE_CLASS_RULE_SHA" &&
   "$SOURCE_BASE_RULE_SHA" == "$BASE_SCOPE_RULE_SHA" &&
   "$SOURCE_RO_GDS_SHA" =~ ^[0-9a-f]{64}$ &&
   "$SOURCE_RO_GDS_SHA" == "$STANDALONE_RO_GDS_SHA" &&
   "$SOURCE_RO_GDS_SHA" == "$MONOLITHIC_RO_GDS_SHA" &&
   "$SOURCE_RO_GDS_SHA" == "$MONOLITHIC_INPUT_RO_GDS_SHA" &&
   "$STANDALONE_RO_CDL_SHA" =~ ^[0-9a-f]{64}$ &&
   "$STANDALONE_RO_CDL_SHA" == "$MONOLITHIC_RO_CDL_SHA" &&
   "$STANDALONE_RO_CDL_SHA" == "$MONOLITHIC_INPUT_RO_CDL_SHA" ]] || PREFLIGHT=FAIL
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  [[ "$SOURCE_GDS_SHA" == "$BOUNDARY_GDS_SHA" &&
     "$SOURCE_RO_GDS_SHA" == "$BOUNDARY_RO_GDS_SHA" &&
     "$STANDALONE_RO_CDL_SHA" == "$BOUNDARY_RO_CDL_SHA" ]] || PREFLIGHT=FAIL
fi

mapfile -t BASE_DRC_RUNS < <(find "$SOURCE_DIR/pvs_drc" -mindepth 1 -maxdepth 1 -type d \
  -exec test -s '{}/run.pvs' ';' -print 2>/dev/null)
[[ "${#BASE_DRC_RUNS[@]}" == 1 ]] || PREFLIGHT=FAIL
BASE_DRC_TEMPLATE="${BASE_DRC_RUNS[0]:-MISSING}"

echo "PVS_DENSITY_PREFLIGHT=$PREFLIGHT"
echo "LVS_PREREQUISITE_MODE=$LVS_PREREQUISITE_MODE"
echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID_VALUE"
echo "BOUNDARY_PROOF_STATUS=$BOUNDARY_PROOF_STATUS"
echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
echo "MONOLITHIC_PVS_RUN_ID=$MONOLITHIC_PVS_RUN_ID"
echo "PVS_RUN_ID=$PVS_RUN_ID"
echo "SOURCE_GDS_SHA256=$SOURCE_GDS_SHA"
echo "BASE_DRC_TEMPLATE=$BASE_DRC_TEMPLATE"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

mkdir -p "$PVS_DIR/reports" "$PVS_DIR/manifests" "$PVS_DIR/logs" "$PVS_DIR/pvs_drc"
ln -s "$SOURCE_DIR/outputs" "$PVS_DIR/outputs"
sed "s|$SOURCE_DIR|$PVS_DIR|g" "$SOURCE_HASHES" > "$PVS_DIR/manifests/pvs_input_hashes.rpt"
cp -p "$SOURCE_BASE_RULES" "$PVS_DIR/reports/pvs_drc_base_nonzero_rules.tsv"
sed "s|$SOURCE_DIR|$PVS_DIR|g" "$SOURCE_BASE_STATUS" > "$PVS_DIR/reports/pvs_drc_base_status.rpt"
{
  echo "PVS_RUN_CLASS=DIAGNOSTIC_DENSITY_AFTER_MONOLITHIC_LVS"
  echo "LVS_PREREQUISITE_MODE=$LVS_PREREQUISITE_MODE"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
  echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID_VALUE"
  echo "BOUNDARY_PROOF_STATUS=$BOUNDARY_PROOF_STATUS"
  echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
  echo "MONOLITHIC_PVS_RUN_ID=$MONOLITHIC_PVS_RUN_ID"
  echo "MONOLITHIC_LVS_STATUS=MATCH"
  echo "LVS_BLACKBOXED_CELL_COUNT=0"
  echo "LVS_HCELL_STATUS=NOT_USED"
  echo "MERGED_GDS_SHA256=$SOURCE_GDS_SHA"
  echo "RO_GDS_SHA256=$SOURCE_RO_GDS_SHA"
  echo "ANTENNA_REPAIR_ATTEMPTED=NO"
  echo "DENSITY_REPAIR_ATTEMPTED=NO"
  echo "SIGNOFF_ELIGIBLE=NO"
} > "$PVS_DIR/manifests/pvs_density_scope.rpt"

NEW_DRC_RUN="$PVS_DIR/pvs_drc/mptdc_axis_core_merged_density_script"
set +e
bash "$DRC_REPLAY" --prepared-dir "$PVS_DIR" --template-run "$BASE_DRC_TEMPLATE" \
  --old-base "$SOURCE_DIR" --old-gds "$SOURCE_GDS" --new-run-dir "$NEW_DRC_RUN" \
  --variant density --expected-head "$EXPECTED_HEAD_VALUE" \
  2>&1 | tee "$PVS_DIR/logs/operator_drc_density.log"
DRC_RC=${PIPESTATUS[0]}
set +e

DENSITY_STATUS="$PVS_DIR/reports/pvs_drc_density_status.rpt"
DENSITY_RULES="$PVS_DIR/reports/pvs_drc_density_nonzero_rules.tsv"
CLASSIFICATION="$PVS_DIR/reports/pvs_density_delta_classification.rpt"
set +e
python3 "$CLASSIFIER" --base-status "$PVS_DIR/reports/pvs_drc_base_status.rpt" \
  --base-rules "$PVS_DIR/reports/pvs_drc_base_nonzero_rules.tsv" \
  --density-status "$DENSITY_STATUS" --density-rules "$DENSITY_RULES" \
  --out "$CLASSIFICATION" 2>&1 | tee "$PVS_DIR/logs/operator_density_classification.log"
CLASSIFICATION_RC=${PIPESTATUS[0]}
set +e

CLASSIFICATION_STATUS="$(report_value "$CLASSIFICATION" DENSITY_CLASSIFICATION_STATUS)"
DENSITY_RAW_STATUS="$(report_value "$CLASSIFICATION" PVS_DRC_DENSITY_RAW_STATUS)"
NON_ANTENNA_STATUS="$(report_value "$CLASSIFICATION" PVS_DRC_DENSITY_NON_ANTENNA_STATUS)"
NON_ANTENNA_COUNT="$(report_value "$CLASSIFICATION" DENSITY_NON_ANTENNA_RULE_COUNT)"
NON_ANTENNA_SET="$(report_value "$CLASSIFICATION" DENSITY_NON_ANTENNA_RULE_SET)"
ANTENNA_SIGNATURE_STATUS="$(report_value "$CLASSIFICATION" DENSITY_ANTENNA_SIGNATURE_MATCH_STATUS)"
DECISION=FAIL_INVALID_EVIDENCE
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
if [[ ( "$DENSITY_RAW_STATUS" == PASS && "$DRC_RC" -eq 0 ||
        "$DENSITY_RAW_STATUS" == FAIL && "$DRC_RC" -eq 9 ) &&
      "$CLASSIFICATION_RC" -eq 0 && "$CLASSIFICATION_STATUS" == PASS &&
      "$NON_ANTENNA_STATUS" == PASS && "$NON_ANTENNA_COUNT" == 0 &&
      "$ANTENNA_SIGNATURE_STATUS" == PASS ]]; then
  DECISION=PASS_NON_ANTENNA_DENSITY_CLEAN
  NEXT_STAGE=CLOSURE_SUMMARY_WITH_ANTENNA_EXCEPTION
elif [[ "$DENSITY_RAW_STATUS" == FAIL && "$DRC_RC" -eq 9 &&
        "$CLASSIFICATION_RC" -eq 10 && "$CLASSIFICATION_STATUS" == FAIL &&
        "$NON_ANTENNA_STATUS" == FAIL && "$NON_ANTENNA_COUNT" =~ ^[1-9][0-9]*$ &&
        "$ANTENNA_SIGNATURE_STATUS" == PASS ]]; then
  DECISION=FAIL_REVIEW_ATTRIBUTABLE_DENSITY_DEBT
  NEXT_STAGE=REVIEW_ATTRIBUTABLE_DENSITY_DEBT
fi
{
  echo "STEP=PVS_DRC_DENSITY_AFTER_MONOLITHIC_LVS"
  echo "PVS_RUN_CLASS=DIAGNOSTIC_DENSITY_AFTER_MONOLITHIC_LVS"
  echo "LVS_PREREQUISITE_MODE=$LVS_PREREQUISITE_MODE"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
  echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID_VALUE"
  echo "BOUNDARY_PROOF_STATUS=$BOUNDARY_PROOF_STATUS"
  echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
  echo "MONOLITHIC_PVS_RUN_ID=$MONOLITHIC_PVS_RUN_ID"
  echo "MONOLITHIC_LVS_STATUS=MATCH"
  echo "LVS_BLACKBOXED_CELL_COUNT=0"
  echo "LVS_HCELL_STATUS=NOT_USED"
  echo "DRC_REPLAY_RC=$DRC_RC"
  echo "DENSITY_CLASSIFICATION_RC=$CLASSIFICATION_RC"
  echo "DENSITY_CLASSIFICATION_STATUS=$CLASSIFICATION_STATUS"
  echo "PVS_DRC_DENSITY_RAW_STATUS=$DENSITY_RAW_STATUS"
  echo "DENSITY_ANTENNA_SIGNATURE_MATCH_STATUS=$ANTENNA_SIGNATURE_STATUS"
  echo "DENSITY_NON_ANTENNA_RULE_COUNT=$NON_ANTENNA_COUNT"
  echo "DENSITY_NON_ANTENNA_RULE_SET=$NON_ANTENNA_SET"
  echo "PVS_DRC_DENSITY_NON_ANTENNA_STATUS=$NON_ANTENNA_STATUS"
  echo "NON_ANTENNA_DRC_STATUS=$NON_ANTENNA_STATUS"
  echo "ANTENNA_EXCEPTION_STATUS=ACCEPTED_PROJECT_POLICY"
  echo "ANTENNA_EXCEPTION_EVIDENCE_KIND=AUTO_CLASSIFIED_NOT_INDEPENDENTLY_SIGNED"
  echo "TOOL_CLEAN_DRC=NO"
  echo "INNOVUS_SPECIAL_CONNECTIVITY_STATUS=FAIL_15_DANGLING"
  echo "ANTENNA_REPAIR_ATTEMPTED=NO"
  echo "DENSITY_REPAIR_ATTEMPTED=NO"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "FINAL_SIGNOFF=NO"
  echo "READY_FOR_TAPEOUT=NO"
  echo "FINAL_PHYSICAL_SIGNOFF_READY=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$PVS_DIR/reports/operator_gate_pvs_drc_density.rpt"

MPTDC_SNAPSHOT_MAX_TEXT_BYTES=4194304 bash "$PUBLISHER" pvs "$PVS_RUN_ID" "$PVS_DIR" PVS_DRC_DENSITY
PUBLISH_RC=$?
echo "PVS_DENSITY_STATUS=$CLASSIFICATION_STATUS"
echo "LVS_PREREQUISITE_MODE=$LVS_PREREQUISITE_MODE"
echo "PVS_RUN_ID=$PVS_RUN_ID"
echo "MONOLITHIC_PVS_RUN_ID=$MONOLITHIC_PVS_RUN_ID"
echo "MONOLITHIC_LVS_STATUS=MATCH"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"
echo "FINAL_PHYSICAL_SIGNOFF_READY=NO"
if [[ "$DECISION" == PASS_NON_ANTENNA_DENSITY_CLEAN && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
