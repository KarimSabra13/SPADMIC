#!/usr/bin/env bash
# =============================================================================
# TX packet-core provisional four-marker waiver and independent PVS DRC/LVS.
#
# This driver is intentionally separate from canonical Phase 2. It permits an
# early LVS diagnosis on one exact exported state while preserving PVS DRC as
# an honest independent result. It never marks the block signoff-ready.
# =============================================================================

set +e

WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
ACTIVE_ENV="${SPADMIC_TX_PACKET_PVS_WAIVER_ACTIVE_ENV:-$WORK_ROOT/diagnostics/tx_packet_pvs_waiver_active.env}"
PHASE2_ACTIVE_ENV="${SPADMIC_TX_PACKET_PHASE2_ACTIVE_ENV:-$WORK_ROOT/diagnostics/tx_packet_canonical_phase2_active.env}"
REPO_DEFAULT="/home/validmgr/ksabra/2026_SPAD/SPADMIC"
DEFAULT_STREAM_MAP="/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map"
DEFAULT_STDCELL_GDS="/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds"
DEFAULT_DRC_TEMPLATE="/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_tx_packet_core_HV"
COMMAND="${1:-help}"
ARGUMENT_1="${2:-}"
ARGUMENT_2="${3:-}"

usage() {
  cat <<'USAGE'
Usage:
  bash TOP/ci/server_run_tx_packet_pvs_waiver.sh init <expected-head> [phase2-active-env]
  bash TOP/ci/server_run_tx_packet_pvs_waiver.sh waiver-export
  bash TOP/ci/server_run_tx_packet_pvs_waiver.sh stage
  bash TOP/ci/server_run_tx_packet_pvs_waiver.sh pvs-drc-base
  bash TOP/ci/server_run_tx_packet_pvs_waiver.sh pvs-lvs
  bash TOP/ci/server_run_tx_packet_pvs_waiver.sh summary
  bash TOP/ci/server_run_tx_packet_pvs_waiver.sh status

Run one subcommand at a time. PVS DRC and LVS are independent after staging.
The exact four Innovus MET1 minimum-area markers are temporarily accepted only
for this diagnostic flow. PVS DRC is not waived. Final signoff remains NO.

For pvs-lvs, create a fresh canonical GUI template from the staged package and
set:
  SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE=/absolute/template/directory

If that template embeds different old GDS/source/CDL paths or top names, also
set the corresponding SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_* variables described
in TOP/docs/38_TX_PACKET_CORE_PROVISIONAL_DRC_WAIVER_AND_PVS_LVS_EXECUTION.md.
USAGE
}

append_active_assignment() {
  local name="$1"
  local value="$2"
  printf 'export %s=%q\n' "$name" "$value" >>"$ACTIVE_ENV"
}

kv_field() {
  local path="$1"
  local key="$2"
  if [[ -r "$path" ]]; then
    awk -F= -v key="$key" \
      '$1 == key {value = substr($0, index($0, "=") + 1)} END {print value}' \
      "$path"
  fi
}

