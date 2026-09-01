#!/usr/bin/env bash
# Prove full-top MPTDC LVS with the exact standalone-matched RO_tune6 CDL.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
REPO_ROOT="${MPTDC_MONOLITHIC_LVS_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-/sim/ksabra/SPADMIC_work/innovus}"
SOURCE_GENERATOR="${MPTDC_MONOLITHIC_LVS_SOURCE_GENERATOR:-$SCRIPT_DIR/01_generate_lvs_source_pg_filtered.py}"
PREP_HELPER="${MPTDC_MONOLITHIC_LVS_PREP:-$SCRIPT_DIR/13_prepare_ro6_monolithic_lvs.py}"
GATE_HELPER="${MPTDC_MONOLITHIC_LVS_GATE:-$SCRIPT_DIR/14_gate_ro6_monolithic_lvs.py}"
RAW_CLASSIFIER="${MPTDC_MONOLITHIC_LVS_RAW_CLASSIFIER:-$SCRIPT_DIR/15_classify_ro6_raw_mismatch.py}"
PUBLISHER="${MPTDC_MONOLITHIC_LVS_PUBLISHER:-$REPO_ROOT/MPTDC/ci/publish_mptdc_server_snapshot.sh}"
CADENCE_ENV="${MPTDC_CADENCE_ENV:-/eda/cadence/eda_2023-2024}"

SOURCE_PVS_RUN_ID=""
SOURCE_PVS_EVIDENCE_ID=""
BOUNDARY_PVS_RUN_ID=""
STANDALONE_PVS_RUN_ID=""
PVS_RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
DIRECT_FULL_TOP=0
CADENCE_ENV_RC=99
CADENCE_ENV_STATUS=NOT_RUN
RAW_CLASSIFICATION_TMP=""

cleanup() {
  [[ -z "$RAW_CLASSIFICATION_TMP" ]] || rm -f "$RAW_CLASSIFICATION_TMP"
}
trap cleanup EXIT

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_ro6_monolithic_lvs.sh \
    --source-pvs-run-id <id> [--boundary-pvs-run-id <id> | --direct-full-top] \
    --standalone-pvs-run-id <id> [options]

Options:
  --source-pvs-evidence-id <id>
                         Published source snapshot; defaults to
                         <source-pvs-run-id>_04_lvs.
  --run-id <id>          New monolithic LVS result directory.
  --direct-full-top      Run the definitive no-HCell full-top comparison after
                         strict raw-mismatch attribution and standalone RO MATCH.
  --expected-head <sha>  Require repository HEAD.
  --innovus-work <path>  Innovus/PVS result root.
  -h, --help             Show this help.

The source raw mismatch, standalone RO MATCH, exact GDS/CDL hashes,
antenna-only base DRC, and PG15 source state must all agree. Boundary MATCH is
required by the legacy mode and intentionally not required by
--direct-full-top because that mode performs the stronger definitive full-top
comparison itself. HCell, blackbox, positional bus mapping, and global-port
promotion are forbidden in both modes.
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

tracked_file() {
  local path="$1" rel="${1#"$REPO_ROOT"/}"
  git -C "$REPO_ROOT" ls-files --error-unmatch "$rel" >/dev/null 2>&1 && [[ -f "$path" ]]
}

load_cadence_env() {
  local env_file="$1"
  echo "CADENCE_ENV=$env_file"
  if [[ ! -r "$env_file" ]]; then
    CADENCE_ENV_RC=1
    CADENCE_ENV_STATUS=FAIL_NOT_READABLE
    echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
    echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
    return 1
  fi
  set +u
  set +e
  # shellcheck disable=SC1090
  source "$env_file" >/dev/null 2>&1
  CADENCE_ENV_RC=$?
  set +e
  set -u
  set -o pipefail
  if [[ "$CADENCE_ENV_RC" -eq 0 ]]; then
    CADENCE_ENV_STATUS=PASS
  else
    CADENCE_ENV_STATUS=FAIL
  fi
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
  [[ "$CADENCE_ENV_STATUS" == PASS ]]
}

publish_stage() {
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=8388608 \
    bash "$PUBLISHER" pvs "$PVS_RUN_ID" "$PVS_DIR" PVS_RO6_MONOLITHIC_LVS
  local rc=$?
  EXPECTED_HEAD_VALUE="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  return "$rc"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-pvs-run-id) SOURCE_PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --source-pvs-evidence-id) SOURCE_PVS_EVIDENCE_ID="${2:?missing value}"; shift 2 ;;
    --boundary-pvs-run-id) BOUNDARY_PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --standalone-pvs-run-id) STANDALONE_PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --direct-full-top) DIRECT_FULL_TOP=1; shift ;;
    --run-id) PVS_RUN_ID="${2:?missing value}"; shift 2 ;;
    --expected-head) EXPECTED_HEAD_VALUE="${2:?missing value}"; shift 2 ;;
    --innovus-work) INNOVUS_WORK="${2:?missing value}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERROR: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_PVS_EVIDENCE_ID" ]] || SOURCE_PVS_EVIDENCE_ID="${SOURCE_PVS_RUN_ID}_04_lvs"
[[ -n "$PVS_RUN_ID" ]] || PVS_RUN_ID="$(date +%Y%m%d)_mptdc_ro6_monolithic_lvs_$(date +%H%M%S)"
for id in "$SOURCE_PVS_RUN_ID" "$SOURCE_PVS_EVIDENCE_ID" \
          "$STANDALONE_PVS_RUN_ID" "$PVS_RUN_ID"; do
  [[ -n "$id" && "$id" =~ ^[A-Za-z0-9._-]+$ ]] || {
    echo "ERROR: missing or unsafe run id: $id" >&2
    exit 2
  }
done
if [[ "$DIRECT_FULL_TOP" -eq 1 ]]; then
  [[ -z "$BOUNDARY_PVS_RUN_ID" ]] || {
    echo "ERROR: --boundary-pvs-run-id cannot be combined with --direct-full-top" >&2
    exit 2
  }
  LVS_PREREQUISITE_MODE=DIRECT_FULL_TOP_WITH_STANDALONE_RO_PROOF
  BOUNDARY_PVS_RUN_ID_VALUE=NOT_USED_DIRECT_FULL_TOP
  BOUNDARY_PROOF_STATUS=NOT_REQUIRED_BY_DIRECT_MONOLITHIC_PROOF
else
  [[ -n "$BOUNDARY_PVS_RUN_ID" && "$BOUNDARY_PVS_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || {
    echo "ERROR: --boundary-pvs-run-id is required unless --direct-full-top is used" >&2
    exit 2
  }
  LVS_PREREQUISITE_MODE=BOUNDARY_MATCH_PLUS_STANDALONE_RO_PROOF
  BOUNDARY_PVS_RUN_ID_VALUE="$BOUNDARY_PVS_RUN_ID"
  BOUNDARY_PROOF_STATUS=PASS
fi

SOURCE_DIR="$INNOVUS_WORK/$SOURCE_PVS_RUN_ID"
STANDALONE_DIR="$INNOVUS_WORK/$STANDALONE_PVS_RUN_ID"
PVS_DIR="$INNOVUS_WORK/$PVS_RUN_ID"
SOURCE_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$SOURCE_PVS_EVIDENCE_ID"
BOUNDARY_SNAPSHOT=""
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  BOUNDARY_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$BOUNDARY_PVS_RUN_ID"
fi
STANDALONE_SNAPSHOT="$REPO_ROOT/MPTDC/docs/server_snapshots/pvs/$STANDALONE_PVS_RUN_ID"

SOURCE_HASHES="$SOURCE_DIR/manifests/pvs_input_hashes.rpt"
SOURCE_FILTER="$SOURCE_DIR/reports/lvs_source_filter.rpt"
SOURCE_LVS_STATUS="$SOURCE_DIR/reports/pvs_lvs_status.rpt"
SOURCE_LVS_TOOL_STATUS="$SOURCE_DIR/reports/pvs_lvs_tool_status.rpt"
SOURCE_BASE_CLASS="$SOURCE_SNAPSHOT/reports/pvs_recovery_base_drc_classification.rpt"
SOURCE_BASE_RULES="$SOURCE_SNAPSHOT/reports/pvs_drc_base_nonzero_rules.tsv"
SOURCE_SPECIAL="$SOURCE_SNAPSHOT/reports/connectivity_special_before_streamout.rpt"
SOURCE_HASHES_TRACKED="$SOURCE_SNAPSHOT/manifests/pvs_input_hashes.rpt"
SOURCE_FILTER_TRACKED="$SOURCE_SNAPSHOT/reports/lvs_source_filter.rpt"
SOURCE_LVS_STATUS_TRACKED="$SOURCE_SNAPSHOT/reports/pvs_lvs_status.rpt"
SOURCE_LVS_TOOL_STATUS_TRACKED="$SOURCE_SNAPSHOT/reports/pvs_lvs_tool_status.rpt"
BOUNDARY_GATE=""
BOUNDARY_DETAIL=""
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  BOUNDARY_GATE="$BOUNDARY_SNAPSHOT/reports/operator_gate_pvs_compositional_lvs.rpt"
  BOUNDARY_DETAIL="$BOUNDARY_SNAPSHOT/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"
fi
STANDALONE_GATE="$STANDALONE_SNAPSHOT/reports/operator_gate_pvs_ro6_standalone_lvs.rpt"
STANDALONE_INPUTS="$STANDALONE_SNAPSHOT/manifests/ro6_standalone_lvs_inputs.rpt"
STANDALONE_INPUTS_LIVE="$STANDALONE_DIR/manifests/ro6_standalone_lvs_inputs.rpt"

cd "$REPO_ROOT" || exit 3
ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
ORIGIN_HEAD="$(git rev-parse refs/remotes/origin/SPADMIC_test 2>/dev/null || true)"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD_VALUE:-${ORIGIN_HEAD:-$ACTUAL_HEAD}}"
TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"

SOURCE_GDS="$(report_value "$SOURCE_HASHES" MERGED_GDS_PATH)"
SOURCE_GDS_EXPECTED_SHA="$(report_value "$SOURCE_HASHES" MERGED_GDS_SHA256)"
SOURCE_PHYSICAL="$(report_value "$SOURCE_HASHES" LVS_SOURCE_PHYSICAL_PG_PATH)"
SOURCE_PHYSICAL_EXPECTED_SHA="$(report_value "$SOURCE_HASHES" LVS_SOURCE_PHYSICAL_PG_SHA256)"
DCELL_CDL="$(report_value "$SOURCE_HASHES" DCELL_CDL_PATH)"
DCELL_CDL_EXPECTED_SHA="$(report_value "$SOURCE_HASHES" DCELL_CDL_SHA256)"
FILLER_REPORT="$(report_value "$SOURCE_HASHES" FILLER_REPORT_PATH)"
FILLER_REPORT_EXPECTED_SHA="$(report_value "$SOURCE_HASHES" FILLER_REPORT_SHA256)"
ROW_INFRA_REPORT="$(report_value "$SOURCE_HASHES" ROW_INFRA_REPORT_PATH)"
ROW_INFRA_REPORT_EXPECTED_SHA="$(report_value "$SOURCE_HASHES" ROW_INFRA_REPORT_SHA256)"
SOURCE_RO_GDS_SHA="$(report_value "$SOURCE_HASHES" RO_GDS_SHA256)"
RO_CDL_SOURCE="$(report_value "$STANDALONE_INPUTS_LIVE" LOCAL_RO_CDL)"
STANDALONE_RO_GDS_SHA="$(report_value "$STANDALONE_INPUTS" RO_GDS_SHA256)"
STANDALONE_RO_CDL_SHA="$(report_value "$STANDALONE_INPUTS" RO_CDL_SHA256)"

SOURCE_LVS_RUN=""
SOURCE_LVS_RUN_COUNT=0
SOURCE_CLS=""
SOURCE_CLS_COUNT=0
if [[ -d "$SOURCE_DIR/pvs_lvs" ]]; then
  mapfile -t SOURCE_LVS_RUNS < <(find "$SOURCE_DIR/pvs_lvs" -mindepth 1 -maxdepth 1 \
    -type d -exec test -s '{}/run.pvs' ';' -exec test -s '{}/pvslvsctl' ';' -print 2>/dev/null)
  SOURCE_LVS_RUN_COUNT="${#SOURCE_LVS_RUNS[@]}"
  SOURCE_LVS_RUN="${SOURCE_LVS_RUNS[0]:-}"
  if [[ "$SOURCE_LVS_RUN_COUNT" == 1 ]]; then
    mapfile -t SOURCE_CLS_FILES < <(find "$SOURCE_LVS_RUN" -type f -name '*.cls' -print 2>/dev/null)
    SOURCE_CLS_COUNT="${#SOURCE_CLS_FILES[@]}"
    SOURCE_CLS="${SOURCE_CLS_FILES[0]:-}"
  fi
fi

SOURCE_LVS_RUN_TRACKED=""
SOURCE_LVS_RUN_TRACKED_COUNT=0
SOURCE_CLS_TRACKED_COUNT=0
if [[ -d "$SOURCE_SNAPSHOT/pvs_lvs" ]]; then
  mapfile -t SOURCE_LVS_RUNS_TRACKED < <(
    find "$SOURCE_SNAPSHOT/pvs_lvs" -mindepth 1 -maxdepth 1 -type d \
      -exec test -s '{}/run.pvs' ';' -exec test -s '{}/pvslvsctl' ';' \
      -exec test -f '{}/.config.rul' ';' -exec test -s '{}/.technology.rul' ';' \
      -print 2>/dev/null
  )
  SOURCE_LVS_RUN_TRACKED_COUNT="${#SOURCE_LVS_RUNS_TRACKED[@]}"
  SOURCE_LVS_RUN_TRACKED="${SOURCE_LVS_RUNS_TRACKED[0]:-}"
fi
SOURCE_CLS_TRACKED=""
if [[ "$SOURCE_LVS_RUN_TRACKED_COUNT" == 1 ]]; then
  mapfile -t SOURCE_CLS_TRACKED_FILES < <(
    find "$SOURCE_LVS_RUN_TRACKED" -type f -name '*.cls' -print 2>/dev/null
  )
  SOURCE_CLS_TRACKED_COUNT="${#SOURCE_CLS_TRACKED_FILES[@]}"
  SOURCE_CLS_TRACKED="${SOURCE_CLS_TRACKED_FILES[0]:-}"
fi

SOURCE_CLS_RESULT=MISSING
SOURCE_BLACKBOXED_COUNT=MISSING
SOURCE_RO6_WRAPPER_MISMATCH_COUNT=0
SOURCE_TOP_59_MISMATCH_COUNT=0
SOURCE_EXACT_REDUCED_SIGNATURE_COUNT=0
SOURCE_CLS_SHA=MISSING
if [[ "$SOURCE_CLS_COUNT" == 1 && -s "$SOURCE_CLS" ]]; then
  SOURCE_CLS_RESULT="$(awk -F ':' '/Run Result/ {value=$2; gsub(/[^[:alnum:]_]/, "", value); print toupper(value); exit}' "$SOURCE_CLS")"
  SOURCE_BLACKBOXED_COUNT="$(awk -F '|' '/Cells that have been blackboxed/ {value=$2; gsub(/[[:space:]]/, "", value); print value; exit}' "$SOURCE_CLS")"
  SOURCE_RO6_WRAPPER_MISMATCH_COUNT="$(grep -Fc '(-, RO_tune6())' "$SOURCE_CLS" 2>/dev/null || true)"
  SOURCE_TOP_59_MISMATCH_COUNT="$(grep -Ec '^mptdc_axis_core[[:space:]]*\|[[:space:]]*59[[:space:]]*:[[:space:]]*59[[:space:]]*\|[[:space:]]*59[[:space:]]*:[[:space:]]*59[[:space:]]*\|[[:space:]]*mismatch' "$SOURCE_CLS" || true)"
  SOURCE_EXACT_REDUCED_SIGNATURE_COUNT="$(grep -Ec '^Total[[:space:]]*\|.*213,?960[[:space:]]*:[[:space:]]*213,?582.*380[[:space:]]*:[[:space:]]*2[[:space:]]*$' "$SOURCE_CLS" || true)"
  SOURCE_CLS_SHA="$(sha256sum "$SOURCE_CLS" | awk '{print $1}')"
fi

PREFLIGHT=PASS
[[ "$BRANCH" == SPADMIC_test ]] || { echo "STOP: branch must be SPADMIC_test"; PREFLIGHT=FAIL; }
[[ "$ACTUAL_HEAD" == "$EXPECTED_HEAD_VALUE" ]] || { echo "STOP: HEAD mismatch"; PREFLIGHT=FAIL; }
[[ -z "$TRACKED_STATUS" ]] || { echo "$TRACKED_STATUS"; echo "STOP: tracked tree is dirty"; PREFLIGHT=FAIL; }
for report in "$SOURCE_BASE_CLASS" "$SOURCE_BASE_RULES" "$SOURCE_SPECIAL" \
              "$SOURCE_HASHES_TRACKED" "$SOURCE_FILTER_TRACKED" \
              "$SOURCE_LVS_STATUS_TRACKED" "$SOURCE_LVS_TOOL_STATUS_TRACKED" \
              "$STANDALONE_GATE" "$STANDALONE_INPUTS"; do
  tracked_report "$report" || { echo "STOP: immutable tracked report missing: $report"; PREFLIGHT=FAIL; }
done
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  for report in "$BOUNDARY_GATE" "$BOUNDARY_DETAIL"; do
    tracked_report "$report" || {
      echo "STOP: immutable tracked boundary report missing: $report"
      PREFLIGHT=FAIL
    }
  done
fi
for path in "$SOURCE_HASHES" "$SOURCE_FILTER" "$SOURCE_LVS_STATUS" \
            "$SOURCE_LVS_TOOL_STATUS" "$STANDALONE_INPUTS_LIVE" \
            "$SOURCE_GENERATOR" "$PREP_HELPER" "$GATE_HELPER" \
            "$RAW_CLASSIFIER" "$PUBLISHER"; do
  [[ -s "$path" ]] || { echo "STOP: required source or script missing: $path"; PREFLIGHT=FAIL; }
done
for path in "$SOURCE_GDS" "$SOURCE_PHYSICAL" "$DCELL_CDL" "$FILLER_REPORT" \
            "$ROW_INFRA_REPORT" "$RO_CDL_SOURCE"; do
  [[ -s "$path" ]] || { echo "STOP: exact monolithic input missing: $path"; PREFLIGHT=FAIL; }
done
for pair in \
  "$SOURCE_HASHES:$SOURCE_HASHES_TRACKED" \
  "$SOURCE_FILTER:$SOURCE_FILTER_TRACKED" \
  "$SOURCE_LVS_STATUS:$SOURCE_LVS_STATUS_TRACKED" \
  "$SOURCE_LVS_TOOL_STATUS:$SOURCE_LVS_TOOL_STATUS_TRACKED"; do
  live="${pair%%:*}"
  tracked="${pair#*:}"
  cmp -s "$live" "$tracked" || {
    echo "STOP: live source evidence differs from its published snapshot: $live"
    PREFLIGHT=FAIL
  }
done
[[ -r "$CADENCE_ENV" ]] || { echo "STOP: Cadence environment is unreadable: $CADENCE_ENV"; PREFLIGHT=FAIL; }
[[ ! -e "$PVS_DIR" ]] || { echo "STOP: result directory exists: $PVS_DIR"; PREFLIGHT=FAIL; }
[[ "$SOURCE_LVS_RUN_COUNT" == 1 && "$SOURCE_CLS_COUNT" == 1 ]] || {
  echo "STOP: source must have one LVS run and one CLS report"; PREFLIGHT=FAIL;
}
[[ "$SOURCE_LVS_RUN_TRACKED_COUNT" == 1 && "$SOURCE_CLS_TRACKED_COUNT" == 1 ]] || {
  echo "STOP: source snapshot must contain one complete LVS run and one CLS report"
  PREFLIGHT=FAIL
}
for path in "$SOURCE_LVS_RUN_TRACKED/run.pvs" "$SOURCE_LVS_RUN_TRACKED/pvslvsctl" \
            "$SOURCE_LVS_RUN_TRACKED/.technology.rul" "$SOURCE_CLS_TRACKED"; do
  tracked_report "$path" || {
    echo "STOP: tracked source LVS template member missing: $path"
    PREFLIGHT=FAIL
  }
done
tracked_file "$SOURCE_LVS_RUN_TRACKED/.config.rul" || {
  echo "STOP: tracked source LVS .config.rul is missing"
  PREFLIGHT=FAIL
}
[[ ! -s "$SOURCE_LVS_RUN_TRACKED/.config.rul" ]] || {
  echo "STOP: tracked source LVS .config.rul must be empty"
  PREFLIGHT=FAIL
}
cmp -s "$SOURCE_CLS" "$SOURCE_CLS_TRACKED" || {
  echo "STOP: live source CLS differs from its published snapshot"
  PREFLIGHT=FAIL
}
[[ "$(report_value "$SOURCE_LVS_STATUS" PVS_LVS_STATUS)" == MISMATCH && \
   "$(report_value "$SOURCE_LVS_TOOL_STATUS" PVS_LVS_RC)" == 0 && \
   "$SOURCE_CLS_RESULT" == MISMATCH && "$SOURCE_BLACKBOXED_COUNT" == 0 && \
   "$SOURCE_RO6_WRAPPER_MISMATCH_COUNT" == 1 && \
   "$SOURCE_TOP_59_MISMATCH_COUNT" == 1 && \
   "$SOURCE_EXACT_REDUCED_SIGNATURE_COUNT" == 1 ]] || {
  echo "STOP: source raw LVS is not the exact 380-layout/2-source RO abstraction mismatch"
  PREFLIGHT=FAIL
}
RAW_CLASSIFIER_RC=99
RAW_ATTRIBUTION_STATUS=MISSING
RAW_MISMATCH_ATTRIBUTION=MISSING
RAW_DIRECT_ELIGIBLE=MISSING
RAW_LAYOUT_ONLY_COUNT=MISSING
RAW_SOURCE_ONLY_COUNT=MISSING
RAW_CLASSIFIER_SHA=MISSING
RAW_CLASSIFICATION_SHA=MISSING
if [[ "$SOURCE_CLS_COUNT" == 1 && -s "$SOURCE_CLS" && -s "$RAW_CLASSIFIER" ]]; then
  RAW_CLASSIFICATION_TMP="$(mktemp /tmp/mptdc_ro6_raw_mismatch.XXXXXX.rpt)"
  set +e
  python3 "$RAW_CLASSIFIER" \
    --cls "$SOURCE_CLS" \
    --out "$RAW_CLASSIFICATION_TMP" \
    --expected-ro-instance u_core_u_osc_fast_u_ro_tune4 \
    --expected-ro-instance u_core_u_osc_slow_u_ro_tune4
  RAW_CLASSIFIER_RC=$?
  set +e
  RAW_ATTRIBUTION_STATUS="$(report_value "$RAW_CLASSIFICATION_TMP" STATUS)"
  RAW_MISMATCH_ATTRIBUTION="$(report_value "$RAW_CLASSIFICATION_TMP" MISMATCH_ATTRIBUTION)"
  RAW_DIRECT_ELIGIBLE="$(report_value "$RAW_CLASSIFICATION_TMP" DIRECT_MONOLITHIC_ELIGIBLE)"
  RAW_LAYOUT_ONLY_COUNT="$(report_value "$RAW_CLASSIFICATION_TMP" LAYOUT_ONLY_INSTANCE_COUNT)"
  RAW_SOURCE_ONLY_COUNT="$(report_value "$RAW_CLASSIFICATION_TMP" SOURCE_ONLY_INSTANCE_COUNT)"
  RAW_CLASSIFIER_SHA="$(sha256sum "$RAW_CLASSIFIER" 2>/dev/null | awk '{print $1}')"
  RAW_CLASSIFICATION_SHA="$(sha256sum "$RAW_CLASSIFICATION_TMP" 2>/dev/null | awk '{print $1}')"
fi
[[ "$RAW_CLASSIFIER_RC" -eq 0 && "$RAW_ATTRIBUTION_STATUS" == PASS && \
   "$RAW_MISMATCH_ATTRIBUTION" == EXACT_TWO_RO6_INTERNALS_ONLY && \
   "$RAW_DIRECT_ELIGIBLE" == YES && "$RAW_LAYOUT_ONLY_COUNT" == 380 && \
   "$RAW_SOURCE_ONLY_COUNT" == 2 && "$RAW_CLASSIFIER_SHA" =~ ^[0-9a-f]{64}$ && \
   "$RAW_CLASSIFICATION_SHA" =~ ^[0-9a-f]{64}$ ]] || {
  echo "STOP: raw mismatch is not attributable exclusively to the two RO_tune6 interiors"
  PREFLIGHT=FAIL
}
[[ "$(report_value "$SOURCE_FILTER" LVS_SOURCE_CONTRACT_STATUS)" == PASS && \
   "$(report_value "$SOURCE_FILTER" SOURCE_KIND)" == INNOVUS_SAVE_NETLIST_PHYS_INCLUDE_POWER_GROUND && \
   "$(report_value "$SOURCE_FILTER" PHYSICAL_ONLY_FILLER_REMOVAL_STATUS)" == PASS && \
   "$(report_value "$SOURCE_FILTER" RO6_PIN_NORMALIZATION)" == EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS && \
   "$(report_value "$SOURCE_FILTER" RO_TUNE6_INSTANCE_COUNT)" == 2 && \
   "$(report_value "$SOURCE_FILTER" RO_TUNE6_INSTANCE_NAME_STATUS)" == PASS && \
   "$(report_value "$SOURCE_FILTER" PHYSICAL_TIE_PRESERVATION_STATUS)" == PASS && \
   "$(report_value "$SOURCE_FILTER" UNRESOLVED_ACTIVE_MASTER_COUNT)" == 0 ]] || {
  echo "STOP: source physical LVS contract is not attributable"; PREFLIGHT=FAIL;
}
[[ "$(report_value "$SOURCE_BASE_CLASS" CLASSIFICATION_STATUS)" == PASS && \
   "$(report_value "$SOURCE_BASE_CLASS" PVS_BASE_DRC_CLASS)" == ANTENNA_ONLY_MANAGER_EXCEPTION && \
   "$(report_value "$SOURCE_BASE_CLASS" DRC_TOTAL_PRIMARY)" == 136 && \
   "$(report_value "$SOURCE_BASE_CLASS" NONZERO_RULE_COUNT)" == 4 && \
   "$(report_value "$SOURCE_BASE_CLASS" NONZERO_RULE_SET)" == R1M2P1,R1M3P1,R2M2P1,R2M3P1 && \
   "$(report_value "$SOURCE_BASE_CLASS" NON_ANTENNA_RULE_COUNT)" == 0 && \
   "$(report_value "$SOURCE_BASE_CLASS" ANTENNA_REPAIR_ATTEMPTED)" == NO ]] || {
  echo "STOP: base DRC is not the exact accepted 136-result antenna-only signature"
  PREFLIGHT=FAIL
}
[[ "$(awk -F '\t' 'NR > 1 {print $1":"$2":"$3}' "$SOURCE_BASE_RULES" | paste -sd, -)" == \
   R1M2P1:6:6,R1M3P1:68:68,R2M2P1:7:7,R2M3P1:55:55 ]] || {
  echo "STOP: antenna rule counts differ from the accepted source report"; PREFLIGHT=FAIL;
}
[[ "$(grep -Ec '15 Problem\(s\) \(IMPVFC-94\)' "$SOURCE_SPECIAL" || true)" == 1 ]] || {
  echo "STOP: source Innovus special connectivity is not the exact PG15 state"; PREFLIGHT=FAIL;
}
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  [[ "$(report_value "$BOUNDARY_GATE" SOURCE_PVS_RUN_ID)" == "$SOURCE_PVS_RUN_ID" && \
     "$(report_value "$BOUNDARY_GATE" BOUNDARY_PVS_RUN_ID)" == "$BOUNDARY_PVS_RUN_ID" && \
     "$(report_value "$BOUNDARY_GATE" STANDALONE_PVS_RUN_ID)" == "$STANDALONE_PVS_RUN_ID" && \
     "$(report_value "$BOUNDARY_GATE" RAW_FULL_TOP_LVS_STATUS)" == MISMATCH_RO_ABSTRACTION_ONLY && \
     "$(report_value "$BOUNDARY_GATE" PVS_TOP_BOUNDARY_LVS)" == MATCH && \
     "$(report_value "$BOUNDARY_GATE" PVS_RO6_STANDALONE_LVS)" == MATCH && \
     "$(report_value "$BOUNDARY_GATE" COMPOSITIONAL_LVS_STATUS)" == PASS && \
     "$(report_value "$BOUNDARY_GATE" RAW_FULL_TOP_CLS_SHA256)" == "$SOURCE_CLS_SHA" && \
     "$(report_value "$BOUNDARY_GATE" NEXT_STAGE)" == PVS_RO6_MONOLITHIC_FULL_TOP_LVS && \
     "$(report_value "$BOUNDARY_GATE" DECISION)" == PASS_MONOLITHIC_LVS_CONTINUE ]] || {
    echo "STOP: boundary evidence is not an explicit attributable top MATCH"; PREFLIGHT=FAIL;
  }
  [[ "$(report_value "$BOUNDARY_DETAIL" SOURCE_PVS_RUN_ID)" == "$SOURCE_PVS_RUN_ID" && \
     "$(report_value "$BOUNDARY_DETAIL" STANDALONE_PVS_RUN_ID)" == "$STANDALONE_PVS_RUN_ID" && \
     "$(report_value "$BOUNDARY_DETAIL" PVS_LVS_STATUS)" == MATCH && \
     "$(report_value "$BOUNDARY_DETAIL" BOUNDARY_REMAINDER_CLASS)" == NONE_MATCH && \
     "$(report_value "$BOUNDARY_DETAIL" SIGNOFF_ELIGIBLE)" == NO && \
     "$(report_value "$BOUNDARY_DETAIL" DECISION)" == PASS_COMPOSITIONAL_LVS && \
     "$(report_value "$BOUNDARY_DETAIL" NEXT_STAGE)" == PVS_RO6_MONOLITHIC_FULL_TOP_LVS ]] || {
    echo "STOP: detailed boundary gate is not the exact no-remainder MATCH"
    PREFLIGHT=FAIL
  }
fi
[[ "$(report_value "$STANDALONE_GATE" PVS_LVS)" == MATCH && \
   "$(report_value "$STANDALONE_GATE" CLS_RUN_RESULT)" == MATCH && \
   "$(report_value "$STANDALONE_GATE" BLACKBOXED_CELL_COUNT)" == 0 && \
   "$(report_value "$STANDALONE_GATE" OA_READ_ONLY_STATUS)" == PASS && \
   "$(report_value "$STANDALONE_GATE" RO6_CDL_PIN_CONTRACT_STATUS)" == PASS && \
   "$(report_value "$STANDALONE_GATE" DECISION)" == PASS_CONTINUE ]] || {
  echo "STOP: standalone RO_tune6 proof is not an explicit unblackboxed MATCH"; PREFLIGHT=FAIL;
}

SOURCE_GDS_SHA="$(sha256sum "$SOURCE_GDS" 2>/dev/null | awk '{print $1}')"
SOURCE_PHYSICAL_SHA="$(sha256sum "$SOURCE_PHYSICAL" 2>/dev/null | awk '{print $1}')"
DCELL_CDL_SHA="$(sha256sum "$DCELL_CDL" 2>/dev/null | awk '{print $1}')"
FILLER_REPORT_SHA="$(sha256sum "$FILLER_REPORT" 2>/dev/null | awk '{print $1}')"
ROW_INFRA_REPORT_SHA="$(sha256sum "$ROW_INFRA_REPORT" 2>/dev/null | awk '{print $1}')"
RO_CDL_SHA="$(sha256sum "$RO_CDL_SOURCE" 2>/dev/null | awk '{print $1}')"
[[ "$SOURCE_GDS_SHA" =~ ^[0-9a-f]{64}$ && "$SOURCE_GDS_SHA" == "$SOURCE_GDS_EXPECTED_SHA" && \
   "$SOURCE_PHYSICAL_SHA" == "$SOURCE_PHYSICAL_EXPECTED_SHA" && \
   "$DCELL_CDL_SHA" == "$DCELL_CDL_EXPECTED_SHA" && \
   "$FILLER_REPORT_SHA" == "$FILLER_REPORT_EXPECTED_SHA" && \
   "$ROW_INFRA_REPORT_SHA" == "$ROW_INFRA_REPORT_EXPECTED_SHA" && \
   "$SOURCE_RO_GDS_SHA" == "$STANDALONE_RO_GDS_SHA" && \
   "$RO_CDL_SHA" == "$STANDALONE_RO_CDL_SHA" ]] || {
  echo "STOP: source, standalone, or live input hashes disagree"; PREFLIGHT=FAIL;
}
if [[ "$DIRECT_FULL_TOP" -eq 0 ]]; then
  [[ "$SOURCE_GDS_SHA" == "$(report_value "$BOUNDARY_GATE" MERGED_GDS_SHA256)" && \
     "$SOURCE_RO_GDS_SHA" == "$(report_value "$BOUNDARY_GATE" RO_GDS_SHA256)" && \
     "$RO_CDL_SHA" == "$(report_value "$BOUNDARY_GATE" RO_CDL_SHA256)" ]] || {
    echo "STOP: boundary hashes disagree with source and standalone evidence"
    PREFLIGHT=FAIL
  }
fi

echo "PVS_RO6_MONOLITHIC_PREFLIGHT=$PREFLIGHT"
echo "LVS_PREREQUISITE_MODE=$LVS_PREREQUISITE_MODE"
echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID_VALUE"
echo "BOUNDARY_PROOF_STATUS=$BOUNDARY_PROOF_STATUS"
echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
echo "PVS_RUN_ID=$PVS_RUN_ID"
echo "SOURCE_RAW_LVS_SIGNATURE=LAYOUT_213960_SCHEMATIC_213582_UNMATCHED_380_2"
echo "MERGED_GDS_SHA256=$SOURCE_GDS_SHA"
echo "RO_GDS_SHA256=$SOURCE_RO_GDS_SHA"
echo "RO_CDL_SHA256=$RO_CDL_SHA"
if [[ "$PREFLIGHT" != PASS ]]; then
  echo "DECISION=FAIL_STOP"
  exit 4
fi

mkdir -p "$PVS_DIR/inputs" "$PVS_DIR/outputs" "$PVS_DIR/manifests" \
  "$PVS_DIR/reports" "$PVS_DIR/logs" "$PVS_DIR/pvs_lvs"
cp -p "$RAW_CLASSIFICATION_TMP" "$PVS_DIR/reports/pvs_ro6_raw_mismatch_attribution.rpt"
LOCAL_RO_CDL="$PVS_DIR/inputs/RO_tune6.standalone_matched.cdl"
cp -p "$RO_CDL_SOURCE" "$LOCAL_RO_CDL"
LOCAL_RO_CDL_SHA="$(sha256sum "$LOCAL_RO_CDL" | awk '{print $1}')"
COPY_STATUS=FAIL
[[ "$LOCAL_RO_CDL_SHA" == "$RO_CDL_SHA" ]] && COPY_STATUS=PASS

EXTERNAL_SOURCE="$PVS_DIR/outputs/mptdc_axis_core_pnr_lvs_external_ro6.v"
UNUSED_HCELL="$PVS_DIR/outputs/pvs_hcell_ro6.NOT_USED"
EXTERNAL_SOURCE_REPORT="$PVS_DIR/reports/lvs_source_external_ro6.rpt"
set +e
python3 "$SOURCE_GENERATOR" \
  --input "$SOURCE_PHYSICAL" \
  --output "$EXTERNAL_SOURCE" \
  --hcell "$UNUSED_HCELL" \
  --report "$EXTERNAL_SOURCE_REPORT" \
  --cdl "$DCELL_CDL" \
  --filler-report "$FILLER_REPORT" \
  --row-infra-report "$ROW_INFRA_REPORT" \
  --ro-model external-cdl \
  --ro-cdl "$LOCAL_RO_CDL" \
  --expected-ro-instance u_core_u_osc_fast_u_ro_tune4 \
  --expected-ro-instance u_core_u_osc_slow_u_ro_tune4 \
  2>&1 | tee "$PVS_DIR/logs/generate_external_ro6_source.log"
SOURCE_RC=${PIPESTATUS[0]}
set +e

SOURCE_STATUS="$(report_value "$EXTERNAL_SOURCE_REPORT" LVS_SOURCE_CONTRACT_STATUS)"
SOURCE_MODEL_MODE="$(report_value "$EXTERNAL_SOURCE_REPORT" RO_MODEL_MODE)"
SOURCE_WRAPPER_COUNT="$(report_value "$EXTERNAL_SOURCE_REPORT" RO_TUNE6_WRAPPER_MODULE_COUNT)"
SOURCE_HCELL_STATUS="$(report_value "$EXTERNAL_SOURCE_REPORT" LVS_HCELL_STATUS)"
SOURCE_HCELL_COUNT="$(report_value "$EXTERNAL_SOURCE_REPORT" LVS_HCELL_ENTRY_COUNT)"
SOURCE_RO_CDL_STATUS="$(report_value "$EXTERNAL_SOURCE_REPORT" RO_EXTERNAL_CDL_PIN_STATUS)"
SOURCE_RO_CDL_SHA="$(report_value "$EXTERNAL_SOURCE_REPORT" RO_EXTERNAL_CDL_SHA256)"

MONOLITHIC_RUN="$PVS_DIR/pvs_lvs/mptdc_axis_core_ro6_external_cdl_script"
PREP_RC=99
if [[ "$SOURCE_RC" -eq 0 && "$COPY_STATUS" == PASS && "$SOURCE_STATUS" == PASS && \
      "$SOURCE_MODEL_MODE" == EXTERNAL_CDL && "$SOURCE_WRAPPER_COUNT" == 0 && \
      "$SOURCE_HCELL_STATUS" == NOT_USED && "$SOURCE_HCELL_COUNT" == 0 && \
      "$SOURCE_RO_CDL_STATUS" == PASS && "$SOURCE_RO_CDL_SHA" == "$RO_CDL_SHA" && \
      ! -e "$UNUSED_HCELL" ]]; then
  set +e
  python3 "$PREP_HELPER" \
    --template-run "$SOURCE_LVS_RUN_TRACKED" \
    --run-dir "$MONOLITHIC_RUN" \
    --gds "$SOURCE_GDS" \
    --source "$EXTERNAL_SOURCE" \
    --dcell-cdl "$DCELL_CDL" \
    --ro-cdl "$LOCAL_RO_CDL" \
    2>&1 | tee "$PVS_DIR/logs/prepare_ro6_monolithic_lvs.log"
  PREP_RC=${PIPESTATUS[0]}
  set +e
