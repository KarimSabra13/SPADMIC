#!/usr/bin/env bash
# =============================================================================
# TX packet-core canonical rebuild: staged Innovus feasibility driver.
#
# Each subcommand is an independent child-shell action. The driver never runs
# PVS, never modifies historical OA/GDS/PVS data, and never advances from
# preflight to Innovus or from Innovus to report collection automatically.
# =============================================================================

set +e

WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
ACTIVE_ENV="${SPADMIC_TX_PACKET_PHASE2_ACTIVE_ENV:-$WORK_ROOT/diagnostics/tx_packet_canonical_phase2_active.env}"
REPO_DEFAULT="/home/validmgr/ksabra/2026_SPAD/SPADMIC"
DEFAULT_LAYOUT_AUDIT="TOP/docs/layout_audits/SPADMIC2_20260709_072331"
DEFAULT_STREAM_MAP="/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map"
DEFAULT_STDCELL_GDS="/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds"
COMMAND="${1:-help}"
ARGUMENT_1="${2:-}"
ARGUMENT_2="${3:-}"

usage() {
  cat <<'USAGE'
Usage:
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh init <expected-head> <phase1-session-root>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh sync
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh preflight
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh innovus
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh innovus-report
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh diagnose
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh pg-probe
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh package
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh status

Run one subcommand at a time and inspect its status report before continuing.
This phase runs packet-core Innovus only. PVS remains blocked.
USAGE
}

append_active_assignment() {
  local name="$1"
  local value="$2"
  printf 'export %s=%q\n' "$name" "$value" >> "$ACTIVE_ENV"
}

kv_field() {
  local path="$1"
  local key="$2"
  if [[ -r "$path" ]]; then
    awk -F= -v key="$key" '$1 == key {value = substr($0, index($0, "=") + 1)} END {print value}' "$path"
  fi
}