load_session() {
  local required
  if [[ ! -r "$ACTIVE_ENV" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: provisional PVS active session is missing"
    echo "ACTIVE_ENV=$ACTIVE_ENV"
    return 1
  fi
  # shellcheck disable=SC1090
  source "$ACTIVE_ENV"
  for required in \
    TX3_REPO \
    TX3_WORK_ROOT \
    TX3_EXPECTED_HEAD \
    TX3_SESSION_ID \
    TX3_SESSION_ROOT \
    TX3_PHASE2_ACTIVE_ENV \
    TX3_PHASE2_ROOT \
    TX3_SOURCE_ARTIFACT_HEAD \
    TX3_SOURCE_BLOCK_ROOT \
    TX3_STEP27_STATUS \
    TX3_STEP27_DRIVER \
    TX3_STEP27_ANALYSIS \
    TX3_STEP27_ANALYSIS_SHA256 \
    TX3_WAIVER_RUN \
    TX3_WAIVER_BLOCK_ROOT \
    TX3_HANDOFF_ROOT \
    TX3_PACKAGE \
    TX3_STREAM_MAP \
    TX3_STDCELL_GDS
  do
    if [[ -z "${!required:-}" ]]; then
      echo "STOP_HERE_DO_NOT_CONTINUE: missing $required in $ACTIVE_ENV"
      return 1
    fi
  done
  mkdir -p \
    "$TX3_SESSION_ROOT/logs" \
    "$TX3_SESSION_ROOT/reports" \
    "$TX3_SESSION_ROOT/status"
  return $?
}

record_status() {
  local step="$1"
  local status="$2"
  local rc="$3"
  local result="$4"
  local report="$TX3_SESSION_ROOT/status/${step}.rpt"
  local utc
  utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  {
    echo "LABEL=SPADMIC_TX_PACKET_PROVISIONAL_PVS_WAIVER"
    echo "STEP=$step"
    echo "DATE_UTC=$utc"
    echo "HEAD_EXPECTED=$TX3_EXPECTED_HEAD"
    echo "STATUS=$status"
    echo "RC=$rc"
    echo "RESULT=$result"
    echo "SESSION_ROOT=$TX3_SESSION_ROOT"
    echo "PACKAGE=$TX3_PACKAGE"
    echo "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY"
    echo "PVS_DRC_WAIVER=NO"
    echo "LVS_DIAGNOSTIC_ONLY=YES"
    echo "MANUAL_DRC_FIX_REQUIRED=YES"
    echo "BLOCK_PROMOTION_AUTHORIZED=NO"
    echo "FINAL_SIGNOFF_READY=NO"
    echo "POLICY=ONE_OPERATOR_COMMAND_PER_GATE_NO_AUTO_ADVANCE"
  } | tee "$report"
  {
    echo
    echo "[$utc] STEP=$step STATUS=$status RC=$rc RESULT=$result"
    echo "REPORT=$report"
  } >>"$TX3_SESSION_ROOT/execution_journal.rpt"
}

status_field() {
  local step="$1"
  local key="$2"
  kv_field "$TX3_SESSION_ROOT/status/${step}.rpt" "$key"
}

require_step_pass() {
  local step="$1"
  local actual
  actual="$(status_field "$step" STATUS)"
  if [[ "$actual" != "PASS" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: prerequisite did not pass"
    echo "REQUIRED_STEP=$step"
    echo "ACTUAL_STATUS=${actual:-MISSING}"
    return 1
  fi
  return 0
}

check_current_head() {
  local actual cd_rc
  actual=UNKNOWN
  cd "$TX3_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual="$(git rev-parse HEAD 2>/dev/null)"
  fi
  echo "EXPECTED_HEAD=$TX3_EXPECTED_HEAD"
  echo "ACTUAL_HEAD=$actual"
  if [[ "$cd_rc" -ne 0 || "$actual" != "$TX3_EXPECTED_HEAD" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: repository HEAD mismatch"
    return 1
  fi
  return 0
}

load_cadence() {
  if [[ ! -r /eda/cadence/eda_2023-2024 ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Cadence environment file is missing"
    return 1
  fi
  # shellcheck disable=SC1091
  source /eda/cadence/eda_2023-2024
  return $?
}

validate_step27_evidence() {
  local status_report="$1"
  local driver_report="$2"
  local analysis_report="$3"
  local phase2_expected_head="$4"

  if [[ "$(kv_field "$status_report" STATUS)" != "PASS" \
      || "$(kv_field "$status_report" RC)" != "0" \
      || "$(kv_field "$status_report" RESULT)" != "MIN_AREA_CHAINED_LANDING_R6_CLASSIFIED_NOT_CLOSED_NO_SAVE_EXPORT_OR_PVS" \
      || "$(kv_field "$driver_report" SOURCE_ARTIFACT_HEAD)" != "$phase2_expected_head" \
      || "$(kv_field "$driver_report" EXPECTED_REPORT_DRIVER_HEAD)" != "$(kv_field "$driver_report" REPORT_DRIVER_HEAD)" \
      || "$(kv_field "$driver_report" TRIAL_REVISION)" != "R6" \
      || "$(kv_field "$driver_report" TRIAL_RC)" != "8" \
      || "$(kv_field "$driver_report" ANALYSIS_RC)" != "0" \
      || "$(kv_field "$driver_report" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$driver_report" TRIAL_PROCESS_RESULT)" != "CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$driver_report" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$driver_report" BASE_STAGE_STATUS)" != "PASS_EXACT_FOUR_0P1777_SURVIVORS" \
      || "$(kv_field "$driver_report" CHAIN_STAGE_STATUS)" != "APPLIED_EXACT_FOUR" \
      || "$(kv_field "$driver_report" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$driver_report" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$driver_report" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$driver_report" PVS)" != "NOT_RUN" \
      || "$(kv_field "$analysis_report" LABEL)" != "SPADMIC_TX_PACKET_MIN_AREA_CHAINED_LANDING_ANALYSIS" \
      || "$(kv_field "$analysis_report" STATUS)" != "PASS" \
      || "$(kv_field "$analysis_report" RESULT)" != "MIN_AREA_CHAINED_LANDING_TRIAL_CLASSIFIED" \
      || "$(kv_field "$analysis_report" TRIAL_REVISION)" != "R6" \
      || "$(kv_field "$analysis_report" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$analysis_report" TRIAL_PROCESS_RESULT)" != "CHAINED_ENDPOINT_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$analysis_report" BASE_STAGE_STATUS)" != "PASS_EXACT_FOUR_0P1777_SURVIVORS" \
      || "$(kv_field "$analysis_report" BASE_DRC_VIOLATION_COUNT)" != "4" \
      || "$(kv_field "$analysis_report" BASE_DRC_MARKER_COUNT)" != "4" \
      || "$(kv_field "$analysis_report" BASE_MIN_AREA_NETS)" != "n_9677 n_9693 n_9696 n_9697" \
      || "$(kv_field "$analysis_report" BASE_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$analysis_report" BASE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$analysis_report" BASE_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$analysis_report" BASE_MARKER_DATABASE_TOTAL)" != "25" \
      || "$(kv_field "$analysis_report" BASE_CANONICAL_FIXED_STUB_NET_COUNT)" != "6" \
      || "$(kv_field "$analysis_report" BASE_PATCH_ATTEMPTED_COUNT)" != "6" \
      || "$(kv_field "$analysis_report" BASE_PATCH_APPLIED_COUNT)" != "6" \
      || "$(kv_field "$analysis_report" FINAL_DRC_VIOLATION_COUNT)" != "4" \
      || "$(kv_field "$analysis_report" FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$analysis_report" FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$analysis_report" FINAL_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$analysis_report" FINAL_MARKER_DATABASE_TOTAL)" != "25" \
      || "$(kv_field "$analysis_report" FINAL_MIN_AREA_NETS)" != "n_9677 n_9693 n_9696 n_9697" \
      || "$(kv_field "$analysis_report" ERROR_COUNT)" != "0" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 27 is not the exact four-marker source tuple"
    echo "STEP27_STATUS=$status_report"
    echo "STEP27_DRIVER=$driver_report"
    echo "STEP27_ANALYSIS=$analysis_report"
    return 1
  fi
  return 0
}

init_session() {
  local expected_head="$1"
  local phase2_env="${2:-$PHASE2_ACTIVE_ENV}"
  local repo actual_head cd_rc
  local step27_status step27_driver step27_analysis source_block_root
  local stamp session_id session_root waiver_run waiver_block_root
  local handoff_root package analysis_sha mkdir_rc

  if [[ -z "$expected_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: init requires expected HEAD"
    usage
    return 1
  fi
  if [[ ! -r "$phase2_env" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Phase 2 active environment is missing"
    echo "PHASE2_ACTIVE_ENV=$phase2_env"
    return 1
  fi
  # shellcheck disable=SC1090
  source "$phase2_env"
  if [[ -z "${TX2_REPO:-}" || -z "${TX2_SESSION_ROOT:-}" \
      || -z "${TX2_EXPECTED_HEAD:-}" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Phase 2 environment is incomplete"
    return 1
  fi
  step27_status="$TX2_SESSION_ROOT/status/27_min_area_chained_landing_trial_r6.rpt"
  step27_driver="$TX2_SESSION_ROOT/reports/27_min_area_chained_landing_trial_r6_driver.rpt"
  step27_analysis="$TX2_SESSION_ROOT/reports/27_min_area_chained_landing_analysis.rpt"
  if [[ ! -s "$step27_status" || ! -s "$step27_driver" || ! -s "$step27_analysis" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: required Step 27 evidence is missing"
    return 1
  fi
  validate_step27_evidence \
    "$step27_status" "$step27_driver" "$step27_analysis" "$TX2_EXPECTED_HEAD" \
    || return 1
  source_block_root="$(kv_field "$step27_driver" SOURCE_BLOCK_ROOT)"
  if [[ -z "$source_block_root" || ! -d "$source_block_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 27 source block root is missing"
    echo "SOURCE_BLOCK_ROOT=${source_block_root:-MISSING}"
    return 1
  fi

  repo="${SPADMIC_TX_REPO:-$TX2_REPO}"
  if [[ -z "$repo" ]]; then
    repo="$REPO_DEFAULT"
  fi
  actual_head=UNKNOWN
  cd "$repo" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$cd_rc" -ne 0 || "$actual_head" != "$expected_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: repository HEAD does not match init request"
    echo "EXPECTED_HEAD=$expected_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  stamp="$(date +%Y%m%d_%H%M%S)"
  session_id="tx_packet_pvs_waiver_${stamp}"
  session_root="$WORK_ROOT/diagnostics/$session_id"
  waiver_run="innovus_tx_packet_min_area_waiver_export_${stamp}"
  waiver_block_root="$WORK_ROOT/innovus/$waiver_run/blocks/tx_packet_core"
  handoff_root="$WORK_ROOT/handoff/innovus"
  package="$handoff_root/blocks/spadmic_tx_packet_core/$session_id"
  analysis_sha="$(sha256sum "$step27_analysis" | awk '{print $1}')"

  mkdir -p \
    "$session_root/logs" \
    "$session_root/reports" \
    "$session_root/status" \
    "$(dirname "$ACTIVE_ENV")"
  mkdir_rc=$?
  if [[ "$mkdir_rc" -ne 0 ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: cannot create Phase 3 session root"
    return 1
  fi
  : >"$ACTIVE_ENV"
  append_active_assignment TX3_REPO "$repo"
  append_active_assignment TX3_WORK_ROOT "$WORK_ROOT"
  append_active_assignment TX3_EXPECTED_HEAD "$expected_head"
  append_active_assignment TX3_SESSION_ID "$session_id"
  append_active_assignment TX3_SESSION_ROOT "$session_root"
  append_active_assignment TX3_PHASE2_ACTIVE_ENV "$phase2_env"
  append_active_assignment TX3_PHASE2_ROOT "$TX2_SESSION_ROOT"
  append_active_assignment TX3_SOURCE_ARTIFACT_HEAD "$TX2_EXPECTED_HEAD"
  append_active_assignment TX3_SOURCE_BLOCK_ROOT "$source_block_root"
  append_active_assignment TX3_STEP27_STATUS "$step27_status"
  append_active_assignment TX3_STEP27_DRIVER "$step27_driver"
  append_active_assignment TX3_STEP27_ANALYSIS "$step27_analysis"
  append_active_assignment TX3_STEP27_ANALYSIS_SHA256 "$analysis_sha"
  append_active_assignment TX3_WAIVER_RUN "$waiver_run"
  append_active_assignment TX3_WAIVER_BLOCK_ROOT "$waiver_block_root"
  append_active_assignment TX3_HANDOFF_ROOT "$handoff_root"
  append_active_assignment TX3_PACKAGE "$package"
  append_active_assignment TX3_STREAM_MAP "${SPADMIC_STREAMOUT_MAP_FILE:-$DEFAULT_STREAM_MAP}"
  append_active_assignment TX3_STDCELL_GDS "${SPADMIC_STDCELL_GDS:-$DEFAULT_STDCELL_GDS}"

  # shellcheck disable=SC1090
  source "$ACTIVE_ENV"
  {
    echo "LABEL=SPADMIC_TX_PACKET_PROVISIONAL_PVS_WAIVER_OBJECTIVE"
    echo "SESSION_ID=$TX3_SESSION_ID"
    echo "SOURCE_PHASE2_ROOT=$TX3_PHASE2_ROOT"
    echo "SOURCE_STEP27_ANALYSIS=$TX3_STEP27_ANALYSIS"
    echo "SOURCE_STEP27_ANALYSIS_SHA256=$TX3_STEP27_ANALYSIS_SHA256"
    echo "SOURCE_BLOCK_ROOT=$TX3_SOURCE_BLOCK_ROOT"
    echo "EXPECTED_HEAD=$TX3_EXPECTED_HEAD"
    echo "OBJECTIVE=EXPORT_EXACT_FOUR_MARKER_STATE_AND_RUN_INDEPENDENT_PVS_DRC_LVS"
    echo "STEP28_NORMALIZED_VIA_SIDE_TRIAL=SKIPPED_BY_OPERATOR_TEMPORARY_WAIVER_DECISION"
    echo "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY"
    echo "PVS_DRC_WAIVER=NO"
    echo "LVS_ACCEPTANCE=EXPLICIT_REPORT_LEVEL_MATCH_ONLY"
    echo "MANUAL_DRC_FIX_REQUIRED=YES"
    echo "FINAL_SIGNOFF_READY=NO"
  } >"$TX3_SESSION_ROOT/00_objective_and_policy.rpt"
  : >"$TX3_SESSION_ROOT/execution_journal.rpt"
  record_status 00_init PASS 0 PROVISIONAL_PVS_WAIVER_SESSION_INITIALIZED
  echo "ACTIVE_ENV=$ACTIVE_ENV"
  echo "SESSION_ROOT=$TX3_SESSION_ROOT"
  echo "WAIVER_BLOCK_ROOT=$TX3_WAIVER_BLOCK_ROOT"
  echo "PACKAGE=$TX3_PACKAGE"
  return 0
}

waiver_export() {
  local cadence_rc console wrapper_rc gate status_report waiver_report audit_report
  local status result current_sha
  load_session || return 1
  require_step_pass 00_init || return 1
  check_current_head || return 1
  current_sha="$(sha256sum "$TX3_STEP27_ANALYSIS" 2>/dev/null | awk '{print $1}')"
  if [[ "$current_sha" != "$TX3_STEP27_ANALYSIS_SHA256" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 27 source analysis hash changed"
    return 1
  fi
  load_cadence
  cadence_rc=$?
  if [[ "$cadence_rc" -ne 0 ]]; then
    record_status 01_waiver_export FAIL "$cadence_rc" CADENCE_ENVIRONMENT_NOT_LOADED
    return 1
  fi

  console="$TX3_SESSION_ROOT/logs/01_waiver_export.console.log"
  export SPADMIC_WORK_ROOT="$TX3_WORK_ROOT"
  export SPADMIC_STREAMOUT_MAP_FILE="$TX3_STREAM_MAP"
  export SPADMIC_STDCELL_GDS="$TX3_STDCELL_GDS"
  echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_min_area_waiver_export.sh $TX3_SOURCE_BLOCK_ROOT $TX3_STEP27_ANALYSIS $TX3_WAIVER_RUN spadmic_tx_packet_core"
  bash "$TX3_REPO/TOP/pnr/scripts/run_innovus_ooc_min_area_waiver_export.sh" \
    "$TX3_SOURCE_BLOCK_ROOT" \
    "$TX3_STEP27_ANALYSIS" \
    "$TX3_WAIVER_RUN" \
    spadmic_tx_packet_core \
    >"$console" 2>&1
  wrapper_rc=$?

  gate="$TX3_WAIVER_BLOCK_ROOT/reports/canonical_tx_lvs_waiver_gate.rpt"
  status_report="$TX3_WAIVER_BLOCK_ROOT/reports/min_area_waiver_export_status.rpt"
  waiver_report="$TX3_WAIVER_BLOCK_ROOT/reports/temporary_drc_waiver.rpt"
  audit_report="$TX3_WAIVER_BLOCK_ROOT/reports/gds_export_audit.rpt"
  status=FAIL
  result=EXACT_FOUR_MARKER_WAIVER_EXPORT_FAILED
  if [[ "$wrapper_rc" -eq 0 \
      && "$(kv_field "$gate" STATUS)" == "PASS" \
      && "$(kv_field "$gate" RESULT)" == "READY_FOR_PROVISIONAL_PVS_DRC_LVS" \
      && "$(kv_field "$gate" WAIVER_MARKER_COUNT)" == "4" \
      && "$(kv_field "$gate" WAIVER_NETS)" == "n_9677 n_9693 n_9696 n_9697" \
      && "$(kv_field "$gate" PVS_DRC_WAIVER)" == "NO" \
      && "$(kv_field "$gate" FINAL_SIGNOFF_READY)" == "NO" \
      && "$(kv_field "$status_report" FINAL_DRC_VIOLATION_COUNT)" == "4" \
      && "$(kv_field "$status_report" FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" == "0" \
      && "$(kv_field "$status_report" FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" == "0" \
      && "$(kv_field "$waiver_report" STATUS)" == "PASS" \
      && "$(kv_field "$audit_report" STATUS)" == "PASS" ]]; then
    status=PASS
    result=EXACT_FOUR_MARKER_WAIVER_STATE_EXPORTED_FOR_PROVISIONAL_PVS
  fi
  for report in "$gate" "$status_report" "$waiver_report" "$audit_report"; do
    if [[ -r "$report" ]]; then
      echo "===== $report ====="
      cat "$report"
    fi
  done
  if [[ "$status" != "PASS" && -r "$console" ]]; then
    echo "===== WAIVER EXPORT CONSOLE TAIL ====="
    tail -n 360 "$console"
  fi
  record_status 01_waiver_export "$status" "$wrapper_rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

stage_handoff() {
  local output_base stage_rc audit_rc status result qualification
  local stage_report audit_console path
  local -a stage_args reports logs
  load_session || return 1
  require_step_pass 01_waiver_export || return 1
  check_current_head || return 1
  if [[ -e "$TX3_PACKAGE" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable handoff package already exists"
    echo "PACKAGE=$TX3_PACKAGE"
    return 1
  fi

  output_base="$TX3_WAIVER_BLOCK_ROOT/outputs/spadmic_tx_packet_core"
  reports=(
    "$TX3_WAIVER_BLOCK_ROOT/context.rpt"
    "$TX3_WAIVER_BLOCK_ROOT/reports/canonical_tx_lvs_waiver_gate.rpt"
    "$TX3_WAIVER_BLOCK_ROOT/reports/temporary_drc_waiver.rpt"
    "$TX3_WAIVER_BLOCK_ROOT/reports/temporary_drc_waiver.tsv"
    "$TX3_WAIVER_BLOCK_ROOT/reports/gds_export_audit.rpt"
    "$TX3_WAIVER_BLOCK_ROOT/reports/min_area_waiver_export_status.rpt"
    "$TX3_WAIVER_BLOCK_ROOT/reports/min_area_waiver_patch_contract.tsv"
    "$TX3_WAIVER_BLOCK_ROOT/reports/min_area_waiver_patch_commands.rpt"
    "$TX3_WAIVER_BLOCK_ROOT/reports/drc_markers_post_waiver_replay.tsv"
    "$TX3_WAIVER_BLOCK_ROOT/reports/verify_drc_post_waiver_replay.rpt"
    "$TX3_WAIVER_BLOCK_ROOT/reports/verify_connectivity_regular_post_waiver_replay.rpt"
    "$TX3_WAIVER_BLOCK_ROOT/reports/verify_connectivity_special_post_waiver_replay.rpt"
  )
  logs=(
    "$TX3_WAIVER_BLOCK_ROOT/logs/innovus.log"
    "$TX3_WAIVER_BLOCK_ROOT/logs/innovus.stdout.log"
  )
  for path in \
    "${output_base}.gds" \
    "${output_base}.routed.pg.v" \
    "${output_base}.abstract.lef" \
    "${output_base}.def" \
    "${reports[@]}" \
    "${logs[@]}"
  do
    if [[ ! -s "$path" ]]; then
      echo "STOP_HERE_DO_NOT_CONTINUE: waiver staging input is missing"
      echo "MISSING=$path"
      return 1
    fi
  done

  stage_args=(
    --kind block
    --name spadmic_tx_packet_core
    --version "$TX3_SESSION_ID"
    --source-root "$TX3_WAIVER_BLOCK_ROOT"
    --gds "${output_base}.gds"
    --layout-top spadmic_tx_packet_core
    --netlist "${output_base}.routed.pg.v"
    --source-top spadmic_tx_packet_core
    --lef "${output_base}.abstract.lef"
    --def-file "${output_base}.def"
    --handoff-root "$TX3_HANDOFF_ROOT"
    --repo-root "$TX3_REPO"
    --qualification-profile canonical_tx_lvs_waiver
    --state candidate
  )
  for path in "${reports[@]}"; do
    stage_args+=(--report "$path")
  done
  for path in "${logs[@]}"; do
    stage_args+=(--log "$path")
  done
  stage_report="$TX3_SESSION_ROOT/reports/02_stage_handoff.console.log"
  python3 "$TX3_REPO/TOP/pnr/scripts/stage_innovus_handoff.py" \
    "${stage_args[@]}" \
    >"$stage_report" 2>&1
  stage_rc=$?

  audit_rc=NOT_RUN
  audit_console="$TX3_SESSION_ROOT/reports/02_handoff_audit.console.log"
  if [[ "$stage_rc" -eq 0 && -d "$TX3_PACKAGE" ]]; then
    python3 "$TX3_REPO/TOP/pnr/scripts/audit_innovus_handoff.py" \
      "$TX3_PACKAGE" \
      >"$audit_console" 2>&1
    audit_rc=$?
  fi
  qualification="$TX3_PACKAGE/status/qualification.rpt"
  status=FAIL
  result=PROVISIONAL_PVS_HANDOFF_STAGING_FAILED
  if [[ "$stage_rc" -eq 0 && "$audit_rc" == "0" \
      && "$(kv_field "$qualification" TEMPORARY_DRC_WAIVER_STATUS)" == "PASS" \
      && "$(kv_field "$qualification" PVS_DRC_WAIVER)" == "NO" \
      && "$(kv_field "$qualification" LVS_DIAGNOSTIC_ONLY)" == "YES" \
      && "$(kv_field "$qualification" SIGNOFF_READY)" == "NO" ]]; then
    status=PASS
    result=IMMUTABLE_PROVISIONAL_PVS_PACKAGE_STAGED
  fi
  {
    echo "LABEL=SPADMIC_TX_PACKET_PROVISIONAL_PVS_STAGE_DRIVER"
    echo "STATUS=$status"
    echo "RESULT=$result"
    echo "STAGE_RC=$stage_rc"
    echo "AUDIT_RC=$audit_rc"
    echo "PACKAGE=$TX3_PACKAGE"
    echo "QUALIFICATION_PROFILE=canonical_tx_lvs_waiver"
    echo "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY"
    echo "PVS_DRC_WAIVER=NO"
    echo "LVS_DIAGNOSTIC_ONLY=YES"
    echo "FINAL_SIGNOFF_READY=NO"
  } >"$TX3_SESSION_ROOT/reports/02_stage_handoff_driver.rpt"
  cat "$TX3_SESSION_ROOT/reports/02_stage_handoff_driver.rpt"
  if [[ -r "$qualification" ]]; then
    cat "$qualification"
  fi
  if [[ "$status" != "PASS" ]]; then
    cat "$stage_report" 2>/dev/null
    cat "$audit_console" 2>/dev/null
  fi
  record_status 02_stage_handoff "$status" "$stage_rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

pvs_drc_base() {
  local template template_gds template_top run_id run_dir console pvs_rc
  local raw_status raw_evidence raw_tool_rc replay_status isolation_status
  local status result driver_report
  load_session || return 1
  require_step_pass 02_stage_handoff || return 1
  check_current_head || return 1

  template="${SPADMIC_TX_PACKET_PVS_DRC_TEMPLATE:-$DEFAULT_DRC_TEMPLATE}"
  template_gds="${SPADMIC_TX_PACKET_PVS_DRC_TEMPLATE_GDS:-$template/spadmic_tx_packet_core_HV.gds}"
  template_top="${SPADMIC_TX_PACKET_PVS_DRC_TEMPLATE_TOP:-spadmic_tx_packet_core_HV}"
  run_id="${TX3_SESSION_ID}_pvs_drc_base"
  run_dir="$TX3_PACKAGE/pvs/drc/$run_id"
  console="$TX3_SESSION_ROOT/logs/03_pvs_drc_base.console.log"
  if [[ -e "$run_dir" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable PVS DRC run already exists"
    echo "RUN_DIR=$run_dir"
    return 1
  fi

  echo "COMMAND=bash TOP/pnr/scripts/run_pvs_drc_handoff.sh --package $TX3_PACKAGE --template $template --template-gds $template_gds --template-top $template_top --variant base --run-id $run_id"
  EXPECTED_HEAD="$TX3_EXPECTED_HEAD" \
    bash "$TX3_REPO/TOP/pnr/scripts/run_pvs_drc_handoff.sh" \
      --package "$TX3_PACKAGE" \
      --template "$template" \
      --template-gds "$template_gds" \
      --template-top "$template_top" \
      --variant base \
      --run-id "$run_id" \
      >"$console" 2>&1
  pvs_rc=$?

  raw_status="$(kv_field "$run_dir/pvs_drc_status.rpt" PVS_DRC_STATUS)"
  raw_evidence="$(kv_field "$run_dir/pvs_drc_status.rpt" EVIDENCE)"
  raw_tool_rc="$(kv_field "$run_dir/pvs_drc_status.rpt" PVS_RC)"
  replay_status="$(kv_field "$run_dir/replay_contract_status.rpt" STATUS)"
  isolation_status="$(kv_field "$run_dir/output_isolation.rpt" STATUS)"
  status=FAIL
  result=PVS_BASE_DRC_EXECUTION_OR_CLASSIFICATION_FAILED
  if [[ "$replay_status" == "PASS" && "$isolation_status" == "PASS" \
      && "$raw_tool_rc" == "0" \
      && "$raw_status" == "PASS" ]]; then
    status=PASS
    result=PVS_BASE_DRC_ZERO
  elif [[ "$replay_status" == "PASS" && "$isolation_status" == "PASS" \
      && "$raw_tool_rc" == "0" \
      && "$raw_status" == "FAIL" \
      && "$raw_evidence" == *"Total DRC Results="* ]]; then
    status=PASS
    result=PVS_BASE_DRC_NONZERO_RECORDED_LVS_STILL_AUTHORIZED
  fi
  driver_report="$TX3_SESSION_ROOT/reports/03_pvs_drc_base_driver.rpt"
  {
    echo "LABEL=SPADMIC_TX_PACKET_PROVISIONAL_PVS_DRC"
    echo "STATUS=$status"
    echo "RESULT=$result"
    echo "PVS_WRAPPER_RC=$pvs_rc"
    echo "PVS_TOOL_RC=${raw_tool_rc:-MISSING}"
    echo "PVS_DRC_STATUS=${raw_status:-MISSING}"
    echo "PVS_DRC_EVIDENCE=${raw_evidence:-MISSING}"
    echo "REPLAY_CONTRACT_STATUS=${replay_status:-MISSING}"
    echo "OUTPUT_ISOLATION_STATUS=${isolation_status:-MISSING}"
    echo "RUN_DIR=$run_dir"
    echo "GDS=$TX3_PACKAGE/gds/spadmic_tx_packet_core.gds"
    echo "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY"
    echo "PVS_DRC_WAIVER=NO"
    echo "LVS_PREREQUISITE=NO"
    echo "LVS_EXECUTION_AUTHORIZED=YES_INDEPENDENT_OF_DRC_RESULT"
    echo "MANUAL_DRC_FIX_REQUIRED=YES"
    echo "FINAL_SIGNOFF_READY=NO"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$run_dir/pvs_drc_status.rpt" ]]; then
    cat "$run_dir/pvs_drc_status.rpt"
  fi
  if [[ "$status" != "PASS" && -r "$console" ]]; then
    echo "===== PVS DRC CONSOLE TAIL ====="
    tail -n 360 "$console"
  fi
  record_status 03_pvs_drc_base "$status" "$pvs_rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

pvs_lvs() {
  local template package_gds package_source package_cdl
  local template_gds template_source template_layout_top template_source_top template_cdl
  local run_id run_dir console pvs_rc raw_status raw_evidence replay_status
  local isolation_status status result driver_report
  load_session || return 1
  require_step_pass 02_stage_handoff || return 1
  check_current_head || return 1

  template="${SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE:-}"
  if [[ -z "$template" || ! -d "$template" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: fresh canonical PVS LVS GUI template is required"
    echo "SET=SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE=/absolute/template/directory"
    echo "PACKAGE=$TX3_PACKAGE"
    echo "LAYOUT_GDS=$TX3_PACKAGE/gds/spadmic_tx_packet_core.gds"
    echo "VERILOG_SOURCE=$TX3_PACKAGE/netlist/spadmic_tx_packet_core.lvs.pg.v"
    echo "STDCELL_CDL=$TX3_PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"
    return 1
  fi
  package_gds="$TX3_PACKAGE/gds/spadmic_tx_packet_core.gds"
  package_source="$TX3_PACKAGE/netlist/spadmic_tx_packet_core.lvs.pg.v"
  package_cdl="$TX3_PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"
  template_gds="${SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_GDS:-$package_gds}"
  template_source="${SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_SOURCE:-$package_source}"
  template_layout_top="${SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_LAYOUT_TOP:-spadmic_tx_packet_core}"
  template_source_top="${SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_SOURCE_TOP:-spadmic_tx_packet_core}"
  template_cdl="${SPADMIC_TX_PACKET_PVS_LVS_TEMPLATE_CDL:-$package_cdl}"
  run_id="${TX3_SESSION_ID}_pvs_lvs"
  run_dir="$TX3_PACKAGE/pvs/lvs/$run_id"
  console="$TX3_SESSION_ROOT/logs/04_pvs_lvs.console.log"
  if [[ -e "$run_dir" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable PVS LVS run already exists"
    echo "RUN_DIR=$run_dir"
    return 1
  fi

  echo "COMMAND=bash TOP/pnr/scripts/run_pvs_lvs_handoff.sh --package $TX3_PACKAGE --template $template --template-gds $template_gds --template-source $template_source --template-layout-top $template_layout_top --template-source-top $template_source_top --template-cdl $template_cdl --run-id $run_id"
  EXPECTED_HEAD="$TX3_EXPECTED_HEAD" \
    bash "$TX3_REPO/TOP/pnr/scripts/run_pvs_lvs_handoff.sh" \
      --package "$TX3_PACKAGE" \
      --template "$template" \
      --template-gds "$template_gds" \
      --template-source "$template_source" \
      --template-layout-top "$template_layout_top" \
      --template-source-top "$template_source_top" \
      --template-cdl "$template_cdl" \
      --run-id "$run_id" \
      >"$console" 2>&1
  pvs_rc=$?

  raw_status="$(kv_field "$run_dir/pvs_lvs_status.rpt" PVS_LVS_STATUS)"
  raw_evidence="$(kv_field "$run_dir/pvs_lvs_status.rpt" EVIDENCE)"
  replay_status="$(kv_field "$run_dir/replay_contract_status.rpt" STATUS)"
  isolation_status="$(kv_field "$run_dir/output_isolation.rpt" STATUS)"
  status=FAIL
  result=PVS_LVS_NOT_MATCHED
  if [[ "$pvs_rc" -eq 0 && "$replay_status" == "PASS" \
      && "$isolation_status" == "PASS" \
      && "$raw_status" == "MATCH" ]]; then
    status=PASS
    result=PVS_LVS_EXPLICIT_MATCH
  elif [[ "$raw_status" == "MISMATCH" ]]; then
    result=PVS_LVS_EXPLICIT_MISMATCH
  fi
  driver_report="$TX3_SESSION_ROOT/reports/04_pvs_lvs_driver.rpt"
  {
    echo "LABEL=SPADMIC_TX_PACKET_PROVISIONAL_PVS_LVS"
    echo "STATUS=$status"
    echo "RESULT=$result"
    echo "PVS_WRAPPER_RC=$pvs_rc"
    echo "PVS_LVS_STATUS=${raw_status:-MISSING}"
    echo "PVS_LVS_EVIDENCE=${raw_evidence:-MISSING}"
    echo "REPLAY_CONTRACT_STATUS=${replay_status:-MISSING}"
    echo "OUTPUT_ISOLATION_STATUS=${isolation_status:-MISSING}"
    echo "RUN_DIR=$run_dir"
    echo "LAYOUT_GDS=$package_gds"
    echo "SCHEMATIC_SOURCE=$package_source"
    echo "STDCELL_CDL=$package_cdl"
    echo "PVS_DRC_PREREQUISITE=NOT_REQUIRED"
    echo "LVS_ACCEPTANCE=EXPLICIT_REPORT_LEVEL_MATCH_ONLY"
    echo "WAIVER_SCOPE=EXACT_FOUR_INNOVUS_MET1_MIN_AREA_ONLY"
    echo "PVS_DRC_WAIVER=NO"
    echo "LVS_DIAGNOSTIC_ONLY=YES"
    echo "MANUAL_DRC_FIX_REQUIRED=YES"
    echo "FINAL_SIGNOFF_READY=NO"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$run_dir/pvs_lvs_status.rpt" ]]; then
    cat "$run_dir/pvs_lvs_status.rpt"
  fi
  if [[ "$status" != "PASS" && -r "$console" ]]; then
    echo "===== PVS LVS CONSOLE TAIL ====="
    tail -n 420 "$console"
  fi
  record_status 04_pvs_lvs "$status" "$pvs_rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

summary_report() {
  local drc_status lvs_status status result report
  load_session || return 1
  require_step_pass 02_stage_handoff || return 1
  drc_status="$(kv_field "$TX3_SESSION_ROOT/reports/03_pvs_drc_base_driver.rpt" PVS_DRC_STATUS)"
  lvs_status="$(kv_field "$TX3_SESSION_ROOT/reports/04_pvs_lvs_driver.rpt" PVS_LVS_STATUS)"
  drc_status="${drc_status:-NOT_RUN}"
  lvs_status="${lvs_status:-NOT_RUN}"
  status=FAIL
  result=PROVISIONAL_LVS_OBJECTIVE_NOT_ACHIEVED
  if [[ "$lvs_status" == "MATCH" ]]; then
    status=PASS
    if [[ "$drc_status" == "PASS" ]]; then
      result=PROVISIONAL_LVS_MATCH_ACHIEVED_PVS_DRC_ZERO_WAIVER_RETIREMENT_PENDING
    else
      result=PROVISIONAL_LVS_MATCH_ACHIEVED_DRC_DEBT_OPEN
    fi
  elif [[ "$lvs_status" == "MISMATCH" ]]; then
    result=PROVISIONAL_LVS_EXPLICIT_MISMATCH_REQUIRES_ROOT_CAUSE
  fi
  report="$TX3_SESSION_ROOT/reports/05_provisional_pvs_summary.rpt"
  {
    echo "LABEL=SPADMIC_TX_PACKET_PROVISIONAL_PVS_SUMMARY"
    echo "STATUS=$status"
    echo "RESULT=$result"
    echo "PACKAGE=$TX3_PACKAGE"
    echo "INNOVUS_DRC_STATUS=PASS_WITH_EXACT_TEMPORARY_WAIVER"
    echo "INNOVUS_WAIVED_MARKER_COUNT=4"
    echo "INNOVUS_WAIVED_NETS=n_9677 n_9693 n_9696 n_9697"
    echo "PVS_DRC_STATUS=$drc_status"
    echo "PVS_DRC_WAIVER=NO"
    echo "PVS_LVS_STATUS=$lvs_status"
    echo "LVS_MATCH_OBJECTIVE=$([ "$lvs_status" == "MATCH" ] && echo ACHIEVED || echo NOT_ACHIEVED)"
    echo "LVS_DIAGNOSTIC_ONLY=YES"
    echo "MANUAL_DRC_FIX_REQUIRED=YES"
    echo "WAIVER_RETIREMENT_REQUIRED=YES"
    echo "FINAL_PVS_DRC_RERUN_REQUIRED=YES"
    echo "FINAL_LVS_RERUN_AFTER_MANUAL_FIX_REQUIRED=YES"
    echo "BLOCK_PROMOTION_AUTHORIZED=NO"
    echo "FINAL_SIGNOFF_READY=NO"
  } >"$report"
  cat "$report"
  record_status 05_summary "$status" 0 "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

show_status() {
  load_session || return 1
  echo "ACTIVE_ENV=$ACTIVE_ENV"
  echo "SESSION_ROOT=$TX3_SESSION_ROOT"
  echo "EXPECTED_HEAD=$TX3_EXPECTED_HEAD"
  echo "WAIVER_BLOCK_ROOT=$TX3_WAIVER_BLOCK_ROOT"
  echo "PACKAGE=$TX3_PACKAGE"
  echo
  local report
  for report in "$TX3_SESSION_ROOT"/status/*.rpt; do
    if [[ -r "$report" ]]; then
      echo "===== $(basename "$report") ====="
      cat "$report"
    fi
  done
  return 0
}

COMMAND_RC=0
case "$COMMAND" in
  init)
    init_session "$ARGUMENT_1" "$ARGUMENT_2"
    COMMAND_RC=$?
    ;;
  waiver-export)
    waiver_export
    COMMAND_RC=$?
    ;;
  stage)
    stage_handoff
    COMMAND_RC=$?
    ;;
  pvs-drc-base)
    pvs_drc_base
    COMMAND_RC=$?
    ;;
  pvs-lvs)
    pvs_lvs
    COMMAND_RC=$?
    ;;
  summary)
    summary_report
    COMMAND_RC=$?
    ;;
  status)
    show_status
    COMMAND_RC=$?
    ;;
  help|-h|--help)
    usage
    COMMAND_RC=0
    ;;
  *)
    echo "Unknown subcommand: $COMMAND"
    usage
    COMMAND_RC=2
    ;;
esac

# The driver is a child process, so a nonzero result cannot terminate the
# operator's interactive shell. Preserve pass/fail for explicit RC capture.
if [[ "$COMMAND_RC" -eq 0 ]]; then
  true
else
  false
fi