fi

PVS_RC=99
if [[ "$PREP_RC" -eq 0 ]] && load_cadence_env "$CADENCE_ENV"; then
  set +e
  (
    cd "$MONOLITHIC_RUN" || exit 3
    bash ./run.pvs
  ) 2>&1 | tee "$PVS_DIR/logs/pvs_ro6_monolithic_lvs.log"
  PVS_RC=${PIPESTATUS[0]}
  set +e
fi

GATE_REPORT="$PVS_DIR/reports/pvs_ro6_monolithic_lvs_status.rpt"
set +e
python3 "$GATE_HELPER" \
  --run-dir "$MONOLITHIC_RUN" \
  --pvs-rc "$PVS_RC" \
  --gds "$SOURCE_GDS" \
  --source "$EXTERNAL_SOURCE" \
  --dcell-cdl "$DCELL_CDL" \
  --ro-cdl "$LOCAL_RO_CDL" \
  --out "$GATE_REPORT" \
  2>&1 | tee "$PVS_DIR/logs/gate_ro6_monolithic_lvs.log"
GATE_RC=${PIPESTATUS[0]}
set +e

MONOLITHIC_STATUS="$(report_value "$GATE_REPORT" MONOLITHIC_LVS_STATUS)"
BLACKBOXED_COUNT="$(report_value "$GATE_REPORT" LVS_BLACKBOXED_CELL_COUNT)"
HCELL_STATUS="$(report_value "$GATE_REPORT" LVS_HCELL_STATUS)"
LVS_SIGNOFF_ELIGIBLE="$(report_value "$GATE_REPORT" LVS_SIGNOFF_ELIGIBLE)"
CLS_RUN_RESULT="$(report_value "$GATE_REPORT" CLS_RUN_RESULT)"
CELLS_WHICH_MISMATCH="$(report_value "$GATE_REPORT" CELLS_WHICH_MISMATCH)"
TOP_PIN_MATCH_STATUS="$(report_value "$GATE_REPORT" TOP_59_PIN_MATCH_STATUS)"
RO6_PIN_MATCH_STATUS="$(report_value "$GATE_REPORT" RO6_19_PIN_MATCH_STATUS)"
MISSING_INSTANCE_COUNT="$(report_value "$GATE_REPORT" MISSING_INSTANCE_EVIDENCE_COUNT)"
SHORT_OPEN_STATUS="$(report_value "$GATE_REPORT" SHORT_OPEN_EVIDENCE_STATUS)"
DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
if [[ "$SOURCE_RC" -eq 0 && "$PREP_RC" -eq 0 && "$PVS_RC" -eq 0 && \
      "$GATE_RC" -eq 0 && "$MONOLITHIC_STATUS" == MATCH && \
      "$BLACKBOXED_COUNT" == 0 && "$HCELL_STATUS" == NOT_USED && \
      "$CLS_RUN_RESULT" == MATCH && "$CELLS_WHICH_MISMATCH" == 0 && \
      "$TOP_PIN_MATCH_STATUS" == PASS && "$RO6_PIN_MATCH_STATUS" == PASS && \
      "$MISSING_INSTANCE_COUNT" == 0 && "$SHORT_OPEN_STATUS" == PASS && \
      "$LVS_SIGNOFF_ELIGIBLE" == YES ]]; then
  DECISION=PASS_MONOLITHIC_LVS
  NEXT_STAGE=PVS_DRC_DENSITY_AFTER_MONOLITHIC_LVS
fi

EXTERNAL_SOURCE_SHA="$(sha256sum "$EXTERNAL_SOURCE" 2>/dev/null | awk '{print $1}')"
{
  echo "PVS_RUN_CLASS=MONOLITHIC_FULL_TOP_LVS_PROOF"
  echo "LVS_PREREQUISITE_MODE=$LVS_PREREQUISITE_MODE"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
  echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID_VALUE"
  echo "BOUNDARY_PROOF_STATUS=$BOUNDARY_PROOF_STATUS"
  echo "RAW_CLS_SHA256=$SOURCE_CLS_SHA"
  echo "RAW_CLASSIFIER_SHA256=$RAW_CLASSIFIER_SHA"
  echo "RAW_CLASSIFICATION_REPORT_SHA256=$RAW_CLASSIFICATION_SHA"
  echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
  echo "LVS_TEMPLATE_RUN=$SOURCE_LVS_RUN_TRACKED"
  echo "MERGED_GDS=$SOURCE_GDS"
  echo "MERGED_GDS_SHA256=$SOURCE_GDS_SHA"
  echo "PHYSICAL_SOURCE=$SOURCE_PHYSICAL"
  echo "PHYSICAL_SOURCE_SHA256=$SOURCE_PHYSICAL_SHA"
  echo "MONOLITHIC_SOURCE=$EXTERNAL_SOURCE"
  echo "MONOLITHIC_SOURCE_SHA256=$EXTERNAL_SOURCE_SHA"
  echo "DCELL_CDL=$DCELL_CDL"
  echo "DCELL_CDL_SHA256=$DCELL_CDL_SHA"
  echo "RO_GDS_SHA256=$SOURCE_RO_GDS_SHA"
  echo "RO_CDL=$LOCAL_RO_CDL"
  echo "RO_CDL_SHA256=$LOCAL_RO_CDL_SHA"
  echo "RO_MODEL_MODE=EXTERNAL_CDL"
  echo "LVS_HCELL_STATUS=NOT_USED"
  echo "LVS_BLACKBOX_STATUS=NOT_USED"
  echo "LVS_POSITION_BUS_MAPPING_STATUS=NOT_USED"
  echo "LVS_GLOBAL_PORT_PROMOTION_STATUS=NOT_USED"
  echo "LVS_CONFIG_RULE_STATUS=PASS_EMPTY"
  echo "LVS_TECHNOLOGY_RULE_STATUS=PASS"
} > "$PVS_DIR/manifests/pvs_ro6_monolithic_lvs_inputs.rpt"

{
  echo "STEP=PVS_RO6_MONOLITHIC_FULL_TOP_LVS"
  echo "PVS_RUN_CLASS=MONOLITHIC_FULL_TOP_LVS_PROOF"
  echo "LVS_PREREQUISITE_MODE=$LVS_PREREQUISITE_MODE"
  echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
  echo "SOURCE_PVS_EVIDENCE_ID=$SOURCE_PVS_EVIDENCE_ID"
  echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID_VALUE"
  echo "BOUNDARY_PROOF_STATUS=$BOUNDARY_PROOF_STATUS"
  echo "RAW_MISMATCH_ATTRIBUTION=$RAW_MISMATCH_ATTRIBUTION"
  echo "RAW_CLASSIFIER_RC=$RAW_CLASSIFIER_RC"
  echo "RAW_CLS_SHA256=$SOURCE_CLS_SHA"
  echo "RAW_CLASSIFIER_SHA256=$RAW_CLASSIFIER_SHA"
  echo "RAW_CLASSIFICATION_REPORT_SHA256=$RAW_CLASSIFICATION_SHA"
  echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
  echo "SOURCE_RC=$SOURCE_RC"
  echo "SOURCE_MODEL_MODE=$SOURCE_MODEL_MODE"
  echo "SOURCE_WRAPPER_COUNT=$SOURCE_WRAPPER_COUNT"
  echo "SOURCE_HCELL_ENTRY_COUNT=$SOURCE_HCELL_COUNT"
  echo "RO_CDL_COPY_STATUS=$COPY_STATUS"
  echo "PREP_RC=$PREP_RC"
  echo "CADENCE_ENV_RC=$CADENCE_ENV_RC"
  echo "CADENCE_ENV_STATUS=$CADENCE_ENV_STATUS"
  echo "PVS_RC=$PVS_RC"
  echo "GATE_RC=$GATE_RC"
  echo "MONOLITHIC_LVS_STATUS=$MONOLITHIC_STATUS"
  echo "LVS_BLACKBOXED_CELL_COUNT=$BLACKBOXED_COUNT"
  echo "LVS_HCELL_STATUS=$HCELL_STATUS"
  echo "CLS_RUN_RESULT=$CLS_RUN_RESULT"
  echo "CELLS_WHICH_MISMATCH=$CELLS_WHICH_MISMATCH"
  echo "TOP_59_PIN_MATCH_STATUS=$TOP_PIN_MATCH_STATUS"
  echo "RO6_19_PIN_MATCH_STATUS=$RO6_PIN_MATCH_STATUS"
  echo "MISSING_INSTANCE_EVIDENCE_COUNT=$MISSING_INSTANCE_COUNT"
  echo "SHORT_OPEN_EVIDENCE_STATUS=$SHORT_OPEN_STATUS"
  echo "LVS_SIGNOFF_ELIGIBLE=$LVS_SIGNOFF_ELIGIBLE"
  echo "MERGED_GDS_SHA256=$SOURCE_GDS_SHA"
  echo "RO_GDS_SHA256=$SOURCE_RO_GDS_SHA"
  echo "RO_CDL_SHA256=$RO_CDL_SHA"
  echo "SIGNOFF_ELIGIBLE=NO"
  echo "FINAL_PHYSICAL_SIGNOFF_READY=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$PVS_DIR/reports/operator_gate_pvs_monolithic_lvs.rpt"

{
  echo "STEP=MPTDC_LVS_DRC_HANDOFF"
  echo "LVS_PREREQUISITE_MODE=$LVS_PREREQUISITE_MODE"
  echo "BOUNDARY_PROOF_STATUS=$BOUNDARY_PROOF_STATUS"
  echo "MONOLITHIC_LVS_STATUS=$MONOLITHIC_STATUS"
  echo "LVS_BLACKBOXED_CELL_COUNT=$BLACKBOXED_COUNT"
  echo "LVS_HCELL_STATUS=$HCELL_STATUS"
  echo "CLS_RUN_RESULT=$CLS_RUN_RESULT"
  echo "CELLS_WHICH_MISMATCH=$CELLS_WHICH_MISMATCH"
  echo "TOP_59_PIN_MATCH_STATUS=$TOP_PIN_MATCH_STATUS"
  echo "RO6_19_PIN_MATCH_STATUS=$RO6_PIN_MATCH_STATUS"
  echo "MISSING_INSTANCE_EVIDENCE_COUNT=$MISSING_INSTANCE_COUNT"
  echo "SHORT_OPEN_EVIDENCE_STATUS=$SHORT_OPEN_STATUS"
  echo "LVS_SIGNOFF_ELIGIBLE=$LVS_SIGNOFF_ELIGIBLE"
  echo "PVS_BASE_DRC_STATUS=FAIL_136_ANTENNA_ONLY"
  echo "NON_ANTENNA_DRC_STATUS=PASS"
  echo "ANTENNA_EXCEPTION_STATUS=ACCEPTED_PROJECT_POLICY"
  echo "ANTENNA_EXCEPTION_EVIDENCE_KIND=AUTO_CLASSIFIED_NOT_INDEPENDENTLY_SIGNED"
  echo "TOOL_CLEAN_DRC=NO"
  echo "INNOVUS_SPECIAL_CONNECTIVITY_STATUS=FAIL_15_DANGLING"
  echo "FINAL_PHYSICAL_SIGNOFF_READY=NO"
  echo "DECISION=$DECISION"
  echo "NEXT_STAGE=$NEXT_STAGE"
} | tee "$PVS_DIR/reports/mptdc_lvs_drc_handoff_status.rpt"

publish_stage
PUBLISH_RC=$?
if [[ "$PUBLISH_RC" -ne 0 ]]; then
  DECISION=FAIL_STOP
  NEXT_STAGE=REPUBLISH_MONOLITHIC_LVS_EVIDENCE
fi

echo "PVS_RO6_MONOLITHIC_STATUS=$MONOLITHIC_STATUS"
echo "LVS_PREREQUISITE_MODE=$LVS_PREREQUISITE_MODE"
echo "PVS_RUN_ID=$PVS_RUN_ID"
echo "SOURCE_PVS_RUN_ID=$SOURCE_PVS_RUN_ID"
echo "BOUNDARY_PVS_RUN_ID=$BOUNDARY_PVS_RUN_ID_VALUE"
echo "BOUNDARY_PROOF_STATUS=$BOUNDARY_PROOF_STATUS"
echo "STANDALONE_PVS_RUN_ID=$STANDALONE_PVS_RUN_ID"
echo "PVS_RC=$PVS_RC"
echo "LVS_BLACKBOXED_CELL_COUNT=$BLACKBOXED_COUNT"
echo "LVS_HCELL_STATUS=$HCELL_STATUS"
echo "LVS_SIGNOFF_ELIGIBLE=$LVS_SIGNOFF_ELIGIBLE"
echo "FINAL_PHYSICAL_SIGNOFF_READY=NO"
echo "DECISION=$DECISION"
echo "PUBLISH_RC=$PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
echo "NEXT_STAGE=$NEXT_STAGE"
if [[ "$DECISION" == PASS_MONOLITHIC_LVS && "$PUBLISH_RC" -eq 0 ]]; then
  exit 0
fi
exit 1