load_session() {
  if [[ ! -r "$ACTIVE_ENV" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: phase-2 active session file is missing"
    echo "ACTIVE_ENV=$ACTIVE_ENV"
    return 1
  fi

  # shellcheck disable=SC1090
  source "$ACTIVE_ENV"
  local required
  for required in \
    TX2_REPO \
    TX2_WORK_ROOT \
    TX2_EXPECTED_HEAD \
    TX2_SESSION_ID \
    TX2_SESSION_ROOT \
    TX2_PHASE1_ROOT \
    TX2_PHASE1_GATE \
    TX2_GENUS_RUN \
    TX2_GENUS_BLOCK_ROOT \
    TX2_INNOVUS_RUN \
    TX2_INNOVUS_ROOT \
    TX2_BLOCK_ROOT \
    TX2_LAYOUT_AUDIT_DIR \
    TX2_STREAM_MAP \
    TX2_STDCELL_GDS
  do
    if [[ -z "${!required:-}" ]]; then
      echo "STOP_HERE_DO_NOT_CONTINUE: missing $required in $ACTIVE_ENV"
      return 1
    fi
  done

  mkdir -p \
    "$TX2_SESSION_ROOT/logs" \
    "$TX2_SESSION_ROOT/reports" \
    "$TX2_SESSION_ROOT/status" \
    "$TX2_SESSION_ROOT/packages"
  return $?
}

status_field() {
  local step="$1"
  local key="$2"
  kv_field "$TX2_SESSION_ROOT/status/${step}.rpt" "$key"
}

record_status() {
  local step="$1"
  local status="$2"
  local rc="$3"
  local result="$4"
  local report="$TX2_SESSION_ROOT/status/${step}.rpt"
  local utc
  utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  {
    echo "LABEL=SPADMIC_TX_PACKET_CANONICAL_PHASE2"
    echo "STEP=$step"
    echo "DATE_UTC=$utc"
    echo "HEAD_EXPECTED=$TX2_EXPECTED_HEAD"
    echo "STATUS=$status"
    echo "RC=$rc"
    echo "RESULT=$result"
    echo "SESSION_ROOT=$TX2_SESSION_ROOT"
    echo "INNOVUS_ROOT=$TX2_INNOVUS_ROOT"
    echo "POLICY=ONE_OPERATOR_COMMAND_PER_GATE_NO_AUTO_ADVANCE"
  } | tee "$report"

  {
    echo
    echo "[$utc] STEP=$step STATUS=$status RC=$rc RESULT=$result"
    echo "REPORT=$report"
  } >> "$TX2_SESSION_ROOT/execution_journal.rpt"
}

require_step_pass() {
  local required_step="$1"
  local actual
  actual="$(status_field "$required_step" STATUS)"
  if [[ "$actual" != "PASS" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: prerequisite did not pass"
    echo "REQUIRED_STEP=$required_step"
    echo "ACTUAL_STATUS=${actual:-MISSING}"
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

init_session() {
  local expected_head="$1"
  local phase1_root="$2"
  if [[ -z "$expected_head" || -z "$phase1_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: init requires expected HEAD and phase-1 session root"
    usage
    return 1
  fi

  local phase1_gate phase1_status phase1_result genus_block_root genus_run
  phase1_gate="$phase1_root/reports/07_genus_gate.rpt"
  if [[ ! -r "$phase1_gate" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: phase-1 Genus gate is missing"
    echo "PHASE1_GATE=$phase1_gate"
    return 1
  fi
  phase1_status="$(kv_field "$phase1_gate" STATUS)"
  phase1_result="$(kv_field "$phase1_gate" RESULT)"
  genus_block_root="$(kv_field "$phase1_gate" BLOCK_ROOT)"
  if [[ "$phase1_status" != "PASS" || "$phase1_result" != "READY_FOR_PACKET_INNOVUS_FEASIBILITY" || -z "$genus_block_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: phase-1 Genus gate is not accepted"
    echo "PHASE1_STATUS=${phase1_status:-MISSING}"
    echo "PHASE1_RESULT=${phase1_result:-MISSING}"
    echo "GENUS_BLOCK_ROOT=${genus_block_root:-MISSING}"
    return 1
  fi
  genus_run="$(basename "$(dirname "$genus_block_root")")"

  local stamp session_id session_root innovus_run innovus_root block_root mkdir_rc repo
  stamp="$(date +%Y%m%d_%H%M%S)"
  session_id="tx_packet_canonical_phase2_${stamp}"
  session_root="$WORK_ROOT/diagnostics/$session_id"
  innovus_run="innovus_ooc_harden_tx_packet_core_canonical_${stamp}"
  innovus_root="$WORK_ROOT/innovus/$innovus_run"
  block_root="$innovus_root/blocks/tx_packet_core"
  repo="${SPADMIC_TX_REPO:-$REPO_DEFAULT}"
  mkdir -p "$session_root/logs" "$session_root/reports" "$session_root/status" "$session_root/packages"
  mkdir_rc=$?
  if [[ "$mkdir_rc" -ne 0 ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: cannot create phase-2 session root"
    echo "SESSION_ROOT=$session_root"
    return 1
  fi

  mkdir -p "$(dirname "$ACTIVE_ENV")"
  : > "$ACTIVE_ENV"
  append_active_assignment TX2_REPO "$repo"
  append_active_assignment TX2_WORK_ROOT "$WORK_ROOT"
  append_active_assignment TX2_EXPECTED_HEAD "$expected_head"
  append_active_assignment TX2_SESSION_ID "$session_id"
  append_active_assignment TX2_SESSION_ROOT "$session_root"
  append_active_assignment TX2_PHASE1_ROOT "$phase1_root"
  append_active_assignment TX2_PHASE1_GATE "$phase1_gate"
  append_active_assignment TX2_GENUS_RUN "$genus_run"
  append_active_assignment TX2_GENUS_BLOCK_ROOT "$genus_block_root"
  append_active_assignment TX2_INNOVUS_RUN "$innovus_run"
  append_active_assignment TX2_INNOVUS_ROOT "$innovus_root"
  append_active_assignment TX2_BLOCK_ROOT "$block_root"
  append_active_assignment TX2_LAYOUT_AUDIT_DIR "$repo/$DEFAULT_LAYOUT_AUDIT"
  append_active_assignment TX2_STREAM_MAP "${SPADMIC_STREAMOUT_MAP_FILE:-$DEFAULT_STREAM_MAP}"
  append_active_assignment TX2_STDCELL_GDS "${SPADMIC_STDCELL_GDS:-$DEFAULT_STDCELL_GDS}"

  load_session
  local load_rc=$?
  if [[ "$load_rc" -ne 0 ]]; then
    return 1
  fi

  {
    echo "LABEL=SPADMIC_TX_PACKET_CANONICAL_PHASE2_OBJECTIVE"
    echo "CURRENT_SCOPE=P03_SERVER_GATE_2_PACKET_INNOVUS_FEASIBILITY"
    echo "CANONICAL_TOP=spadmic_tx_packet_core"
    echo "SOURCE_PHASE1_ROOT=$TX2_PHASE1_ROOT"
    echo "SOURCE_GENUS_GATE=$TX2_PHASE1_GATE"
    echo "SOURCE_GENUS_RUN=$TX2_GENUS_RUN"
    echo "INNOVUS_RUN=$TX2_INNOVUS_RUN"
    echo "SIGNAL_ROUTE_POLICY=MET1_TO_MET3"
    echo "PG_POLICY=EXPLICIT_EXACT_METTP_STRIPES_COREPIN_SROUTE"
    echo "ANTENNA_POLICY=DEFER_REPAIR_BUT_BLOCK_FINAL_HANDOFF"
    echo "REQUIRED_GATES=PG_REGULAR_CONNECTIVITY_DRC_SETUP_HOLD_GDS_PIN_CONTRACT"
    echo "PVS_POLICY=NOT_RUN_IN_THIS_PHASE"
    echo "FINAL_HANDOFF_READY=NO"
  } | tee "$TX2_SESSION_ROOT/00_objective_and_policy.rpt"

  {
    echo "SPADMIC TX packet canonical phase-2 execution journal"
    echo "SESSION_ID=$TX2_SESSION_ID"
    echo "SESSION_ROOT=$TX2_SESSION_ROOT"
    echo "EXPECTED_HEAD=$TX2_EXPECTED_HEAD"
    echo "ACTIVE_ENV=$ACTIVE_ENV"
  } > "$TX2_SESSION_ROOT/execution_journal.rpt"

  record_status 00_init PASS 0 SESSION_INITIALIZED
  echo "ACTIVE_ENV=$ACTIVE_ENV"
  echo "SESSION_ROOT=$TX2_SESSION_ROOT"
  echo "INNOVUS_RUN=$TX2_INNOVUS_RUN"
  echo "INNOVUS_ROOT=$TX2_INNOVUS_ROOT"
  return 0
}

sync_repo() {
  load_session || return 1
  local cd_rc checkout_rc pull_rc actual_head status
  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  checkout_rc=NOT_RUN
  pull_rc=NOT_RUN
  actual_head=UNKNOWN
  status=FAIL

  if [[ "$cd_rc" -eq 0 ]]; then
    git checkout SPADMIC_test 2>&1 | tee "$TX2_SESSION_ROOT/logs/01_git_checkout.log"
    checkout_rc=${PIPESTATUS[0]}
  fi
  if [[ "$checkout_rc" == "0" ]]; then
    git pull --ff-only origin SPADMIC_test 2>&1 | tee "$TX2_SESSION_ROOT/logs/01_git_pull.log"
    pull_rc=${PIPESTATUS[0]}
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
    git status --short --branch | tee "$TX2_SESSION_ROOT/reports/01_git_status.rpt"
  fi
  if [[ "$cd_rc" -eq 0 && "$checkout_rc" == "0" && "$pull_rc" == "0" && "$actual_head" == "$TX2_EXPECTED_HEAD" ]]; then
    status=PASS
  fi

  {
    echo "CD_RC=$cd_rc"
    echo "CHECKOUT_RC=$checkout_rc"
    echo "PULL_RC=$pull_rc"
    echo "EXPECTED_HEAD=$TX2_EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$actual_head"
    echo "DIRTY_TREE_POLICY=RECORD_ONLY_DO_NOT_TOUCH_UNRELATED_FILES"
  } | tee "$TX2_SESSION_ROOT/reports/01_sync_details.rpt"
  record_status 01_sync "$status" "$pull_rc" REPOSITORY_HEAD_CHECKED
  [[ "$status" == "PASS" ]]
  return $?
}

preflight() {
  load_session || return 1
  require_step_pass 01_sync || return 1
  cd "$TX2_REPO" 2>/dev/null
  local cd_rc=$?
  local cadence_rc=NOT_RUN plan_rc=NOT_RUN status=FAIL
  local actual_head=UNKNOWN phase1_status phase1_result phase1_errors
  local phase1_innovus_ready phase1_signoff_ready phase1_mmmc_status
  local netlist sdc expected_netlist_sha expected_sdc_sha actual_netlist_sha actual_sdc_sha
  local input_status=FAIL hash_status=FAIL tool_status=FAIL plan_status=FAIL run_root_status=FAIL
  local config_sha=MISSING
  local plan_root="$TX2_SESSION_ROOT/reports/02_generated_plan"
  netlist="$TX2_GENUS_BLOCK_ROOT/outputs/tx_packet_core.postsyn.v"
  sdc="$TX2_GENUS_BLOCK_ROOT/outputs/tx_packet_core.postsyn.sdc"

  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
    load_cadence
    cadence_rc=$?
  fi
  phase1_status="$(kv_field "$TX2_PHASE1_GATE" STATUS)"
  phase1_result="$(kv_field "$TX2_PHASE1_GATE" RESULT)"
  phase1_errors="$(kv_field "$TX2_PHASE1_GATE" ERROR_COUNT)"
  phase1_innovus_ready="$(kv_field "$TX2_PHASE1_GATE" INNOVUS_FEASIBILITY_READY)"
  phase1_signoff_ready="$(kv_field "$TX2_PHASE1_GATE" SIGNOFF_READY)"
  phase1_mmmc_status="$(kv_field "$TX2_PHASE1_GATE" MMMC_STATUS)"
  expected_netlist_sha="$(kv_field "$TX2_PHASE1_GATE" POSTSYN_NETLIST_SHA256)"
  expected_sdc_sha="$(kv_field "$TX2_PHASE1_GATE" POSTSYN_SDC_SHA256)"

  if [[ -s "$netlist" && -s "$sdc" && -s "$TX2_STREAM_MAP" && -s "$TX2_STDCELL_GDS" && -d "$TX2_LAYOUT_AUDIT_DIR" ]]; then
    input_status=PASS
    actual_netlist_sha="$(sha256sum "$netlist" | awk '{print $1}')"
    actual_sdc_sha="$(sha256sum "$sdc" | awk '{print $1}')"
  else
    actual_netlist_sha=MISSING
    actual_sdc_sha=MISSING
  fi
  if [[ "$actual_netlist_sha" == "$expected_netlist_sha" && "$actual_sdc_sha" == "$expected_sdc_sha" ]]; then
    hash_status=PASS
  fi
  if [[ "$cadence_rc" == "0" ]] && command -v innovus >/dev/null 2>&1; then
    tool_status=PASS
  fi
  if [[ ! -e "$TX2_INNOVUS_ROOT" ]]; then
    run_root_status=PASS
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    python3 TOP/pnr/scripts/gen_ooc_block_harden_plan.py tx_packet_core \
      --layout-audit-dir "$TX2_LAYOUT_AUDIT_DIR" \
      --out-dir "$plan_root" \
      > "$TX2_SESSION_ROOT/logs/02_plan.stdout.log" 2>&1
    plan_rc=$?
  fi
  local config="$plan_root/ooc_block_harden_config.tcl"
  if [[ -s "$config" ]]; then
    config_sha="$(sha256sum "$config" | awk '{print $1}')"
  fi
  if [[ "$plan_rc" == "0" && -s "$config" ]] \
      && grep -q 'variable pg_route_strategy {explicit_exact}' "$config" \
      && grep -q 'variable enable_pg_sroute {1}' "$config" \
      && grep -q 'variable route_profile {met1_effort}' "$config" \
      && grep -q 'variable signal_bottom_layer {MET1}' "$config" \
      && grep -q 'variable signal_top_layer {MET3}' "$config" \
      && grep -q 'variable power_layer {METTP}' "$config" \
      && grep -q 'variable core_width_um {2046.969}' "$config" \
      && grep -q 'variable core_height_um {346.486}' "$config" \
      && grep -q 'variable antenna_milestone_policy {DEFER_MANUAL_REPAIR_FINAL_HANDOFF_BLOCKED}' "$config"; then
    plan_status=PASS
  fi

  if [[ "$cd_rc" -eq 0 \
      && "$actual_head" == "$TX2_EXPECTED_HEAD" \
      && "$phase1_status" == "PASS" \
      && "$phase1_result" == "READY_FOR_PACKET_INNOVUS_FEASIBILITY" \
      && "$phase1_errors" == "0" \
      && "$phase1_innovus_ready" == "YES" \
      && "$phase1_signoff_ready" == "NO" \
      && "$phase1_mmmc_status" == "NOT_RUN_TYPICAL_ONLY" \
      && "$input_status" == "PASS" \
      && "$hash_status" == "PASS" \
      && "$tool_status" == "PASS" \
      && "$plan_status" == "PASS" \
      && "$run_root_status" == "PASS" ]]; then
    status=PASS
  fi

  {
    echo "LABEL=SPADMIC_TX_PACKET_INNOVUS_PREFLIGHT"
    echo "STATUS=$status"
    echo "EXPECTED_HEAD=$TX2_EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$actual_head"
    echo "PHASE1_GATE_STATUS=$phase1_status"
    echo "PHASE1_GATE_RESULT=$phase1_result"
    echo "PHASE1_GATE_ERROR_COUNT=$phase1_errors"
    echo "PHASE1_INNOVUS_FEASIBILITY_READY=$phase1_innovus_ready"
    echo "PHASE1_SIGNOFF_READY=$phase1_signoff_ready"
    echo "PHASE1_MMMC_STATUS=$phase1_mmmc_status"
    echo "GENUS_RUN=$TX2_GENUS_RUN"
    echo "GENUS_BLOCK_ROOT=$TX2_GENUS_BLOCK_ROOT"
    echo "NETLIST=$netlist"
    echo "NETLIST_SHA256_EXPECTED=$expected_netlist_sha"
    echo "NETLIST_SHA256_ACTUAL=$actual_netlist_sha"
    echo "SDC=$sdc"
    echo "SDC_SHA256_EXPECTED=$expected_sdc_sha"
    echo "SDC_SHA256_ACTUAL=$actual_sdc_sha"
    echo "INPUT_STATUS=$input_status"
    echo "HASH_STATUS=$hash_status"
    echo "CADENCE_RC=$cadence_rc"
    echo "TOOL_STATUS=$tool_status"
    echo "PLAN_RC=$plan_rc"
    echo "PLAN_STATUS=$plan_status"
    echo "GENERATED_CONFIG=$config"
    echo "GENERATED_CONFIG_SHA256=$config_sha"
    echo "LAYOUT_AUDIT_DIR=$TX2_LAYOUT_AUDIT_DIR"
    echo "STREAM_MAP=$TX2_STREAM_MAP"
    echo "STDCELL_GDS=$TX2_STDCELL_GDS"
    echo "INNOVUS_RUN=$TX2_INNOVUS_RUN"
    echo "INNOVUS_ROOT=$TX2_INNOVUS_ROOT"
    echo "RUN_ROOT_UNUSED_STATUS=$run_root_status"
    echo "SIGNAL_ROUTE_POLICY=MET1_TO_MET3"
    echo "PG_POLICY=EXPLICIT_EXACT_COREPIN_SROUTE"
    echo "ANTENNA_POLICY=DEFERRED_FINAL_HANDOFF_BLOCKED"
    echo "PVS_STATUS=NOT_RUN"
  } | tee "$TX2_SESSION_ROOT/reports/02_innovus_preflight.rpt"
  record_status 02_preflight "$status" "$plan_rc" INNOVUS_INPUT_AND_POLICY_PREFLIGHT_COMPLETE
  [[ "$status" == "PASS" ]]
  return $?
}

run_innovus() {
  load_session || return 1
  require_step_pass 02_preflight || return 1
  cd "$TX2_REPO" 2>/dev/null
  local cd_rc=$?
  local cadence_rc=NOT_RUN wrapper_rc=NOT_RUN status=FAIL result=INNOVUS_NOT_RUN
  local actual_head=UNKNOWN gate_status=MISSING gate_result=MISSING

  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
    load_cadence
    cadence_rc=$?
  fi
  if [[ "$cadence_rc" == "0" && "$actual_head" == "$TX2_EXPECTED_HEAD" && ! -e "$TX2_INNOVUS_ROOT" ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    export SPADMIC_LAYOUT_AUDIT_DIR="$TX2_LAYOUT_AUDIT_DIR"
    export SPADMIC_STREAMOUT_MAP_FILE="$TX2_STREAM_MAP"
    export SPADMIC_STDCELL_GDS="$TX2_STDCELL_GDS"
    export MPTDC_XH018_STACK=xx31
    export MPTDC_STDCELL_FAMILY=JIHD
    export MPTDC_PNR_ROUTE_LAYER_NAMES="MET1 MET2 MET3 METTP"
    export MPTDC_PNR_SIGNAL_TOP_LAYER=MET3
    export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER=METTP
    export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
    export SPADMIC_OOC_ROUTE_PROFILE=met1_effort
    export SPADMIC_OOC_SIGNAL_BOTTOM_LAYER=MET1
    export SPADMIC_OOC_SIGNAL_TOP_LAYER=MET3
    export SPADMIC_OOC_SIGNAL_BOTTOM_LAYER_IDX=1
    export SPADMIC_OOC_SIGNAL_TOP_LAYER_IDX=3
    export SPADMIC_OOC_CORE_WIDTH_UM=2046.969
    export SPADMIC_OOC_CORE_HEIGHT_UM=346.486
    export SPADMIC_OOC_PLACE_MAX_DENSITY=0.64
    export SPADMIC_OOC_ENABLE_ROUTE_EFFORT=1
    export SPADMIC_OOC_ENABLE_PG_SROUTE=1
    export SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR=1
    export SPADMIC_OOC_ENABLE_ANTENNA_REPAIR=0
    export SPADMIC_OOC_REQUIRE_ANTENNA_CLEAN=0
    export SPADMIC_OOC_IGNORE_UNDEFINED_SCAN=1
    export SPADMIC_OOC_ALLOW_SCAN_REORDER=0
    export SPADMIC_OOC_FILLER_ADD_FILLERS_WITH_DRC=0
    export SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER=1
    export SPADMIC_TX_ALLOW_ANTENNA_DEFERRED=1
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh tx_packet_core $TX2_GENUS_RUN $TX2_INNOVUS_RUN"
    bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh \
      tx_packet_core \
      "$TX2_GENUS_RUN" \
      "$TX2_INNOVUS_RUN" \
      2>&1 | tee "$TX2_SESSION_ROOT/logs/03_innovus_driver.console.log"
    wrapper_rc=${PIPESTATUS[0]}
  fi

  local canonical_gate="$TX2_BLOCK_ROOT/reports/canonical_tx_ooc_gate.rpt"
  gate_status="$(kv_field "$canonical_gate" STATUS)"
  gate_result="$(kv_field "$canonical_gate" RESULT)"
  if [[ "$wrapper_rc" == "0" && "$gate_status" == "PASS" && "$gate_result" == "READY_FOR_PVS_CANDIDATE" ]]; then
    status=PASS
    result=INNOVUS_FEASIBILITY_AND_CANONICAL_GATE_PASS
  else
    result=INNOVUS_REVIEW_REQUIRED
  fi

  {
    echo "WRAPPER_RC=$wrapper_rc"
    echo "CANONICAL_GATE=$canonical_gate"
    echo "CANONICAL_GATE_STATUS=$gate_status"
    echo "CANONICAL_GATE_RESULT=$gate_result"
    echo "INNOVUS_ROOT=$TX2_INNOVUS_ROOT"
    echo "BLOCK_ROOT=$TX2_BLOCK_ROOT"
  } | tee "$TX2_SESSION_ROOT/reports/03_innovus_driver_result.rpt"
  record_status 03_innovus "$status" "$wrapper_rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

innovus_report() {
  load_session || return 1
  local source_step_status status result
  local ooc_status="$TX2_BLOCK_ROOT/reports/ooc_harden_status.rpt"
  local canonical_gate="$TX2_BLOCK_ROOT/reports/canonical_tx_ooc_gate.rpt"
  local gds_audit="$TX2_BLOCK_ROOT/reports/gds_export_audit.rpt"
  local marker_class="$TX2_BLOCK_ROOT/reports/DRC_MARKER_CLASSIFICATION.rpt"
  local regular_conn="$TX2_BLOCK_ROOT/reports/verify_connectivity_regular.rpt"
  local pg_conn="$TX2_BLOCK_ROOT/reports/verify_connectivity_pg.rpt"
  local review="$TX2_SESSION_ROOT/reports/04_innovus_review.rpt"
  source_step_status="$(status_field 03_innovus STATUS)"
  status=FAIL
  result=INNOVUS_EVIDENCE_REVIEW_REQUIRED
  if [[ "$source_step_status" == "PASS" \
      && "$(kv_field "$canonical_gate" STATUS)" == "PASS" \
      && "$(kv_field "$canonical_gate" RESULT)" == "READY_FOR_PVS_CANDIDATE" ]]; then
    status=PASS
    result=READY_FOR_PACKET_PVS_PREFLIGHT
  fi

  {
    echo "LABEL=SPADMIC_TX_PACKET_INNOVUS_REVIEW"
    echo "STATUS=$status"
    echo "RESULT=$result"
    echo "SOURCE_STEP_STATUS=${source_step_status:-MISSING}"
    echo "INNOVUS_ROOT=$TX2_INNOVUS_ROOT"
    echo "BLOCK_ROOT=$TX2_BLOCK_ROOT"
    echo "OOC_RESULT=$(kv_field "$ooc_status" RESULT)"
    echo "INNOVUS_DRC_STATUS=$(kv_field "$ooc_status" INNOVUS_DRC_STATUS)"
    echo "DRC_MARKER_TOTAL=$(kv_field "$ooc_status" DRC_MARKER_TOTAL)"
    echo "ANTENNA_MARKER_COUNT=$(kv_field "$ooc_status" ANTENNA_MARKER_COUNT)"
    echo "ANTENNA_MARKER_STATUS=$(kv_field "$ooc_status" ANTENNA_MARKER_STATUS)"
    echo "REGULAR_CONNECTIVITY_STATUS=$(kv_field "$ooc_status" REGULAR_CONNECTIVITY_STATUS)"
    echo "PG_CONNECTIVITY_STATUS=$(kv_field "$ooc_status" PG_CONNECTIVITY_STATUS)"
    echo "SETUP_WNS_NS=$(kv_field "$canonical_gate" SETUP_WNS_NS)"
    echo "SETUP_TNS_NS=$(kv_field "$canonical_gate" SETUP_TNS_NS)"
    echo "SETUP_VIOLATING_PATH_COUNT=$(kv_field "$canonical_gate" SETUP_VIOLATING_PATH_COUNT)"
    echo "SETUP_TIMING_SUMMARY=$(kv_field "$canonical_gate" SETUP_TIMING_SUMMARY)"
    echo "SETUP_TIMING_SHA256=$(kv_field "$canonical_gate" SETUP_TIMING_SHA256)"
    echo "HOLD_WNS_NS=$(kv_field "$canonical_gate" HOLD_WNS_NS)"
    echo "HOLD_TNS_NS=$(kv_field "$canonical_gate" HOLD_TNS_NS)"
    echo "HOLD_VIOLATING_PATH_COUNT=$(kv_field "$canonical_gate" HOLD_VIOLATING_PATH_COUNT)"
    echo "HOLD_TIMING_SUMMARY=$(kv_field "$canonical_gate" HOLD_TIMING_SUMMARY)"
    echo "HOLD_TIMING_SHA256=$(kv_field "$canonical_gate" HOLD_TIMING_SHA256)"
    echo "POST_REPAIR_TIMING_REQUIRED=$(kv_field "$canonical_gate" POST_REPAIR_TIMING_REQUIRED)"
    echo "ANTENNA_MILESTONE_ACCEPTED=$(kv_field "$marker_class" ANTENNA_MILESTONE_ACCEPTED)"
    echo "GDS_AUDIT_STATUS=$(kv_field "$gds_audit" STATUS)"
    echo "CANONICAL_GATE_STATUS=$(kv_field "$canonical_gate" STATUS)"
    echo "CANONICAL_GATE_RESULT=$(kv_field "$canonical_gate" RESULT)"
    echo "CANONICAL_GATE_ERROR_COUNT=$(kv_field "$canonical_gate" ERROR_COUNT)"
    echo "PVS_STATUS=NOT_RUN"
    echo "FINAL_HANDOFF_READY=NO"
    echo "OUTPUT_HASHES_BEGIN"
    if [[ -d "$TX2_BLOCK_ROOT/outputs" ]]; then
      find "$TX2_BLOCK_ROOT/outputs" -maxdepth 1 -type f -print0 2>/dev/null \
        | sort -z \
        | xargs -0 -r sha256sum 2>/dev/null
    fi
    echo "OUTPUT_HASHES_END"
  } | tee "$review"

  local path
  for path in "$ooc_status" "$canonical_gate" "$gds_audit" "$marker_class"; do
    echo
    echo "===== $(basename "$path") ====="
    if [[ -r "$path" ]]; then
      sed -n '1,240p' "$path"
      cp -p "$path" "$TX2_SESSION_ROOT/reports/04_$(basename "$path")"
    else
      echo "MISSING=$path"
    fi
  done
  for path in "$regular_conn" "$pg_conn"; do
    if [[ -r "$path" ]]; then
      cp -p "$path" "$TX2_SESSION_ROOT/reports/04_$(basename "$path")"
    fi
  done

  record_status 04_innovus_report "$status" 0 "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

diagnose_existing() {
  load_session || return 1
  local analyzer report console raw_dir rc status result path
  analyzer="$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_ooc_failure.py"
  report="$TX2_SESSION_ROOT/reports/04_innovus_failure_diagnosis.rpt"
  console="$TX2_SESSION_ROOT/logs/04_innovus_failure_diagnosis.console.log"
  raw_dir="$TX2_SESSION_ROOT/reports/04_failure_inputs"
  rc=8
  status=FAIL
  result=FAILURE_DIAGNOSTIC_INCOMPLETE

  mkdir -p "$raw_dir"
  if [[ ! -r "$analyzer" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: failure analyzer is missing"
    echo "ANALYZER=$analyzer"
  elif [[ ! -d "$TX2_BLOCK_ROOT" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: completed Innovus block root is missing"
    echo "BLOCK_ROOT=$TX2_BLOCK_ROOT"
  else
    python3 "$analyzer" \
      --block-root "$TX2_BLOCK_ROOT" \
      --report "$report" \
      >"$console" 2>&1
    rc=$?
  fi

  for path in \
    "$TX2_BLOCK_ROOT/reports/ooc_harden_status.rpt" \
    "$TX2_BLOCK_ROOT/reports/canonical_tx_ooc_gate.rpt" \
    "$TX2_BLOCK_ROOT/reports/SROUTE_PG.rpt" \
    "$TX2_BLOCK_ROOT/reports/verify_connectivity_pg.rpt" \
    "$TX2_BLOCK_ROOT/reports/POSTROUTE_MIN_AREA_REPAIR.rpt" \
    "$TX2_BLOCK_ROOT/reports/postroute_min_area_repair_pre_markers.tsv" \
    "$TX2_BLOCK_ROOT/reports/postroute_min_area_repair_post_markers.tsv" \
    "$TX2_BLOCK_ROOT/reports/verify_drc_post_route_markers.tsv" \
    "$TX2_BLOCK_ROOT/generated/ooc_block_harden_config.tcl" \
    "$TX2_BLOCK_ROOT/generated/ooc_block_pin_plan.csv" \
    "$TX2_BLOCK_ROOT/generated/ooc_block_pin_assignments.tcl"
  do
    if [[ -r "$path" ]]; then
      cp -p "$path" "$raw_dir/$(basename "$path")"
    fi
  done

  if [[ "$rc" -eq 0 && "$(kv_field "$report" DIAGNOSIS_STATUS)" == "PASS" ]]; then
    status=PASS
    result=BLOCKERS_CLASSIFIED_NO_DESIGN_MODIFICATION
  fi
  if [[ -r "$report" ]]; then
    cat "$report"
  elif [[ -r "$console" ]]; then
    cat "$console"
  fi
  record_status 04_innovus_diagnose "$status" "$rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

pg_probe() {
  load_session || return 1
  require_step_pass 04_innovus_diagnose || return 1
  local cadence_rc probe_id probe_root console rc probe_status status result copy_dir path
  cadence_rc=1
  probe_id="${TX2_SESSION_ID}_pg_probe"
  probe_root="$TX2_WORK_ROOT/diagnostics/$probe_id"
  console="$TX2_SESSION_ROOT/logs/05_pg_probe.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/05_pg_probe"
  rc=8
  status=FAIL
  result=PG_TOPOLOGY_PROBE_INCOMPLETE

  load_cadence
  cadence_rc=$?
  if [[ "$cadence_rc" -eq 0 ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_pg_probe.sh $TX2_BLOCK_ROOT $probe_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_pg_probe.sh" \
      "$TX2_BLOCK_ROOT" \
      "$probe_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    rc=$?
  fi

  probe_status="$probe_root/reports/pg_probe_status.rpt"
  if [[ "$rc" -eq 0 \
      && "$(kv_field "$probe_status" STATUS)" == "PASS" \
      && "$(kv_field "$probe_status" DESIGN_MODIFICATION)" == "NOT_RUN" ]]; then
    status=PASS
    result=PG_TOPOLOGY_DIAGNOSTIC_CAPTURED_READ_ONLY
  fi

  mkdir -p "$copy_dir"
  for path in \
    "$probe_root/context.rpt" \
    "$probe_root/reports/pg_probe_status.rpt" \
    "$probe_root/reports/verify_connectivity_special_detail.rpt" \
    "$probe_root/reports/verify_connectivity_special_console.rpt" \
    "$probe_root/reports/pg_topology.rpt" \
    "$probe_root/reports/pg_connectivity_markers.tsv"
  do
    if [[ -r "$path" ]]; then
      cp -p "$path" "$copy_dir/$(basename "$path")"
    fi
  done

  echo "PG_PROBE_RC=$rc"
  echo "PG_PROBE_ROOT=$probe_root"
  echo "CADENCE_RC=$cadence_rc"
  if [[ -r "$probe_status" ]]; then
    cat "$probe_status"
  elif [[ -r "$console" ]]; then
    sed -n '1,240p' "$console"
  fi
  if [[ -r "$probe_root/reports/verify_connectivity_special_detail.rpt" ]]; then
    echo
    echo "===== SPECIAL CONNECTIVITY DETAIL ====="
    cat "$probe_root/reports/verify_connectivity_special_detail.rpt"
  fi
  if [[ -r "$probe_root/reports/pg_connectivity_markers.tsv" ]]; then
    echo
    echo "===== PG CONNECTIVITY MARKERS ====="
    cat "$probe_root/reports/pg_connectivity_markers.tsv"
  fi
  if [[ -r "$probe_root/reports/pg_topology.rpt" ]]; then
    echo
    echo "===== PG TOPOLOGY SUMMARY ====="
    grep -E '^(LABEL|TOP_NAME|DIE_BOX|CORE_BOX|PG_TERM_|VDD_PG_TERM|VSS_PG_TERM|VDD_SWIRE_COUNT|VSS_SWIRE_COUNT)' \
      "$probe_root/reports/pg_topology.rpt"
  fi
  record_status 05_pg_probe "$status" "$rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

package_evidence() {
  load_session || return 1
  local package="$TX2_SESSION_ROOT/packages/${TX2_SESSION_ID}_text_evidence.tar.gz"
  tar -czf "$package" \
    --exclude='status/06_package.rpt' \
    --exclude='reports/06_package_details.rpt' \
    -C "$TX2_SESSION_ROOT" \
    00_objective_and_policy.rpt \
    execution_journal.rpt \
    status \
    reports
  local tar_rc=$?
  local status=FAIL
  if [[ "$tar_rc" -eq 0 && -s "$package" ]]; then
    status=PASS
  fi
  {
    echo "PACKAGE=$package"
    echo "TAR_RC=$tar_rc"
    if [[ -s "$package" ]]; then
      stat -c 'PACKAGE_BYTES=%s' "$package"
      sha256sum "$package"
    fi
  } | tee "$TX2_SESSION_ROOT/reports/06_package_details.rpt"
  record_status 06_package "$status" "$tar_rc" TEXT_ONLY_EVIDENCE_PACKAGE_COMPLETE
  [[ "$status" == "PASS" ]]
  return $?
}

show_status() {
  load_session || return 1
  echo "ACTIVE_ENV=$ACTIVE_ENV"
  echo "SESSION_ROOT=$TX2_SESSION_ROOT"
  echo "EXPECTED_HEAD=$TX2_EXPECTED_HEAD"
  echo "INNOVUS_ROOT=$TX2_INNOVUS_ROOT"
  echo
  local report
  for report in "$TX2_SESSION_ROOT"/status/*.rpt; do
    if [[ -r "$report" ]]; then
      echo "===== $(basename "$report") ====="
      cat "$report"
    fi
  done
  return 0
}

case "$COMMAND" in
  init)
    init_session "$ARGUMENT_1" "$ARGUMENT_2"
    ;;
  sync)
    sync_repo
    ;;
  preflight)
    preflight
    ;;
  innovus)
    run_innovus
    ;;
  innovus-report)
    innovus_report
    ;;
  diagnose)
    diagnose_existing
    ;;
  pg-probe)
    pg_probe
    ;;
  package)
    package_evidence
    ;;
  status)
    show_status
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "Unknown subcommand: $COMMAND"
    usage
    ;;
esac

# Status files, rather than the child-shell return code, control advancement.
:
