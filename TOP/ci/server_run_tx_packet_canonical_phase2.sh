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
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh pg-analyze
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh pg-help
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh pg-via-trial <via-only|patch-stack>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh pg-via-drc-probe
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh pg-via-1x1-trial
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh preroute-pg-rerun <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh preroute-pg-postfiller-rerun <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh postfiller-stage-probe <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh postcts-via1-analyze <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh preroute-pg-no-restitch-rerun <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh final-closure-analyze <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh min-area-second-pass-trial-r2 <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh min-area-geometry-probe <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh min-area-landing-patch-trial <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh min-area-landing-patch-trial-r2 <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh min-area-landing-patch-trial-r3 <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh min-area-landing-patch-trial-r4 <expected-report-driver-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase2.sh min-area-landing-materialization-probe <expected-report-driver-head>
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

normalized_marker_signature_sha256() {
  local path="$1"
  local net_pattern="${2:-}"
  if [[ ! -r "$path" ]]; then
    return 1
  fi
  awk -F'\t' -v net_pattern="$net_pattern" \
    'NR > 1 && (net_pattern == "" || $13 ~ ("Net (" net_pattern ") ")) {
      print $3 "\t" $10 "\t" $11 "\t" $12 "\t" $13
    }' "$path" \
    | LC_ALL=C sort \
    | sha256sum \
    | awk '{print $1}'
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
  local innovus_root="${5:-$TX2_INNOVUS_ROOT}"
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
    echo "INNOVUS_ROOT=$innovus_root"
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

pg_analyze() {
  load_session || return 1
  require_step_pass 05_pg_probe || return 1
  local probe_root analyzer report console rc status result
  probe_root="$TX2_WORK_ROOT/diagnostics/${TX2_SESSION_ID}_pg_probe"
  analyzer="$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_pg_probe.py"
  report="$TX2_SESSION_ROOT/reports/06_pg_topology_analysis.rpt"
  console="$TX2_SESSION_ROOT/logs/06_pg_topology_analysis.console.log"
  rc=8
  status=FAIL
  result=PG_TOPOLOGY_ANALYSIS_INCOMPLETE

  if [[ ! -r "$analyzer" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: PG topology analyzer is missing"
    echo "ANALYZER=$analyzer"
  elif [[ ! -d "$probe_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: PG probe root is missing"
    echo "PROBE_ROOT=$probe_root"
  else
    python3 "$analyzer" \
      --probe-root "$probe_root" \
      --report "$report" \
      >"$console" 2>&1
    rc=$?
  fi

  if [[ -r "$report" ]]; then
    {
      echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
      echo "REPORT_DRIVER_HEAD=$(git -C "$TX2_REPO" rev-parse HEAD 2>/dev/null)"
    } >> "$report"
  fi

  if [[ "$rc" -eq 0 && "$(kv_field "$report" STATUS)" == "PASS" ]]; then
    status=PASS
    result=PG_TOPOLOGY_CLASSIFIED_NO_DESIGN_MODIFICATION
  fi
  if [[ -r "$report" ]]; then
    cat "$report"
  elif [[ -r "$console" ]]; then
    cat "$console"
  fi
  record_status 06_pg_analyze "$status" "$rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

pg_help() {
  load_session || return 1
  require_step_pass 06_pg_analyze || return 1
  local cadence_rc help_id help_root console rc help_status status result copy_dir path
  help_id="${TX2_SESSION_ID}_pg_repair_help"
  help_root="$TX2_WORK_ROOT/diagnostics/$help_id"
  console="$TX2_SESSION_ROOT/logs/07_pg_command_help.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/07_pg_command_help"
  rc=8
  status=FAIL
  result=PG_REPAIR_COMMAND_HELP_INCOMPLETE

  load_cadence
  cadence_rc=$?
  if [[ "$cadence_rc" -eq 0 ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    echo "COMMAND=bash TOP/pnr/scripts/run_capture_innovus_pg_command_help.sh $help_id"
    bash "$TX2_REPO/TOP/pnr/scripts/run_capture_innovus_pg_command_help.sh" "$help_id" \
      >"$console" 2>&1
    rc=$?
  fi

  help_status="$help_root/reports/command_help_status.rpt"
  if [[ "$rc" -eq 0 \
      && "$(kv_field "$help_status" STATUS)" == "PASS" \
      && "$(kv_field "$help_status" COMMAND_editPowerVia)" != "UNAVAILABLE" \
      && -n "$(kv_field "$help_status" COMMAND_editPowerVia)" ]]; then
    status=PASS
    result=EDIT_POWER_VIA_HELP_CAPTURED_NO_DESIGN_LOADED
  fi

  mkdir -p "$copy_dir"
  if [[ -d "$help_root/reports" ]]; then
    for path in "$help_root"/reports/*.rpt; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi
  echo "PG_COMMAND_HELP_RC=$rc"
  echo "PG_COMMAND_HELP_ROOT=$help_root"
  if [[ -r "$help_status" ]]; then
    cat "$help_status"
  elif [[ -r "$console" ]]; then
    sed -n '1,200p' "$console"
  fi
  record_status 07_pg_help "$status" "$rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

pg_via_trial() {
  load_session || return 1
  require_step_pass 06_pg_analyze || return 1
  require_step_pass 07_pg_help || return 1
  local mode="$1"
  local analysis decision help_report cadence_rc trial_id trial_root console rc trial_status
  local status result copy_dir path status_step
  analysis="$TX2_SESSION_ROOT/reports/06_pg_topology_analysis.rpt"
  decision="$(kv_field "$analysis" EDIT_POWER_VIA_TRIAL_DECISION)"
  rc=8
  status=FAIL
  result=PG_VIA_TRIAL_NOT_RUN

  if [[ "$mode" != "via-only" && "$mode" != "patch-stack" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: pg-via-trial requires via-only or patch-stack"
    return 1
  fi
  if [[ "$decision" != "READY_FOR_ONE_ISOLATED_TRIAL" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: topology analysis did not authorize a via trial"
    echo "EDIT_POWER_VIA_TRIAL_DECISION=${decision:-MISSING}"
    return 1
  fi
  help_report="$TX2_SESSION_ROOT/reports/07_pg_command_help/man_editPowerVia.rpt"
  if [[ ! -r "$help_report" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: installed editPowerVia help report is missing"
    echo "HELP_REPORT=$help_report"
    return 1
  fi
  if ! grep -Fq "setViaGenMode -area_only 1" "$help_report"; then
    echo "STOP_HERE_DO_NOT_CONTINUE: installed help does not prove bounded area-only generation"
    return 1
  fi
  if ! grep -Fq -- "-exclude_stack_vias" "$help_report"; then
    echo "STOP_HERE_DO_NOT_CONTINUE: installed help does not prove non-adjacent stack control"
    return 1
  fi

  trial_id="${TX2_SESSION_ID}_pg_via_${mode}"
  trial_root="$TX2_WORK_ROOT/diagnostics/$trial_id"
  console="$TX2_SESSION_ROOT/logs/08_pg_via_${mode}.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/08_pg_via_${mode}"
  status_step="08_pg_via_trial_${mode//-/_}"

  load_cadence
  cadence_rc=$?
  if [[ "$cadence_rc" -eq 0 ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    export SPADMIC_PG_VIA_TRIAL_HELP_REPORT="$help_report"
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_pg_via_trial.sh $TX2_BLOCK_ROOT $analysis $mode $trial_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_pg_via_trial.sh" \
      "$TX2_BLOCK_ROOT" \
      "$analysis" \
      "$mode" \
      "$trial_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    rc=$?
  fi

  trial_status="$trial_root/reports/pg_via_trial_status.rpt"
  if [[ "$rc" -eq 0 \
      && "$(kv_field "$trial_status" STATUS)" == "PASS" \
      && "$(kv_field "$trial_status" RESULT)" == "PG_VIA_METHOD_VALIDATED_NOT_CANONICAL" ]]; then
    status=PASS
    result=PG_VIA_METHOD_VALIDATED_NOT_CANONICAL
  else
    result=PG_VIA_METHOD_REJECTED_OR_INCOMPLETE
  fi

  mkdir -p "$copy_dir"
  if [[ -r "$trial_root/context.rpt" ]]; then
    cp -p "$trial_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$trial_root/reports" ]]; then
    for path in "$trial_root"/reports/*.rpt; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi
  echo "PG_VIA_TRIAL_RC=$rc"
  echo "PG_VIA_TRIAL_ROOT=$trial_root"
  if [[ -r "$trial_status" ]]; then
    cat "$trial_status"
  elif [[ -r "$console" ]]; then
    sed -n '1,240p' "$console"
  fi
  record_status "$status_step" "$status" "$rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

pg_via_drc_probe() {
  load_session || return 1
  require_step_pass 06_pg_analyze || return 1
  require_step_pass 07_pg_help || return 1
  local reference_step reference_trial analysis help_report trial_id trial_root
  local console copy_dir cadence_rc trial_rc trial_status analysis_report analysis_rc
  local status result path driver_report
  reference_step="$TX2_SESSION_ROOT/status/08_pg_via_trial_via_only.rpt"
  reference_trial="$TX2_SESSION_ROOT/reports/08_pg_via_via-only/pg_via_trial_status.rpt"
  analysis="$TX2_SESSION_ROOT/reports/06_pg_topology_analysis.rpt"
  help_report="$TX2_SESSION_ROOT/reports/07_pg_command_help/man_editPowerVia.rpt"
  status=FAIL
  result=PG_VIA_DRC_PROBE_NOT_RUN
  trial_rc=8
  analysis_rc=8

  if [[ "$(kv_field "$reference_step" STATUS)" != "FAIL" \
      || "$(kv_field "$reference_step" RESULT)" != "PG_VIA_METHOD_REJECTED_OR_INCOMPLETE" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: rejected via-only step evidence is missing"
    echo "REFERENCE_STEP=$reference_step"
    return 1
  fi
  if [[ "$(kv_field "$reference_trial" STATUS)" != "FAIL" \
      || "$(kv_field "$reference_trial" RESULT)" != "PG_VIA_METHOD_REJECTED" \
      || "$(kv_field "$reference_trial" COMMAND_FAIL_COUNT)" != "0" \
      || "$(kv_field "$reference_trial" PRE_DRC_VIOLATION_COUNT)" != "7" \
      || "$(kv_field "$reference_trial" POST_DRC_VIOLATION_COUNT)" != "25" \
      || "$(kv_field "$reference_trial" PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$reference_trial" POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$reference_trial" PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "4" \
      || "$(kv_field "$reference_trial" POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: via-only rejection tuple is not the reviewed 7-to-25 DRC result"
    echo "REFERENCE_TRIAL=$reference_trial"
    return 1
  fi
  if [[ ! -r "$analysis" || ! -r "$help_report" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: topology analysis or editPowerVia help is missing"
    return 1
  fi

  trial_id="${TX2_SESSION_ID}_pg_via_via-only_drc_probe_r2"
  trial_root="$TX2_WORK_ROOT/diagnostics/$trial_id"
  console="$TX2_SESSION_ROOT/logs/10_pg_via_drc_probe_r2.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/10_pg_via_drc_probe_r2"
  analysis_report="$TX2_SESSION_ROOT/reports/10_pg_via_drc_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/10_pg_via_drc_probe_driver.rpt"

  load_cadence
  cadence_rc=$?
  if [[ "$cadence_rc" -eq 0 ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    export SPADMIC_PG_VIA_TRIAL_HELP_REPORT="$help_report"
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_pg_via_trial.sh $TX2_BLOCK_ROOT $analysis via-only $trial_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_pg_via_trial.sh" \
      "$TX2_BLOCK_ROOT" \
      "$analysis" \
      via-only \
      "$trial_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    trial_rc=$?
  fi

  trial_status="$trial_root/reports/pg_via_trial_status.rpt"
  mkdir -p "$copy_dir"
  if [[ -r "$trial_root/context.rpt" ]]; then
    cp -p "$trial_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$trial_root/reports" ]]; then
    for path in "$trial_root"/reports/*.rpt "$trial_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$trial_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_pg_via_drc.py" \
      --trial-root "$trial_root" \
      --analysis-report "$analysis" \
      --reference-status "$reference_trial" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ "$trial_rc" -eq 8 \
      && "$analysis_rc" -eq 0 \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "DIRECT_STACK_DRC_MARKERS_CLASSIFIED" ]]; then
    status=PASS
    result=DIRECT_STACK_DRC_MARKERS_CLASSIFIED_NO_SAVE_EXPORT
  else
    result=PG_VIA_DRC_PROBE_INCOMPLETE
  fi

  {
    echo "TRIAL_RC=$trial_rc"
    echo "TRIAL_ROOT=$trial_root"
    echo "TRIAL_STATUS=$trial_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    sed -n '1,240p' "$console"
  fi
  record_status 10_pg_via_drc_probe_r2 "$status" "$analysis_rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

pg_via_1x1_trial() {
  load_session || return 1
  require_step_pass 10_pg_via_drc_probe_r2 || return 1
  local direct_analysis topology_analysis help_report trial_id trial_root console copy_dir
  local cadence_rc trial_rc trial_status candidate_report analysis_rc status result path
  local driver_report candidate_status
  direct_analysis="$TX2_SESSION_ROOT/reports/10_pg_via_drc_analysis.rpt"
  topology_analysis="$TX2_SESSION_ROOT/reports/06_pg_topology_analysis.rpt"
  help_report="$TX2_SESSION_ROOT/reports/07_pg_command_help/man_editPowerVia.rpt"
  status=FAIL
  result=PG_VIA_1X1_TRIAL_NOT_RUN
  trial_rc=8
  analysis_rc=8

  if [[ "$(kv_field "$direct_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$direct_analysis" RESULT)" != "DIRECT_STACK_DRC_MARKERS_CLASSIFIED" \
      || "$(kv_field "$direct_analysis" DIRECT_STACK_CONNECTIVITY_STATUS)" != "PASS_ZERO_SPECIAL_AND_REGULAR" \
      || "$(kv_field "$direct_analysis" DIRECT_STACK_DRC_STATUS)" != "FAIL_NEW_MARKERS" \
      || "$(kv_field "$direct_analysis" PRE_DRC_MARKER_COUNT)" != "7" \
      || "$(kv_field "$direct_analysis" POST_DRC_MARKER_COUNT)" != "25" \
      || "$(kv_field "$direct_analysis" NEW_DRC_MARKER_COUNT)" != "18" \
      || "$(kv_field "$direct_analysis" REMOVED_BASELINE_MARKER_COUNT)" != "0" \
      || "$(kv_field "$direct_analysis" NEXT_METHOD_DECISION)" != "REVIEW_NEW_MARKER_TABLE_BEFORE_ANY_NEW_TRIAL" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 10 direct-stack marker evidence is not the reviewed result"
    echo "DIRECT_ANALYSIS=$direct_analysis"
    return 1
  fi
  if [[ ! -r "$topology_analysis" || ! -r "$help_report" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: topology analysis or editPowerVia help is missing"
    return 1
  fi
  if ! grep -Fq -- "-via_rows" "$help_report" \
      || ! grep -Fq -- "-via_columns" "$help_report"; then
    echo "STOP_HERE_DO_NOT_CONTINUE: installed help does not prove explicit via multiplicity controls"
    return 1
  fi

  trial_id="${TX2_SESSION_ID}_pg_via_via-1x1"
  trial_root="$TX2_WORK_ROOT/diagnostics/$trial_id"
  console="$TX2_SESSION_ROOT/logs/11_pg_via_1x1_trial.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/11_pg_via_1x1_trial"
  candidate_report="$TX2_SESSION_ROOT/reports/11_pg_via_1x1_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/11_pg_via_1x1_driver.rpt"

  load_cadence
  cadence_rc=$?
  if [[ "$cadence_rc" -eq 0 ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    export SPADMIC_PG_VIA_TRIAL_HELP_REPORT="$help_report"
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_pg_via_trial.sh $TX2_BLOCK_ROOT $topology_analysis via-1x1 $trial_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_pg_via_trial.sh" \
      "$TX2_BLOCK_ROOT" \
      "$topology_analysis" \
      via-1x1 \
      "$trial_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    trial_rc=$?
  fi

  trial_status="$trial_root/reports/pg_via_trial_status.rpt"
  mkdir -p "$copy_dir"
  if [[ -r "$trial_root/context.rpt" ]]; then
    cp -p "$trial_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$trial_root/reports" ]]; then
    for path in "$trial_root"/reports/*.rpt "$trial_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$trial_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_pg_via_candidate.py" \
      --trial-root "$trial_root" \
      --analysis-report "$topology_analysis" \
      --expected-mode via-1x1 \
      --report "$candidate_report"
    analysis_rc=$?
  fi

  if [[ ( "$trial_rc" -eq 0 || "$trial_rc" -eq 8 ) \
      && "$analysis_rc" -eq 0 \
      && "$(kv_field "$candidate_report" STATUS)" == "PASS" \
      && "$(kv_field "$candidate_report" RESULT)" == "PG_VIA_CANDIDATE_CLASSIFIED" ]]; then
    status=PASS
    result=PG_VIA_1X1_CANDIDATE_CLASSIFIED_NO_SAVE_EXPORT
  else
    result=PG_VIA_1X1_CANDIDATE_CLASSIFICATION_INCOMPLETE
  fi
  candidate_status="$(kv_field "$candidate_report" CANDIDATE_PHYSICAL_STATUS)"

  {
    echo "TRIAL_RC=$trial_rc"
    echo "TRIAL_ROOT=$trial_root"
    echo "TRIAL_STATUS=$trial_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$candidate_report"
    echo "CANDIDATE_PHYSICAL_STATUS=${candidate_status:-UNKNOWN}"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "CANONICAL_RERUN=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$candidate_report" ]]; then
    cat "$candidate_report"
  elif [[ -r "$console" ]]; then
    sed -n '1,240p' "$console"
  fi
  record_status 11_pg_via_1x1_trial "$status" "$analysis_rc" "$result"
  [[ "$status" == "PASS" ]]
  return $?
}

preroute_pg_rerun() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: preroute-pg-rerun requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 11_pg_via_1x1_trial || return 1
  local step11 step11_status session_suffix candidate_run candidate_root candidate_block_root
  local console driver_report analysis_report actual_head cadence_rc wrapper_rc analysis_rc
  local status result physical_status direct_via_areas
  step11="$TX2_SESSION_ROOT/reports/11_pg_via_1x1_analysis.rpt"
  step11_status="$TX2_SESSION_ROOT/status/11_pg_via_1x1_trial.rpt"
  status=FAIL
  result=PREROUTE_PG_CANDIDATE_NOT_RUN
  cadence_rc=NOT_RUN
  wrapper_rc=NOT_RUN
  analysis_rc=NOT_RUN
  actual_head=UNKNOWN

  if [[ "$(kv_field "$step11_status" RESULT)" != "PG_VIA_1X1_CANDIDATE_CLASSIFIED_NO_SAVE_EXPORT" \
      || "$(kv_field "$step11" STATUS)" != "PASS" \
      || "$(kv_field "$step11" RESULT)" != "PG_VIA_CANDIDATE_CLASSIFIED" \
      || "$(kv_field "$step11" CANDIDATE_PHYSICAL_STATUS)" != "REJECTED_NEW_DRC" \
      || "$(kv_field "$step11" CANDIDATE_CONNECTIVITY_STATUS)" != "PASS_ZERO_SPECIAL_AND_REGULAR" \
      || "$(kv_field "$step11" CANDIDATE_DRC_STATUS)" != "FAIL_NEW_MARKERS" \
      || "$(kv_field "$step11" COMMAND_PASS_COUNT)" != "4" \
      || "$(kv_field "$step11" COMMAND_FAIL_COUNT)" != "0" \
      || "$(kv_field "$step11" PRE_DRC_MARKER_COUNT)" != "7" \
      || "$(kv_field "$step11" POST_DRC_MARKER_COUNT)" != "22" \
      || "$(kv_field "$step11" DRC_MARKER_DELTA)" != "15" \
      || "$(kv_field "$step11" NEW_DRC_MARKER_COUNT)" != "15" \
      || "$(kv_field "$step11" REMOVED_BASELINE_MARKER_COUNT)" != "0" \
      || "$(kv_field "$step11" NEW_MARKER_LAYER_COUNTS)" != "MET2:8 MET3:6 VIA2:1" \
      || "$(kv_field "$step11" NEW_MARKER_LAYER_SUBTYPE_COUNTS)" != "MET2/Metal_Short:6 MET2/Parallel_Run_Length_Spacing:2 MET3/Metal_Short:6 VIA2/Cut_Spacing:1" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 11 is not the reviewed 1x1 physical rejection"
    echo "STEP11_ANALYSIS=$step11"
    return 1
  fi

  session_suffix="${TX2_SESSION_ID#tx_packet_canonical_phase2_}"
  candidate_run="innovus_ooc_harden_tx_packet_core_canonical_preroute_pg1x1_${session_suffix}"
  candidate_root="$TX2_WORK_ROOT/innovus/$candidate_run"
  candidate_block_root="$candidate_root/blocks/tx_packet_core"
  console="$TX2_SESSION_ROOT/logs/12_preroute_pg_rerun.console.log"
  driver_report="$TX2_SESSION_ROOT/reports/12_preroute_pg_rerun_driver.rpt"
  analysis_report="$TX2_SESSION_ROOT/reports/12_preroute_pg_candidate_analysis.rpt"
  direct_via_areas="{515.200 126.160 518.560 126.960} {515.200 135.120 518.560 135.920} {515.200 278.480 518.560 279.280}"

  if [[ -e "$candidate_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable candidate root already exists"
    echo "CANDIDATE_ROOT=$candidate_root"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  local cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi
  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi

  if [[ "$cadence_rc" == "0" && "$actual_head" != "UNKNOWN" ]]; then
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
    export SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS=1
    export SPADMIC_OOC_PG_DIRECT_VIA_AREAS="$direct_via_areas"
    export SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR=1
    export SPADMIC_OOC_ENABLE_ANTENNA_REPAIR=0
    export SPADMIC_OOC_REQUIRE_ANTENNA_CLEAN=0
    export SPADMIC_OOC_IGNORE_UNDEFINED_SCAN=1
    export SPADMIC_OOC_ALLOW_SCAN_REORDER=0
    export SPADMIC_OOC_FILLER_ADD_FILLERS_WITH_DRC=0
    export SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER=1
    export SPADMIC_TX_ALLOW_ANTENNA_DEFERRED=1
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh tx_packet_core $TX2_GENUS_RUN $candidate_run"
    bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh \
      tx_packet_core \
      "$TX2_GENUS_RUN" \
      "$candidate_run" \
      2>&1 | tee "$console"
    wrapper_rc=${PIPESTATUS[0]}
  fi

  if [[ -r "$candidate_block_root/reports/ooc_harden_status.rpt" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_preroute_pg_candidate.py" \
      --block-root "$candidate_block_root" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ ( "$wrapper_rc" == "0" || "$wrapper_rc" == "8" ) \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "PREROUTE_PG_CANDIDATE_CLASSIFIED" ]]; then
    status=PASS
    result=PREROUTE_PG_CANDIDATE_CLASSIFIED_NO_AUTOMATIC_PVS_STAGING_OR_PVS
  else
    result=PREROUTE_PG_CANDIDATE_CLASSIFICATION_INCOMPLETE
  fi
  physical_status="$(kv_field "$analysis_report" CANDIDATE_PHYSICAL_STATUS)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "CANDIDATE_RUN=$candidate_run"
    echo "CANDIDATE_ROOT=$candidate_root"
    echo "CANDIDATE_BLOCK_ROOT=$candidate_block_root"
    echo "WRAPPER_RC=$wrapper_rc"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "CANDIDATE_PHYSICAL_STATUS=${physical_status:-UNKNOWN}"
    echo "CANDIDATE_EXPORT=RUN_LOCAL_AND_RUN_ID_HANDOFF_ONLY"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 240 "$console"
  fi
  record_status 12_preroute_pg_rerun "$status" "$analysis_rc" "$result" "$candidate_root"
  [[ "$status" == "PASS" ]]
  return $?
}

preroute_pg_postfiller_rerun() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: preroute-pg-postfiller-rerun requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 12_preroute_pg_rerun || return 1
  local step12 step12_status session_suffix candidate_run candidate_root candidate_block_root
  local console driver_report analysis_report actual_head cadence_rc wrapper_rc analysis_rc
  local status result physical_status direct_via_areas
  step12="$TX2_SESSION_ROOT/reports/12_preroute_pg_candidate_analysis.rpt"
  step12_status="$TX2_SESSION_ROOT/status/12_preroute_pg_rerun.rpt"
  status=FAIL
  result=PREROUTE_PG_POSTFILLER_CANDIDATE_NOT_RUN
  cadence_rc=NOT_RUN
  wrapper_rc=NOT_RUN
  analysis_rc=NOT_RUN
  actual_head=UNKNOWN

  if [[ "$(kv_field "$step12_status" RESULT)" != "PREROUTE_PG_CANDIDATE_CLASSIFIED_NO_AUTOMATIC_PVS_STAGING_OR_PVS" \
      || "$(kv_field "$step12" STATUS)" != "PASS" \
      || "$(kv_field "$step12" RESULT)" != "PREROUTE_PG_CANDIDATE_CLASSIFIED" \
      || "$(kv_field "$step12" CANDIDATE_PHYSICAL_STATUS)" != "REJECTED_PRE_CTS_MILESTONE" \
      || "$(kv_field "$step12" DIRECT_VIA_COMMAND_STATUS)" != "PASS" \
      || "$(kv_field "$step12" DIRECT_VIA_COMMAND_PASS_COUNT)" != "5" \
      || "$(kv_field "$step12" DIRECT_VIA_COMMAND_FAIL_COUNT)" != "0" \
      || "$(kv_field "$step12" PRE_CTS_SPECIAL_CONNECTIVITY_STATUS)" != "FAIL" \
      || "$(kv_field "$step12" PRE_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "156" \
      || "$(kv_field "$step12" PRE_CTS_DRC_STATUS)" != "PASS" \
      || "$(kv_field "$step12" PRE_CTS_DRC_VIOLATION_COUNT)" != "0" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 12 is not the reviewed dangling-only pre-CTS rejection"
    echo "STEP12_ANALYSIS=$step12"
    return 1
  fi

  session_suffix="${TX2_SESSION_ID#tx_packet_canonical_phase2_}"
  candidate_run="innovus_ooc_harden_tx_packet_core_canonical_preroute_pg1x1_postfiller_${session_suffix}"
  candidate_root="$TX2_WORK_ROOT/innovus/$candidate_run"
  candidate_block_root="$candidate_root/blocks/tx_packet_core"
  console="$TX2_SESSION_ROOT/logs/13_preroute_pg_postfiller_rerun.console.log"
  driver_report="$TX2_SESSION_ROOT/reports/13_preroute_pg_postfiller_rerun_driver.rpt"
  analysis_report="$TX2_SESSION_ROOT/reports/13_preroute_pg_postfiller_candidate_analysis.rpt"
  direct_via_areas="{515.200 126.160 518.560 126.960} {515.200 135.120 518.560 135.920} {515.200 278.480 518.560 279.280}"

  if [[ -e "$candidate_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable candidate root already exists"
    echo "CANDIDATE_ROOT=$candidate_root"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  local cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi
  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi

  if [[ "$cadence_rc" == "0" && "$actual_head" != "UNKNOWN" ]]; then
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
    export SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS=1
    export SPADMIC_OOC_PG_DIRECT_VIA_AREAS="$direct_via_areas"
    export SPADMIC_OOC_PRE_CTS_EXPECTED_DANGLING_COUNT=156
    export SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH=1
    export SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR=1
    export SPADMIC_OOC_ENABLE_ANTENNA_REPAIR=0
    export SPADMIC_OOC_REQUIRE_ANTENNA_CLEAN=0
    export SPADMIC_OOC_IGNORE_UNDEFINED_SCAN=1
    export SPADMIC_OOC_ALLOW_SCAN_REORDER=0
    export SPADMIC_OOC_FILLER_ADD_FILLERS_WITH_DRC=0
    export SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER=1
    export SPADMIC_TX_ALLOW_ANTENNA_DEFERRED=1
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh tx_packet_core $TX2_GENUS_RUN $candidate_run"
    bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh \
      tx_packet_core \
      "$TX2_GENUS_RUN" \
      "$candidate_run" \
      2>&1 | tee "$console"
    wrapper_rc=${PIPESTATUS[0]}
  fi

  if [[ -r "$candidate_block_root/reports/ooc_harden_status.rpt" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_preroute_pg_candidate.py" \
      --block-root "$candidate_block_root" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ ( "$wrapper_rc" == "0" || "$wrapper_rc" == "8" ) \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "PREROUTE_PG_CANDIDATE_CLASSIFIED" ]]; then
    status=PASS
    result=PREROUTE_PG_POSTFILLER_CANDIDATE_CLASSIFIED_NO_AUTOMATIC_PVS_STAGING_OR_PVS
  else
    result=PREROUTE_PG_POSTFILLER_CANDIDATE_CLASSIFICATION_INCOMPLETE
  fi
  physical_status="$(kv_field "$analysis_report" CANDIDATE_PHYSICAL_STATUS)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "CANDIDATE_RUN=$candidate_run"
    echo "CANDIDATE_ROOT=$candidate_root"
    echo "CANDIDATE_BLOCK_ROOT=$candidate_block_root"
    echo "WRAPPER_RC=$wrapper_rc"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "CANDIDATE_PHYSICAL_STATUS=${physical_status:-UNKNOWN}"
    echo "PRE_CTS_EXPECTED_DANGLING_COUNT=156"
    echo "POST_FILLER_PG_RESTITCH=ENABLED_STRICT_ZERO_CONNECTIVITY_AND_DRC"
    echo "CANDIDATE_EXPORT=RUN_LOCAL_AND_RUN_ID_HANDOFF_ONLY"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 240 "$console"
  fi
  record_status 13_preroute_pg_postfiller_rerun "$status" "$analysis_rc" "$result" "$candidate_root"
  [[ "$status" == "PASS" ]]
  return $?
}

postfiller_stage_probe() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: postfiller-stage-probe requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 13_preroute_pg_postfiller_rerun || return 1

  local step13_status step13_driver step13_analysis source_block_root
  local probe_id probe_root console copy_dir probe_status driver_report analysis_report
  local actual_head cadence_rc probe_rc analysis_rc status result path
  local stage_attribution next_decision
  step13_status="$TX2_SESSION_ROOT/status/13_preroute_pg_postfiller_rerun.rpt"
  step13_driver="$TX2_SESSION_ROOT/reports/13_preroute_pg_postfiller_rerun_driver.rpt"
  step13_analysis="$TX2_SESSION_ROOT/reports/13_preroute_pg_postfiller_candidate_analysis.rpt"
  status=FAIL
  result=POSTFILLER_STAGE_ATTRIBUTION_NOT_RUN
  cadence_rc=NOT_RUN
  probe_rc=NOT_RUN
  analysis_rc=NOT_RUN
  actual_head=UNKNOWN

  if [[ "$(kv_field "$step13_status" RESULT)" != "PREROUTE_PG_POSTFILLER_CANDIDATE_CLASSIFIED_NO_AUTOMATIC_PVS_STAGING_OR_PVS" \
      || "$(kv_field "$step13_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step13_analysis" RESULT)" != "PREROUTE_PG_CANDIDATE_CLASSIFIED" \
      || "$(kv_field "$step13_analysis" CANDIDATE_PHYSICAL_STATUS)" != "REJECTED_POST_FILLER_RESTITCH_MILESTONE" \
      || "$(kv_field "$step13_analysis" PRE_CTS_SPECIAL_CONNECTIVITY_STATUS)" != "EXPECTED_DANGLING_ONLY" \
      || "$(kv_field "$step13_analysis" PRE_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "156" \
      || "$(kv_field "$step13_analysis" PRE_CTS_IMPVFC_94_DANGLING_COUNT)" != "156" \
      || "$(kv_field "$step13_analysis" PRE_CTS_OTHER_PROBLEM_COUNT)" != "0" \
      || "$(kv_field "$step13_analysis" PRE_CTS_DRC_STATUS)" != "PASS" \
      || "$(kv_field "$step13_analysis" PRE_CTS_DRC_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step13_analysis" POST_FILLER_RESTITCH_ENABLED)" != "YES" \
      || "$(kv_field "$step13_analysis" POST_FILLER_SROUTE_STATUS)" != "PASS" \
      || "$(kv_field "$step13_analysis" POST_FILLER_SPECIAL_CONNECTIVITY_STATUS)" != "PASS" \
      || "$(kv_field "$step13_analysis" POST_FILLER_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step13_analysis" POST_FILLER_DRC_STATUS)" != "FAIL" \
      || "$(kv_field "$step13_analysis" POST_FILLER_DRC_VIOLATION_COUNT)" != "165" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 13 is not the reviewed zero-connectivity/165-DRC rejection"
    echo "STEP13_ANALYSIS=$step13_analysis"
    return 1
  fi

  source_block_root="$(kv_field "$step13_driver" CANDIDATE_BLOCK_ROOT)"
  if [[ -z "$source_block_root" || ! -d "$source_block_root" \
      || "$source_block_root" != "$(kv_field "$step13_analysis" BLOCK_ROOT)" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 13 candidate block root is missing or inconsistent"
    echo "SOURCE_BLOCK_ROOT=${source_block_root:-MISSING}"
    return 1
  fi

  probe_id="${TX2_SESSION_ID}_postfiller_stage_probe"
  probe_root="$TX2_WORK_ROOT/diagnostics/$probe_id"
  console="$TX2_SESSION_ROOT/logs/14_postfiller_stage_probe.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/14_postfiller_stage_probe"
  driver_report="$TX2_SESSION_ROOT/reports/14_postfiller_stage_probe_driver.rpt"
  analysis_report="$TX2_SESSION_ROOT/reports/14_postfiller_stage_analysis.rpt"
  if [[ -e "$probe_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable Step 14 probe root already exists"
    echo "PROBE_ROOT=$probe_root"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  local cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi
  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi

  if [[ "$cadence_rc" == "0" ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_postfiller_stage_probe.sh $source_block_root $probe_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_postfiller_stage_probe.sh" \
      "$source_block_root" \
      "$probe_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    probe_rc=$?
  fi

  probe_status="$probe_root/reports/postfiller_stage_probe_status.rpt"
  mkdir -p "$copy_dir"
  if [[ -r "$probe_root/context.rpt" ]]; then
    cp -p "$probe_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$probe_root/reports" ]]; then
    for path in "$probe_root"/reports/*.rpt "$probe_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$probe_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_postfiller_stage_probe.py" \
      --probe-root "$probe_root" \
      --step13-analysis "$step13_analysis" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ "$probe_rc" == "0" \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "POSTFILLER_STAGE_ATTRIBUTION_CLASSIFIED" ]]; then
    status=PASS
    result=POSTFILLER_STAGE_ATTRIBUTION_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS
  else
    result=POSTFILLER_STAGE_ATTRIBUTION_INCOMPLETE
  fi
  stage_attribution="$(kv_field "$analysis_report" STAGE_ATTRIBUTION)"
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP13_ANALYSIS=$step13_analysis"
    echo "SOURCE_BLOCK_ROOT=$source_block_root"
    echo "PROBE_RC=$probe_rc"
    echo "PROBE_ROOT=$probe_root"
    echo "PROBE_STATUS=$probe_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "STAGE_ATTRIBUTION=${stage_attribution:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "POST_FILLER_SROUTE=NOT_RUN"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    sed -n '1,260p' "$console"
  fi
  record_status 14_postfiller_stage_probe "$status" "$analysis_rc" "$result" "$probe_root"
  [[ "$status" == "PASS" ]]
  return $?
}

postcts_via1_analyze() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: postcts-via1-analyze requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 14_postfiller_stage_probe || return 1

  local step13_driver step13_analysis step14_status step14_driver step14_analysis
  local probe_root step13_block_root actual_head cd_rc analysis_report driver_report
  local analysis_rc status result next_decision
  step13_driver="$TX2_SESSION_ROOT/reports/13_preroute_pg_postfiller_rerun_driver.rpt"
  step13_analysis="$TX2_SESSION_ROOT/reports/13_preroute_pg_postfiller_candidate_analysis.rpt"
  step14_status="$TX2_SESSION_ROOT/status/14_postfiller_stage_probe.rpt"
  step14_driver="$TX2_SESSION_ROOT/reports/14_postfiller_stage_probe_driver.rpt"
  step14_analysis="$TX2_SESSION_ROOT/reports/14_postfiller_stage_analysis.rpt"
  analysis_report="$TX2_SESSION_ROOT/reports/15_postcts_via1_marker_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/15_postcts_via1_analyze_driver.rpt"
  actual_head=UNKNOWN
  analysis_rc=NOT_RUN
  status=FAIL
  result=POST_CTS_VIA1_MARKER_CLASSIFICATION_NOT_RUN

  if [[ "$(kv_field "$step14_status" RESULT)" != "POSTFILLER_STAGE_ATTRIBUTION_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS" \
      || "$(kv_field "$step14_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step14_analysis" RESULT)" != "POSTFILLER_STAGE_ATTRIBUTION_CLASSIFIED" \
      || "$(kv_field "$step14_analysis" STAGE_ATTRIBUTION)" != "CTS_STAGE_INTRODUCES_DRC" \
      || "$(kv_field "$step14_analysis" POST_CTS_DRC_VIOLATION_COUNT)" != "1000" \
      || "$(kv_field "$step14_analysis" POST_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "154" \
      || "$(kv_field "$step14_analysis" POST_CTS_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "239" \
      || "$(kv_field "$step14_analysis" POST_FILLER_PRE_RESTITCH_DRC_VIOLATION_COUNT)" != "1000" \
      || "$(kv_field "$step14_analysis" POST_FILLER_PRE_RESTITCH_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step14_analysis" POST_FILLER_PRE_RESTITCH_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "239" \
      || "$(kv_field "$step14_analysis" FILLER_NEW_DRC_MARKER_COUNT)" != "0" \
      || "$(kv_field "$step14_analysis" FILLER_REMOVED_DRC_MARKER_COUNT)" != "0" \
      || "$(kv_field "$step14_analysis" PVS_DECISION)" != "DO_NOT_RUN" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 14 is not the reviewed post-CTS VIA1 evidence tuple"
    echo "STEP14_ANALYSIS=$step14_analysis"
    return 1
  fi

  probe_root="$(kv_field "$step14_driver" PROBE_ROOT)"
  step13_block_root="$(kv_field "$step13_driver" CANDIDATE_BLOCK_ROOT)"
  if [[ -z "$probe_root" || ! -d "$probe_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 14 probe root is missing"
    echo "PROBE_ROOT=${probe_root:-MISSING}"
    return 1
  fi
  if [[ -z "$step13_block_root" || ! -d "$step13_block_root" \
      || "$step13_block_root" != "$(kv_field "$step13_analysis" BLOCK_ROOT)" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 13 block root is missing or inconsistent"
    echo "STEP13_BLOCK_ROOT=${step13_block_root:-MISSING}"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_postcts_via1_markers.py" \
      --probe-root "$probe_root" \
      --step13-block-root "$step13_block_root" \
      --step13-analysis "$step13_analysis" \
      --step14-analysis "$step14_analysis" \
      --report-driver-head "$actual_head" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "POST_CTS_VIA1_MARKERS_CLASSIFIED" \
      && "$(kv_field "$analysis_report" POST_CTS_MARKER_SIGNATURE_STABILITY)" == "PASS_IDENTICAL_BEFORE_AND_AFTER_FILLER" \
      && "$(kv_field "$analysis_report" FILLER_SPECIAL_CONNECTIVITY_EFFECT)" == "CLOSED_154_TO_0_WITHOUT_SROUTE" \
      && "$(kv_field "$analysis_report" POST_FILLER_SROUTE_ELECTRICAL_NECESSITY)" == "NOT_REQUIRED_FOR_SPECIAL_CONNECTIVITY" \
      && "$(kv_field "$analysis_report" PVS_DECISION)" == "DO_NOT_RUN" ]]; then
    status=PASS
    result=POSTCTS_VIA1_CAPTURE_CLASSIFIED_NO_DESIGN_MODIFICATION
  else
    result=POST_CTS_VIA1_MARKER_CLASSIFICATION_INCOMPLETE
  fi
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP13_ANALYSIS=$step13_analysis"
    echo "SOURCE_STEP14_ANALYSIS=$step14_analysis"
    echo "SOURCE_PROBE_ROOT=$probe_root"
    echo "SOURCE_STEP13_BLOCK_ROOT=$step13_block_root"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "ANALYSIS_MODE=READ_ONLY_TEXT_ARTIFACTS_NO_INNOVUS"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "DESIGN_MODIFICATION=NOT_RUN"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  fi
  record_status 15_postcts_via1_analyze "$status" "$analysis_rc" "$result" "$probe_root"
  [[ "$status" == "PASS" ]]
  return $?
}

preroute_pg_no_restitch_rerun() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: preroute-pg-no-restitch-rerun requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 15_postcts_via1_analyze || return 1

  local step15_status step15_analysis session_suffix candidate_run candidate_root
  local candidate_block_root console driver_report analysis_report actual_head cd_rc
  local cadence_rc wrapper_rc analysis_rc status result physical_status next_decision
  local direct_via_areas
  step15_status="$TX2_SESSION_ROOT/status/15_postcts_via1_analyze.rpt"
  step15_analysis="$TX2_SESSION_ROOT/reports/15_postcts_via1_marker_analysis.rpt"
  status=FAIL
  result=PREROUTE_PG_NO_RESTITCH_CANDIDATE_NOT_RUN
  cadence_rc=NOT_RUN
  wrapper_rc=NOT_RUN
  analysis_rc=NOT_RUN
  actual_head=UNKNOWN

  if [[ "$(kv_field "$step15_status" RESULT)" != "POSTCTS_VIA1_CAPTURE_CLASSIFIED_NO_DESIGN_MODIFICATION" \
      || "$(kv_field "$step15_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step15_analysis" RESULT)" != "POST_CTS_VIA1_MARKERS_CLASSIFIED" \
      || "$(kv_field "$step15_analysis" POST_CTS_DRC_COUNT_INTERPRETATION)" != "AT_LEAST_1000_EXACT_TOTAL_UNPROVEN" \
      || "$(kv_field "$step15_analysis" POST_CTS_MARKER_SIGNATURE_STABILITY)" != "PASS_IDENTICAL_BEFORE_AND_AFTER_FILLER" \
      || "$(kv_field "$step15_analysis" POST_CTS_MARKER_LAYER_SUBTYPE_COUNTS)" != "VIA1/Cut_Enclosure:1000" \
      || "$(kv_field "$step15_analysis" POST_CTS_RULE_TEMPLATE_UNIQUE_COUNT)" != "2" \
      || "$(kv_field "$step15_analysis" POST_CTS_RULE_TEMPLATE_TABLE_TRUNCATED)" != "NO" \
      || "$(kv_field "$step15_analysis" POST_CTS_REGULAR_NET_UNIQUE_COUNT)" != "403" \
      || "$(kv_field "$step15_analysis" POST_CTS_SPECIAL_NET_UNIQUE_COUNT)" != "0" \
      || "$(kv_field "$step15_analysis" FILLER_SPECIAL_CONNECTIVITY_EFFECT)" != "CLOSED_154_TO_0_WITHOUT_SROUTE" \
      || "$(kv_field "$step15_analysis" POST_FILLER_SROUTE_ELECTRICAL_NECESSITY)" != "NOT_REQUIRED_FOR_SPECIAL_CONNECTIVITY" \
      || "$(kv_field "$step15_analysis" REGULAR_CONNECTIVITY_INTERPRETATION)" != "PRE_SIGNAL_ROUTE_OBSERVATION_NOT_A_FINAL_CONNECTIVITY_GATE" \
      || "$(kv_field "$step15_analysis" PVS_DECISION)" != "DO_NOT_RUN" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 15 is not the reviewed pre-route VIA1 enclosure tuple"
    echo "STEP15_ANALYSIS=$step15_analysis"
    return 1
  fi

  session_suffix="${TX2_SESSION_ID#tx_packet_canonical_phase2_}"
  candidate_run="innovus_ooc_harden_tx_packet_core_canonical_preroute_pg1x1_no_restitch_${session_suffix}"
  candidate_root="$TX2_WORK_ROOT/innovus/$candidate_run"
  candidate_block_root="$candidate_root/blocks/tx_packet_core"
  console="$TX2_SESSION_ROOT/logs/16_preroute_pg_no_restitch_rerun.console.log"
  driver_report="$TX2_SESSION_ROOT/reports/16_preroute_pg_no_restitch_rerun_driver.rpt"
  analysis_report="$TX2_SESSION_ROOT/reports/16_preroute_pg_no_restitch_candidate_analysis.rpt"
  direct_via_areas="{515.200 126.160 518.560 126.960} {515.200 135.120 518.560 135.920} {515.200 278.480 518.560 279.280}"

  if [[ -e "$candidate_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable candidate root already exists"
    echo "CANDIDATE_ROOT=$candidate_root"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi
  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi

  if [[ "$cadence_rc" == "0" && "$actual_head" != "UNKNOWN" ]]; then
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
    export SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS=1
    export SPADMIC_OOC_PG_DIRECT_VIA_AREAS="$direct_via_areas"
    export SPADMIC_OOC_PRE_CTS_EXPECTED_DANGLING_COUNT=156
    export SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH=0
    export SPADMIC_OOC_ENABLE_MIN_AREA_REPAIR=1
    export SPADMIC_OOC_ENABLE_ANTENNA_REPAIR=0
    export SPADMIC_OOC_REQUIRE_ANTENNA_CLEAN=0
    export SPADMIC_OOC_IGNORE_UNDEFINED_SCAN=1
    export SPADMIC_OOC_ALLOW_SCAN_REORDER=0
    export SPADMIC_OOC_FILLER_ADD_FILLERS_WITH_DRC=0
    export SPADMIC_OOC_REQUIRE_DRC_SAFE_FILLER=1
    export SPADMIC_TX_ALLOW_ANTENNA_DEFERRED=1
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh tx_packet_core $TX2_GENUS_RUN $candidate_run"
    bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh \
      tx_packet_core \
      "$TX2_GENUS_RUN" \
      "$candidate_run" \
      2>&1 | tee "$console"
    wrapper_rc=${PIPESTATUS[0]}
  fi

  if [[ -r "$candidate_block_root/reports/ooc_harden_status.rpt" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_preroute_pg_candidate.py" \
      --block-root "$candidate_block_root" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ ( "$wrapper_rc" == "0" || "$wrapper_rc" == "8" ) \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "PREROUTE_PG_CANDIDATE_CLASSIFIED" \
      && "$(kv_field "$analysis_report" PRE_CTS_EXPECTED_DANGLING_POLICY)" == "ENABLED_EXACT_156" \
      && "$(kv_field "$analysis_report" POST_FILLER_RESTITCH_ENABLED)" == "NO" ]]; then
    status=PASS
    result=PREROUTE_PG_NO_RESTITCH_CANDIDATE_CLASSIFIED_NO_AUTOMATIC_PVS_STAGING_OR_PVS
  else
    result=PREROUTE_PG_NO_RESTITCH_CANDIDATE_CLASSIFICATION_INCOMPLETE
  fi
  physical_status="$(kv_field "$analysis_report" CANDIDATE_PHYSICAL_STATUS)"
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP15_ANALYSIS=$step15_analysis"
    echo "CANDIDATE_RUN=$candidate_run"
    echo "CANDIDATE_ROOT=$candidate_root"
    echo "CANDIDATE_BLOCK_ROOT=$candidate_block_root"
    echo "WRAPPER_RC=$wrapper_rc"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "CANDIDATE_PHYSICAL_STATUS=${physical_status:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "PRE_CTS_EXPECTED_DANGLING_COUNT=156"
    echo "POST_FILLER_PG_RESTITCH=DISABLED_PROVEN_REDUNDANT"
    echo "POST_FILLER_SROUTE=NOT_RUN"
    echo "PRE_ROUTE_DRC_GATE=NOT_RUN_INCOMPLETE_SIGNAL_GEOMETRY"
    echo "ORDINARY_SIGNAL_ROUTE=RUN_CANONICAL_ROUTE_DESIGN"
    echo "AUTHORITATIVE_FINAL_GATES=REGULAR_CONNECTIVITY_PG_CONNECTIVITY_DRC_TIMING_EXPORT_CANONICAL_GATE"
    echo "CANDIDATE_EXPORT=RUN_LOCAL_AND_RUN_ID_HANDOFF_ONLY"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 240 "$console"
  fi
  record_status 16_preroute_pg_no_restitch_rerun "$status" "$analysis_rc" "$result" "$candidate_root"
  [[ "$status" == "PASS" ]]
  return $?
}

final_closure_analyze() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: final-closure-analyze requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 16_preroute_pg_no_restitch_rerun || return 1

  local step16_status step16_driver step16_analysis candidate_block_root
  local actual_head cd_rc analysis_report driver_report analysis_rc
  local status result physical_status min_area_effect pin_mapping_decision
  step16_status="$TX2_SESSION_ROOT/status/16_preroute_pg_no_restitch_rerun.rpt"
  step16_driver="$TX2_SESSION_ROOT/reports/16_preroute_pg_no_restitch_rerun_driver.rpt"
  step16_analysis="$TX2_SESSION_ROOT/reports/16_preroute_pg_no_restitch_candidate_analysis.rpt"
  analysis_report="$TX2_SESSION_ROOT/reports/17_final_closure_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/17_final_closure_analyze_driver.rpt"
  actual_head=UNKNOWN
  analysis_rc=NOT_RUN
  status=FAIL
  result=FINAL_CLOSURE_CLASSIFICATION_NOT_RUN

  if [[ "$(kv_field "$step16_status" RESULT)" != "PREROUTE_PG_NO_RESTITCH_CANDIDATE_CLASSIFIED_NO_AUTOMATIC_PVS_STAGING_OR_PVS" \
      || "$(kv_field "$step16_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step16_analysis" RESULT)" != "PREROUTE_PG_CANDIDATE_CLASSIFIED" \
      || "$(kv_field "$step16_analysis" PRE_CTS_EXPECTED_DANGLING_POLICY)" != "ENABLED_EXACT_156" \
      || "$(kv_field "$step16_analysis" PRE_CTS_IMPVFC_94_DANGLING_COUNT)" != "156" \
      || "$(kv_field "$step16_analysis" PRE_CTS_OTHER_PROBLEM_COUNT)" != "0" \
      || "$(kv_field "$step16_analysis" PRE_CTS_DRC_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step16_analysis" POST_FILLER_RESTITCH_ENABLED)" != "NO" \
      || "$(kv_field "$step16_analysis" FINAL_PG_CONNECTIVITY_STATUS)" != "PASS" \
      || "$(kv_field "$step16_analysis" FINAL_REGULAR_CONNECTIVITY_STATUS)" != "PASS" \
      || "$(kv_field "$step16_analysis" FINAL_DRC_STATUS)" != "FAIL" \
      || "$(kv_field "$step16_analysis" FINAL_MET1_MIN_AREA_MARKER_COUNT)" != "6" \
      || "$(kv_field "$step16_analysis" FINAL_ANTENNA_MARKER_COUNT)" != "177" \
      || "$(kv_field "$step16_analysis" FINAL_OTHER_MARKER_COUNT)" != "0" \
      || "$(kv_field "$step16_analysis" SETUP_WNS_NS)" != "0.131" \
      || "$(kv_field "$step16_analysis" HOLD_WNS_NS)" != "0.206" \
      || "$(kv_field "$step16_analysis" PVS_DECISION)" != "DO_NOT_RUN_FROM_THIS_STEP" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 16 is not the reviewed routed closure tuple"
    echo "STEP16_ANALYSIS=$step16_analysis"
    return 1
  fi

  candidate_block_root="$(kv_field "$step16_driver" CANDIDATE_BLOCK_ROOT)"
  if [[ -z "$candidate_block_root" || ! -d "$candidate_block_root" \
      || "$candidate_block_root" != "$(kv_field "$step16_analysis" BLOCK_ROOT)" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 16 candidate block root is missing or inconsistent"
    echo "CANDIDATE_BLOCK_ROOT=${candidate_block_root:-MISSING}"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_ooc_failure.py" \
      --block-root "$candidate_block_root" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" DIAGNOSIS_STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "BLOCKERS_CLASSIFIED" \
      && "$(kv_field "$analysis_report" PHYSICAL_CANDIDATE_STATUS)" == "PG_AND_REGULAR_CLOSED_FINAL_REPAIR_REQUIRED" \
      && "$(kv_field "$analysis_report" FINAL_DRC_STATUS)" == "FAIL" \
      && "$(kv_field "$analysis_report" REGULAR_CONNECTIVITY_STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" PG_CONNECTIVITY_STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" PG_PROBLEM_COUNT)" == "0" \
      && "$(kv_field "$analysis_report" PG_DIAGNOSIS)" == "TOPOLOGY_CLOSED" \
      && "$(kv_field "$analysis_report" MIN_AREA_FINAL_MARKER_COUNT)" == "6" \
      && "$(kv_field "$analysis_report" ANTENNA_FINAL_MARKER_COUNT)" == "177" \
      && "$(kv_field "$analysis_report" STREAM_PIN_COUNT)" == "19" \
      && "$(kv_field "$analysis_report" STREAM_PIN_EXPECTED_COUNT)" == "19" \
      && "$(kv_field "$analysis_report" STREAM_PIN_UNIQUE_DELTA_UM)" == "-0.280000" \
      && "$(kv_field "$analysis_report" STREAM_PIN_DELTA_STATUS)" == "UNIFORM" \
      && "$(kv_field "$analysis_report" STREAM_PIN_TARGET_STATUS)" == "CANONICAL_TARGETS_PRESERVED" \
      && "$(kv_field "$analysis_report" STREAM_PIN_UNIQUE_ASSIGN_MINUS_TARGET_UM)" == "-0.280000" \
      && "$(kv_field "$analysis_report" STREAM_PIN_UNIQUE_ACTUAL_MINUS_ASSIGN_UM)" == "0.000000" \
      && "$(kv_field "$analysis_report" STREAM_PIN_ASSIGNMENT_STATUS)" == "ACTUAL_MATCHES_GENERATED_ASSIGN_X" \
      && "$(kv_field "$analysis_report" STREAM_PIN_COMMAND_MAPPING_DECISION)" == "REMOVE_NEGATIVE_COMPENSATION_KEEP_CANONICAL_CENTERS" \
      && "$(kv_field "$analysis_report" PVS_DECISION)" == "DO_NOT_RUN" ]]; then
    status=PASS
    result=FINAL_CLOSURE_BLOCKERS_CLASSIFIED_NO_DESIGN_MODIFICATION
  else
    result=FINAL_CLOSURE_CLASSIFICATION_INCOMPLETE
  fi
  physical_status="$(kv_field "$analysis_report" PHYSICAL_CANDIDATE_STATUS)"
  min_area_effect="$(kv_field "$analysis_report" MIN_AREA_REPAIR_EFFECT)"
  pin_mapping_decision="$(kv_field "$analysis_report" STREAM_PIN_COMMAND_MAPPING_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP16_STATUS=$step16_status"
    echo "SOURCE_STEP16_DRIVER=$step16_driver"
    echo "SOURCE_STEP16_ANALYSIS=$step16_analysis"
    echo "CANDIDATE_BLOCK_ROOT=$candidate_block_root"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "ANALYSIS_MODE=READ_ONLY_TEXT_ARTIFACTS_NO_INNOVUS"
    echo "PHYSICAL_CANDIDATE_STATUS=${physical_status:-UNKNOWN}"
    echo "MIN_AREA_REPAIR_EFFECT=${min_area_effect:-UNKNOWN}"
    echo "PIN_MAPPING_DECISION=${pin_mapping_decision:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=REVIEW_SIX_MET1_MARKERS_AND_REMOVE_PIN_ASSIGNMENT_COMPENSATION"
    echo "DESIGN_MODIFICATION=NOT_RUN"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  fi
  record_status 17_final_closure_analyze "$status" "$analysis_rc" "$result" "$candidate_block_root"
  [[ "$status" == "PASS" ]]
  return $?
}

min_area_second_pass_trial_r2() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: min-area-second-pass-trial-r2 requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 17_final_closure_analyze || return 1

  local step17_status step17_driver step17_analysis step18_status step18_driver
  local step18_analysis source_block_root
  local actual_head cd_rc cadence_rc trial_id trial_root trial_status console copy_dir
  local trial_rc analysis_report analysis_rc driver_report status result path
  local method_status trial_process_status trial_process_result drc_sequence next_decision
  step17_status="$TX2_SESSION_ROOT/status/17_final_closure_analyze.rpt"
  step17_driver="$TX2_SESSION_ROOT/reports/17_final_closure_analyze_driver.rpt"
  step17_analysis="$TX2_SESSION_ROOT/reports/17_final_closure_analysis.rpt"
  step18_status="$TX2_SESSION_ROOT/status/18_min_area_second_pass_trial.rpt"
  step18_driver="$TX2_SESSION_ROOT/reports/18_min_area_second_pass_trial_driver.rpt"
  step18_analysis="$TX2_SESSION_ROOT/reports/18_min_area_second_pass_analysis.rpt"
  actual_head=UNKNOWN
  cadence_rc=NOT_RUN
  trial_rc=NOT_RUN
  analysis_rc=NOT_RUN
  status=FAIL
  result=MIN_AREA_SECOND_PASS_CLASSIFICATION_NOT_RUN

  if [[ "$(kv_field "$step17_status" RESULT)" != "FINAL_CLOSURE_BLOCKERS_CLASSIFIED_NO_DESIGN_MODIFICATION" \
      || "$(kv_field "$step17_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step17_analysis" RESULT)" != "BLOCKERS_CLASSIFIED" \
      || "$(kv_field "$step17_analysis" PHYSICAL_CANDIDATE_STATUS)" != "PG_AND_REGULAR_CLOSED_FINAL_REPAIR_REQUIRED" \
      || "$(kv_field "$step17_analysis" FINAL_DRC_STATUS)" != "FAIL" \
      || "$(kv_field "$step17_analysis" REGULAR_CONNECTIVITY_STATUS)" != "PASS" \
      || "$(kv_field "$step17_analysis" PG_CONNECTIVITY_STATUS)" != "PASS" \
      || "$(kv_field "$step17_analysis" PG_PROBLEM_COUNT)" != "0" \
      || "$(kv_field "$step17_analysis" MIN_AREA_REPAIR_EFFECT)" != "REDUCED_10_TO_6" \
      || "$(kv_field "$step17_analysis" MIN_AREA_PRE_MARKER_COUNT)" != "10" \
      || "$(kv_field "$step17_analysis" MIN_AREA_POST_MARKER_COUNT)" != "6" \
      || "$(kv_field "$step17_analysis" MIN_AREA_FINAL_MARKER_COUNT)" != "6" \
      || "$(kv_field "$step17_analysis" ANTENNA_FINAL_MARKER_COUNT)" != "177" \
      || "$(kv_field "$step17_analysis" STREAM_PIN_TARGET_STATUS)" != "CANONICAL_TARGETS_PRESERVED" \
      || "$(kv_field "$step17_analysis" STREAM_PIN_COMMAND_MAPPING_DECISION)" != "REMOVE_NEGATIVE_COMPENSATION_KEEP_CANONICAL_CENTERS" \
      || "$(kv_field "$step17_analysis" PVS_DECISION)" != "DO_NOT_RUN" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 17 is not the reviewed six-marker closure tuple"
    echo "STEP17_ANALYSIS=$step17_analysis"
    return 1
  fi

  if [[ "$(kv_field "$step18_status" STATUS)" != "FAIL" \
      || "$(kv_field "$step18_status" RC)" != "8" \
      || "$(kv_field "$step18_status" RESULT)" != "MIN_AREA_SECOND_PASS_CLASSIFICATION_INCOMPLETE" \
      || "$(kv_field "$step18_driver" TRIAL_RC)" != "8" \
      || "$(kv_field "$step18_driver" ANALYSIS_RC)" != "8" \
      || "$(kv_field "$step18_driver" TRIAL_PROCESS_RESULT)" != "BASELINE_PRECONDITION_FAILED" \
      || "$(kv_field "$step18_analysis" STATUS)" != "FAIL" \
      || "$(kv_field "$step18_analysis" RESULT)" != "ITERATIVE_MIN_AREA_TRIAL_CLASSIFICATION_INCOMPLETE" \
      || "$(kv_field "$step18_analysis" TRIAL_PROCESS_RESULT)" != "BASELINE_PRECONDITION_FAILED" \
      || "$(kv_field "$step18_analysis" PRE_DRC_VIOLATION_COUNT)" != "6" \
      || "$(kv_field "$step18_analysis" PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step18_analysis" PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step18_analysis" PRE_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step18_analysis" PRE_MARKER_DATABASE_TOTAL)" != "27" \
      || "$(kv_field "$step18_analysis" ITERATION_COUNT)" != "0" \
      || "$(kv_field "$step18_analysis" PRE_MIN_AREA_NETS)" != "n_9677 n_9693 n_9696 n_9697 n_9706 n_9721" \
      || "$(kv_field "$step18_analysis" PVS_DECISION)" != "DO_NOT_RUN" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 18 is not the reviewed no-command restored-marker guard failure"
    echo "STEP18_STATUS=$step18_status"
    echo "STEP18_DRIVER=$step18_driver"
    echo "STEP18_ANALYSIS=$step18_analysis"
    return 1
  fi

  source_block_root="$(kv_field "$step17_driver" CANDIDATE_BLOCK_ROOT)"
  if [[ -z "$source_block_root" || ! -d "$source_block_root" \
      || "$source_block_root" != "$(kv_field "$step17_analysis" BLOCK_ROOT)" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 17 source block root is missing or inconsistent"
    echo "SOURCE_BLOCK_ROOT=${source_block_root:-MISSING}"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  trial_id="${TX2_SESSION_ID}_min_area_second_pass_trial_r2"
  trial_root="$TX2_WORK_ROOT/diagnostics/$trial_id"
  trial_status="$trial_root/reports/min_area_second_pass_trial_status.rpt"
  console="$TX2_SESSION_ROOT/logs/19_min_area_second_pass_trial_r2.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/19_min_area_second_pass_trial_r2"
  analysis_report="$TX2_SESSION_ROOT/reports/19_min_area_second_pass_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/19_min_area_second_pass_trial_driver.rpt"
  if [[ -e "$trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable Step 19 R2 trial root already exists"
    echo "TRIAL_ROOT=$trial_root"
    return 1
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi
  if [[ "$cadence_rc" == "0" ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    export SPADMIC_MIN_AREA_TRIAL_REVISION=R2
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_min_area_second_pass_trial.sh $source_block_root $step17_analysis $trial_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_min_area_second_pass_trial.sh" \
      "$source_block_root" \
      "$step17_analysis" \
      "$trial_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    trial_rc=$?
  fi

  mkdir -p "$copy_dir"
  if [[ -r "$trial_root/context.rpt" ]]; then
    cp -p "$trial_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$trial_root/reports" ]]; then
    for path in "$trial_root"/reports/*.rpt "$trial_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$trial_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_min_area_second_pass_trial.py" \
      --trial-root "$trial_root" \
      --step17-analysis "$step17_analysis" \
      --report-driver-head "$actual_head" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ ( "$trial_rc" == "0" || "$trial_rc" == "8" ) \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "ITERATIVE_MIN_AREA_TRIAL_CLASSIFIED" ]]; then
    status=PASS
    result=MIN_AREA_SECOND_PASS_R2_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS
  else
    result=MIN_AREA_SECOND_PASS_CLASSIFICATION_INCOMPLETE
  fi
  method_status="$(kv_field "$analysis_report" METHOD_STATUS)"
  trial_process_status="$(kv_field "$analysis_report" TRIAL_PROCESS_STATUS)"
  trial_process_result="$(kv_field "$analysis_report" TRIAL_PROCESS_RESULT)"
  drc_sequence="$(kv_field "$analysis_report" DRC_COUNT_SEQUENCE)"
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP17_STATUS=$step17_status"
    echo "SOURCE_STEP17_DRIVER=$step17_driver"
    echo "SOURCE_STEP17_ANALYSIS=$step17_analysis"
    echo "SOURCE_STEP18_STATUS=$step18_status"
    echo "SOURCE_STEP18_DRIVER=$step18_driver"
    echo "SOURCE_STEP18_ANALYSIS=$step18_analysis"
    echo "SOURCE_BLOCK_ROOT=$source_block_root"
    echo "TRIAL_REVISION=R2"
    echo "TRIAL_RC=$trial_rc"
    echo "TRIAL_ROOT=$trial_root"
    echo "TRIAL_STATUS=$trial_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "TRIAL_PROCESS_STATUS=${trial_process_status:-UNKNOWN}"
    echo "TRIAL_PROCESS_RESULT=${trial_process_result:-UNKNOWN}"
    echo "METHOD_STATUS=${method_status:-UNKNOWN}"
    echo "DRC_COUNT_SEQUENCE=${drc_sequence:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "DESIGN_MODIFICATION=IN_MEMORY_ONLY"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 260 "$console"
  fi
  record_status 19_min_area_second_pass_trial_r2 "$status" "$analysis_rc" "$result" "$trial_root"
  [[ "$status" == "PASS" ]]
  return $?
}

min_area_geometry_probe() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: min-area-geometry-probe requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 19_min_area_second_pass_trial_r2 || return 1

  local step19_status step19_driver step19_analysis source_block_root
  local actual_head cd_rc cadence_rc probe_id probe_root probe_status console copy_dir
  local probe_rc analysis_report analysis_rc driver_report status result path
  local topology_capture local_geometry_capture next_decision
  step19_status="$TX2_SESSION_ROOT/status/19_min_area_second_pass_trial_r2.rpt"
  step19_driver="$TX2_SESSION_ROOT/reports/19_min_area_second_pass_trial_driver.rpt"
  step19_analysis="$TX2_SESSION_ROOT/reports/19_min_area_second_pass_analysis.rpt"
  actual_head=UNKNOWN
  cadence_rc=NOT_RUN
  probe_rc=NOT_RUN
  analysis_rc=NOT_RUN
  status=FAIL
  result=MIN_AREA_GEOMETRY_CLASSIFICATION_NOT_RUN

  if [[ "$(kv_field "$step19_status" STATUS)" != "PASS" \
      || "$(kv_field "$step19_status" RC)" != "0" \
      || "$(kv_field "$step19_status" RESULT)" != "MIN_AREA_SECOND_PASS_R2_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS" \
      || "$(kv_field "$step19_driver" TRIAL_REVISION)" != "R2" \
      || "$(kv_field "$step19_driver" TRIAL_RC)" != "8" \
      || "$(kv_field "$step19_driver" ANALYSIS_RC)" != "0" \
      || "$(kv_field "$step19_driver" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step19_driver" TRIAL_PROCESS_RESULT)" != "ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT" \
      || "$(kv_field "$step19_driver" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step19_driver" DRC_COUNT_SEQUENCE)" != "6 6" \
      || "$(kv_field "$step19_driver" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step19_driver" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step19_driver" PVS)" != "NOT_RUN" \
      || "$(kv_field "$step19_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step19_analysis" RESULT)" != "ITERATIVE_MIN_AREA_TRIAL_CLASSIFIED" \
      || "$(kv_field "$step19_analysis" TRIAL_REVISION)" != "R2" \
      || "$(kv_field "$step19_analysis" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step19_analysis" TRIAL_PROCESS_RESULT)" != "ITERATIVE_MIN_AREA_REPAIR_NO_IMPROVEMENT" \
      || "$(kv_field "$step19_analysis" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step19_analysis" PRE_DRC_VIOLATION_COUNT)" != "6" \
      || "$(kv_field "$step19_analysis" FINAL_DRC_VIOLATION_COUNT)" != "6" \
      || "$(kv_field "$step19_analysis" DRC_COUNT_SEQUENCE)" != "6 6" \
      || "$(kv_field "$step19_analysis" ITERATION_COUNT)" != "1" \
      || "$(kv_field "$step19_analysis" PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step19_analysis" FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step19_analysis" PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step19_analysis" FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step19_analysis" PRE_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step19_analysis" FINAL_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step19_analysis" PRE_MARKER_DATABASE_TOTAL)" != "27" \
      || "$(kv_field "$step19_analysis" FINAL_MARKER_DATABASE_TOTAL)" != "27" \
      || "$(kv_field "$step19_analysis" COMMAND_PASS_COUNT)" != "22" \
      || "$(kv_field "$step19_analysis" COMMAND_FAIL_COUNT)" != "0" \
      || "$(kv_field "$step19_analysis" PRE_MIN_AREA_NETS)" != "n_9677 n_9693 n_9696 n_9697 n_9706 n_9721" \
      || "$(kv_field "$step19_analysis" FINAL_MIN_AREA_NETS)" != "n_9677 n_9693 n_9696 n_9697 n_9706 n_9721" \
      || "$(kv_field "$step19_analysis" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step19_analysis" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step19_analysis" PVS_DECISION)" != "DO_NOT_RUN" \
      || "$(kv_field "$step19_analysis" ERROR_COUNT)" != "0" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 19 is not the reviewed no-improvement six-marker tuple"
    echo "STEP19_STATUS=$step19_status"
    echo "STEP19_DRIVER=$step19_driver"
    echo "STEP19_ANALYSIS=$step19_analysis"
    return 1
  fi

  source_block_root="$(kv_field "$step19_driver" SOURCE_BLOCK_ROOT)"
  if [[ -z "$source_block_root" || ! -d "$source_block_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 19 source block root is missing"
    echo "SOURCE_BLOCK_ROOT=${source_block_root:-MISSING}"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  probe_id="${TX2_SESSION_ID}_min_area_geometry_probe"
  probe_root="$TX2_WORK_ROOT/diagnostics/$probe_id"
  probe_status="$probe_root/reports/min_area_geometry_probe_status.rpt"
  console="$TX2_SESSION_ROOT/logs/20_min_area_geometry_probe.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/20_min_area_geometry_probe"
  analysis_report="$TX2_SESSION_ROOT/reports/20_min_area_geometry_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/20_min_area_geometry_probe_driver.rpt"
  if [[ -e "$probe_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable Step 20 probe root already exists"
    echo "PROBE_ROOT=$probe_root"
    return 1
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi
  if [[ "$cadence_rc" == "0" ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_min_area_geometry_probe.sh $source_block_root $step19_analysis $probe_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_min_area_geometry_probe.sh" \
      "$source_block_root" \
      "$step19_analysis" \
      "$probe_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    probe_rc=$?
  fi

  mkdir -p "$copy_dir"
  if [[ -r "$probe_root/context.rpt" ]]; then
    cp -p "$probe_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$probe_root/reports" ]]; then
    for path in "$probe_root"/reports/*.rpt "$probe_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$probe_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_min_area_geometry_probe.py" \
      --probe-root "$probe_root" \
      --step19-analysis "$step19_analysis" \
      --report-driver-head "$actual_head" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ "$probe_rc" == "0" \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "MIN_AREA_LOCAL_GEOMETRY_CLASSIFIED" ]]; then
    status=PASS
    result=MIN_AREA_GEOMETRY_PROBE_CLASSIFIED_NO_DESIGN_MODIFICATION
  else
    result=MIN_AREA_GEOMETRY_CLASSIFICATION_INCOMPLETE
  fi
  topology_capture="$(kv_field "$probe_status" TOPOLOGY_CAPTURE_STATUS)"
  local_geometry_capture="$(kv_field "$analysis_report" LOCAL_GEOMETRY_CAPTURE_STATUS)"
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP19_STATUS=$step19_status"
    echo "SOURCE_STEP19_DRIVER=$step19_driver"
    echo "SOURCE_STEP19_ANALYSIS=$step19_analysis"
    echo "SOURCE_BLOCK_ROOT=$source_block_root"
    echo "PROBE_RC=$probe_rc"
    echo "PROBE_ROOT=$probe_root"
    echo "PROBE_STATUS=$probe_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "TOPOLOGY_CAPTURE_STATUS=${topology_capture:-UNKNOWN}"
    echo "LOCAL_GEOMETRY_CAPTURE_STATUS=${local_geometry_capture:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "DESIGN_MODIFICATION=NOT_RUN"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 260 "$console"
  fi
  record_status 20_min_area_geometry_probe "$status" "$analysis_rc" "$result" "$probe_root"
  [[ "$status" == "PASS" ]]
  return $?
}

min_area_landing_patch_trial() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: min-area-landing-patch-trial requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 20_min_area_geometry_probe || return 1

  local step20_status step20_driver step20_analysis source_block_root source_probe_root
  local actual_head cd_rc cadence_rc trial_id trial_root trial_status console copy_dir
  local trial_rc analysis_report analysis_rc driver_report status result path
  local trial_process_status trial_process_result method_status next_decision
  step20_status="$TX2_SESSION_ROOT/status/20_min_area_geometry_probe.rpt"
  step20_driver="$TX2_SESSION_ROOT/reports/20_min_area_geometry_probe_driver.rpt"
  step20_analysis="$TX2_SESSION_ROOT/reports/20_min_area_geometry_analysis.rpt"
  actual_head=UNKNOWN
  cadence_rc=NOT_RUN
  trial_rc=NOT_RUN
  analysis_rc=NOT_RUN
  status=FAIL
  result=MIN_AREA_LANDING_PATCH_CLASSIFICATION_NOT_RUN

  if [[ "$(kv_field "$step20_status" STATUS)" != "PASS" \
      || "$(kv_field "$step20_status" RC)" != "0" \
      || "$(kv_field "$step20_status" RESULT)" != "MIN_AREA_GEOMETRY_PROBE_CLASSIFIED_NO_DESIGN_MODIFICATION" \
      || "$(kv_field "$step20_driver" PROBE_RC)" != "0" \
      || "$(kv_field "$step20_driver" ANALYSIS_RC)" != "0" \
      || "$(kv_field "$step20_driver" TOPOLOGY_CAPTURE_STATUS)" != "PARTIAL_SCHEMA_GUIDED_LOCAL_WIRE_CAPTURE" \
      || "$(kv_field "$step20_driver" LOCAL_GEOMETRY_CAPTURE_STATUS)" != "PARTIAL_TERMINAL_OR_PIN_SHAPE_COVERAGE" \
      || "$(kv_field "$step20_driver" DESIGN_MODIFICATION)" != "NOT_RUN" \
      || "$(kv_field "$step20_driver" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step20_driver" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step20_driver" PVS)" != "NOT_RUN" \
      || "$(kv_field "$step20_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step20_analysis" RESULT)" != "MIN_AREA_LOCAL_GEOMETRY_CLASSIFIED" \
      || "$(kv_field "$step20_analysis" SELECTED_NET_REROUTE_METHOD_STATUS)" != "REJECTED_NO_IMPROVEMENT" \
      || "$(kv_field "$step20_analysis" PRE_DRC_VIOLATION_COUNT)" != "6" \
      || "$(kv_field "$step20_analysis" POST_DRC_VIOLATION_COUNT)" != "6" \
      || "$(kv_field "$step20_analysis" PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step20_analysis" POST_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step20_analysis" PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step20_analysis" POST_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step20_analysis" PRE_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step20_analysis" POST_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step20_analysis" PRE_MARKER_DATABASE_TOTAL)" != "27" \
      || "$(kv_field "$step20_analysis" POST_MARKER_DATABASE_TOTAL)" != "27" \
      || "$(kv_field "$step20_analysis" MARKER_SIGNATURE_STABILITY)" != "PASS_IDENTICAL_BEFORE_AND_AFTER_QUERY_PROBE" \
      || "$(kv_field "$step20_analysis" RESOLVED_NET_COUNT)" != "6" \
      || "$(kv_field "$step20_analysis" WIRE_QUERY_PASS_NET_COUNT)" != "6" \
      || "$(kv_field "$step20_analysis" LOCAL_WIRE_NET_COUNT)" != "6" \
      || "$(kv_field "$step20_analysis" INST_TERM_NET_COUNT)" != "6" \
      || "$(kv_field "$step20_analysis" INST_TERM_ROW_COUNT)" != "12" \
      || "$(kv_field "$step20_analysis" LOCAL_GEOMETRY_CAPTURE_STATUS)" != "PARTIAL_TERMINAL_OR_PIN_SHAPE_COVERAGE" \
      || "$(kv_field "$step20_analysis" DIRECT_GEOMETRY_TRIAL_DECISION)" != "BLOCKED_PENDING_OPERATOR_REVIEW" \
      || "$(kv_field "$step20_analysis" CANONICAL_RERUN_DECISION)" != "BLOCKED_PENDING_LOCAL_GEOMETRY_REVIEW" \
      || "$(kv_field "$step20_analysis" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step20_analysis" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step20_analysis" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$step20_analysis" PVS_DECISION)" != "DO_NOT_RUN" \
      || "$(kv_field "$step20_analysis" ERROR_COUNT)" != "0" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 20 is not the reviewed stable six-marker geometry tuple"
    echo "STEP20_STATUS=$step20_status"
    echo "STEP20_DRIVER=$step20_driver"
    echo "STEP20_ANALYSIS=$step20_analysis"
    return 1
  fi

  source_block_root="$(kv_field "$step20_driver" SOURCE_BLOCK_ROOT)"
  source_probe_root="$(kv_field "$step20_driver" PROBE_ROOT)"
  if [[ -z "$source_block_root" || ! -d "$source_block_root" \
      || -z "$source_probe_root" || ! -d "$source_probe_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 20 source roots are missing"
    echo "SOURCE_BLOCK_ROOT=${source_block_root:-MISSING}"
    echo "SOURCE_PROBE_ROOT=${source_probe_root:-MISSING}"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  trial_id="${TX2_SESSION_ID}_min_area_landing_patch_trial"
  trial_root="$TX2_WORK_ROOT/diagnostics/$trial_id"
  trial_status="$trial_root/reports/min_area_landing_patch_trial_status.rpt"
  console="$TX2_SESSION_ROOT/logs/21_min_area_landing_patch_trial.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/21_min_area_landing_patch_trial"
  analysis_report="$TX2_SESSION_ROOT/reports/21_min_area_landing_patch_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/21_min_area_landing_patch_trial_driver.rpt"
  if [[ -e "$trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable Step 21 trial root already exists"
    echo "TRIAL_ROOT=$trial_root"
    return 1
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi
  if [[ "$cadence_rc" == "0" ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    echo "COMMAND=bash TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh $source_block_root $step20_analysis $trial_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh" \
      "$source_block_root" \
      "$step20_analysis" \
      "$trial_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    trial_rc=$?
  fi

  mkdir -p "$copy_dir"
  if [[ -r "$trial_root/context.rpt" ]]; then
    cp -p "$trial_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$trial_root/reports" ]]; then
    for path in "$trial_root"/reports/*.rpt "$trial_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$trial_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_min_area_landing_patch_trial.py" \
      --trial-root "$trial_root" \
      --step20-analysis "$step20_analysis" \
      --report-driver-head "$actual_head" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ ( "$trial_rc" == "0" || "$trial_rc" == "8" ) \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED" ]]; then
    status=PASS
    result=MIN_AREA_LANDING_PATCH_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS
  else
    result=MIN_AREA_LANDING_PATCH_CLASSIFICATION_INCOMPLETE
  fi
  trial_process_status="$(kv_field "$analysis_report" TRIAL_PROCESS_STATUS)"
  trial_process_result="$(kv_field "$analysis_report" TRIAL_PROCESS_RESULT)"
  method_status="$(kv_field "$analysis_report" METHOD_STATUS)"
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP20_STATUS=$step20_status"
    echo "SOURCE_STEP20_DRIVER=$step20_driver"
    echo "SOURCE_STEP20_ANALYSIS=$step20_analysis"
    echo "SOURCE_STEP20_PROBE_ROOT=$source_probe_root"
    echo "SOURCE_BLOCK_ROOT=$source_block_root"
    echo "TRIAL_RC=$trial_rc"
    echo "TRIAL_ROOT=$trial_root"
    echo "TRIAL_STATUS=$trial_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "TRIAL_PROCESS_STATUS=${trial_process_status:-UNKNOWN}"
    echo "TRIAL_PROCESS_RESULT=${trial_process_result:-UNKNOWN}"
    echo "METHOD_STATUS=${method_status:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "DESIGN_MODIFICATION=IN_MEMORY_ONLY"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "CANONICAL_RERUN=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 280 "$console"
  fi
  record_status 21_min_area_landing_patch_trial "$status" "$analysis_rc" "$result" "$trial_root"
  [[ "$status" == "PASS" ]]
  return $?
}

min_area_landing_patch_trial_r2() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: min-area-landing-patch-trial-r2 requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 21_min_area_landing_patch_trial || return 1

  local step21_status step21_driver step21_analysis source_block_root source_trial_root
  local actual_head cd_rc cadence_rc trial_id trial_root trial_status console copy_dir
  local trial_rc analysis_report analysis_rc driver_report status result path
  local trial_process_status trial_process_result method_status next_decision patch_length_policy
  step21_status="$TX2_SESSION_ROOT/status/21_min_area_landing_patch_trial.rpt"
  step21_driver="$TX2_SESSION_ROOT/reports/21_min_area_landing_patch_trial_driver.rpt"
  step21_analysis="$TX2_SESSION_ROOT/reports/21_min_area_landing_patch_analysis.rpt"
  actual_head=UNKNOWN
  cadence_rc=NOT_RUN
  trial_rc=NOT_RUN
  analysis_rc=NOT_RUN
  status=FAIL
  result=MIN_AREA_LANDING_PATCH_R2_CLASSIFICATION_NOT_RUN

  if [[ "$(kv_field "$step21_status" STATUS)" != "PASS" \
      || "$(kv_field "$step21_status" RC)" != "0" \
      || "$(kv_field "$step21_status" RESULT)" != "MIN_AREA_LANDING_PATCH_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS" \
      || "$(kv_field "$step21_driver" TRIAL_RC)" != "8" \
      || "$(kv_field "$step21_driver" ANALYSIS_RC)" != "0" \
      || "$(kv_field "$step21_driver" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step21_driver" TRIAL_PROCESS_RESULT)" != "SIX_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$step21_driver" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step21_driver" DESIGN_MODIFICATION)" != "IN_MEMORY_ONLY" \
      || "$(kv_field "$step21_driver" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step21_driver" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step21_driver" CANONICAL_RERUN)" != "NOT_RUN" \
      || "$(kv_field "$step21_driver" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$step21_driver" PVS)" != "NOT_RUN" \
      || "$(kv_field "$step21_analysis" LABEL)" != "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS" \
      || "$(kv_field "$step21_analysis" POLICY)" != "ISOLATED_IN_MEMORY_SIX_NET_MET1_LANDING_PATCH_CLASSIFICATION" \
      || "$(kv_field "$step21_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step21_analysis" RESULT)" != "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED" \
      || "$(kv_field "$step21_analysis" REPORT_DRIVER_HEAD)" != "$(kv_field "$step21_driver" REPORT_DRIVER_HEAD)" \
      || "$(kv_field "$step21_analysis" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step21_analysis" TRIAL_PROCESS_RESULT)" != "SIX_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$step21_analysis" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step21_analysis" PATCH_CONTRACT_STATUS)" != "PASS_EXACT_SIX_REVIEWED_EXTENSIONS" \
      || "$(kv_field "$step21_analysis" PATCH_WIDTH_UM)" != "0.28" \
      || "$(kv_field "$step21_analysis" PATCH_LENGTH_UM)" != "0.56" \
      || "$(kv_field "$step21_analysis" PATCH_ATTEMPTED_COUNT)" != "6" \
      || "$(kv_field "$step21_analysis" PATCH_APPLIED_COUNT)" != "6" \
      || "$(kv_field "$step21_analysis" COMMAND_PASS_COUNT)" != "24" \
      || "$(kv_field "$step21_analysis" COMMAND_FAIL_COUNT)" != "0" \
      || "$(kv_field "$step21_analysis" PRE_DRC_VIOLATION_COUNT)" != "6" \
      || "$(kv_field "$step21_analysis" FINAL_DRC_VIOLATION_COUNT)" != "4" \
      || "$(kv_field "$step21_analysis" PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step21_analysis" FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step21_analysis" PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step21_analysis" FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step21_analysis" PRE_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step21_analysis" FINAL_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step21_analysis" PRE_MARKER_DATABASE_TOTAL)" != "27" \
      || "$(kv_field "$step21_analysis" FINAL_MARKER_DATABASE_TOTAL)" != "25" \
      || "$(kv_field "$step21_analysis" REMOVED_MARKER_SIGNATURE_COUNT)" != "6" \
      || "$(kv_field "$step21_analysis" ADDED_MARKER_SIGNATURE_COUNT)" != "4" \
      || "$(kv_field "$step21_analysis" FINAL_MIN_AREA_NETS)" != "n_9677 n_9693 n_9696 n_9697" \
      || "$(kv_field "$step21_analysis" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step21_analysis" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step21_analysis" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$step21_analysis" PVS_DECISION)" != "DO_NOT_RUN" \
      || "$(kv_field "$step21_analysis" CANONICAL_RERUN_DECISION)" != "DO_NOT_RUN_FROM_THIS_STEP" \
      || "$(kv_field "$step21_analysis" NEXT_METHOD_DECISION)" != "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD" \
      || "$(kv_field "$step21_analysis" ERROR_COUNT)" != "0" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 21 is not the reviewed four-survivor landing-patch tuple"
    echo "STEP21_STATUS=$step21_status"
    echo "STEP21_DRIVER=$step21_driver"
    echo "STEP21_ANALYSIS=$step21_analysis"
    return 1
  fi

  source_block_root="$(kv_field "$step21_driver" SOURCE_BLOCK_ROOT)"
  source_trial_root="$(kv_field "$step21_driver" TRIAL_ROOT)"
  if [[ -z "$source_block_root" || ! -d "$source_block_root" \
      || -z "$source_trial_root" || ! -d "$source_trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 21 source roots are missing"
    echo "SOURCE_BLOCK_ROOT=${source_block_root:-MISSING}"
    echo "SOURCE_STEP21_TRIAL_ROOT=${source_trial_root:-MISSING}"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  trial_id="${TX2_SESSION_ID}_min_area_landing_patch_trial_r2"
  trial_root="$TX2_WORK_ROOT/diagnostics/$trial_id"
  trial_status="$trial_root/reports/min_area_landing_patch_trial_status.rpt"
  console="$TX2_SESSION_ROOT/logs/22_min_area_landing_patch_trial_r2.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/22_min_area_landing_patch_trial_r2"
  analysis_report="$TX2_SESSION_ROOT/reports/22_min_area_landing_patch_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/22_min_area_landing_patch_trial_driver.rpt"
  if [[ -e "$trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable Step 22 trial root already exists"
    echo "TRIAL_ROOT=$trial_root"
    return 1
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi
  if [[ "$cadence_rc" == "0" ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    export SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R2
    echo "COMMAND=SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R2 bash TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh $source_block_root $step21_analysis $trial_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh" \
      "$source_block_root" \
      "$step21_analysis" \
      "$trial_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    trial_rc=$?
  fi

  mkdir -p "$copy_dir"
  if [[ -r "$trial_root/context.rpt" ]]; then
    cp -p "$trial_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$trial_root/reports" ]]; then
    for path in "$trial_root"/reports/*.rpt "$trial_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$trial_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_min_area_landing_patch_trial.py" \
      --trial-root "$trial_root" \
      --step21-analysis "$step21_analysis" \
      --trial-revision R2 \
      --report-driver-head "$actual_head" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ ( "$trial_rc" == "0" || "$trial_rc" == "8" ) \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED" \
      && "$(kv_field "$analysis_report" TRIAL_REVISION)" == "R2" ]]; then
    status=PASS
    result=MIN_AREA_LANDING_PATCH_R2_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS
  else
    result=MIN_AREA_LANDING_PATCH_R2_CLASSIFICATION_INCOMPLETE
  fi
  trial_process_status="$(kv_field "$analysis_report" TRIAL_PROCESS_STATUS)"
  trial_process_result="$(kv_field "$analysis_report" TRIAL_PROCESS_RESULT)"
  method_status="$(kv_field "$analysis_report" METHOD_STATUS)"
  patch_length_policy="$(kv_field "$analysis_report" PATCH_LENGTH_POLICY)"
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP21_STATUS=$step21_status"
    echo "SOURCE_STEP21_DRIVER=$step21_driver"
    echo "SOURCE_STEP21_ANALYSIS=$step21_analysis"
    echo "SOURCE_STEP21_TRIAL_ROOT=$source_trial_root"
    echo "SOURCE_BLOCK_ROOT=$source_block_root"
    echo "TRIAL_REVISION=R2"
    echo "TRIAL_RC=$trial_rc"
    echo "TRIAL_ROOT=$trial_root"
    echo "TRIAL_STATUS=$trial_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "TRIAL_PROCESS_STATUS=${trial_process_status:-UNKNOWN}"
    echo "TRIAL_PROCESS_RESULT=${trial_process_result:-UNKNOWN}"
    echo "METHOD_STATUS=${method_status:-UNKNOWN}"
    echo "PATCH_LENGTH_POLICY=${patch_length_policy:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "DESIGN_MODIFICATION=IN_MEMORY_ONLY"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "CANONICAL_RERUN=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 280 "$console"
  fi
  record_status 22_min_area_landing_patch_trial_r2 "$status" "$analysis_rc" "$result" "$trial_root"
  [[ "$status" == "PASS" ]]
  return $?
}

min_area_landing_patch_trial_r3() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: min-area-landing-patch-trial-r3 requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 22_min_area_landing_patch_trial_r2 || return 1

  local step22_status step22_driver step22_analysis source_block_root source_trial_root
  local step21_post_markers step22_post_markers step21_signature step22_signature
  local step22_area_count saturation_status actual_head cd_rc cadence_rc trial_id
  local trial_root trial_status console copy_dir trial_rc analysis_report analysis_rc
  local driver_report status result path trial_process_status trial_process_result
  local method_status next_decision patch_direction_policy
  step22_status="$TX2_SESSION_ROOT/status/22_min_area_landing_patch_trial_r2.rpt"
  step22_driver="$TX2_SESSION_ROOT/reports/22_min_area_landing_patch_trial_driver.rpt"
  step22_analysis="$TX2_SESSION_ROOT/reports/22_min_area_landing_patch_analysis.rpt"
  step21_post_markers="$TX2_SESSION_ROOT/reports/21_min_area_landing_patch_trial/drc_markers_post_trial.tsv"
  step22_post_markers="$TX2_SESSION_ROOT/reports/22_min_area_landing_patch_trial_r2/drc_markers_post_trial.tsv"
  actual_head=UNKNOWN
  cadence_rc=NOT_RUN
  trial_rc=NOT_RUN
  analysis_rc=NOT_RUN
  status=FAIL
  result=MIN_AREA_LANDING_PATCH_R3_CLASSIFICATION_NOT_RUN
  saturation_status=FAIL

  if [[ "$(kv_field "$step22_status" STATUS)" != "PASS" \
      || "$(kv_field "$step22_status" RC)" != "0" \
      || "$(kv_field "$step22_status" RESULT)" != "MIN_AREA_LANDING_PATCH_R2_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS" \
      || "$(kv_field "$step22_status" HEAD_EXPECTED)" != "$TX2_EXPECTED_HEAD" \
      || "$(kv_field "$step22_status" SESSION_ROOT)" != "$TX2_SESSION_ROOT" \
      || "$(kv_field "$step22_driver" SOURCE_ARTIFACT_HEAD)" != "$TX2_EXPECTED_HEAD" \
      || "$(kv_field "$step22_driver" EXPECTED_REPORT_DRIVER_HEAD)" != "$(kv_field "$step22_driver" REPORT_DRIVER_HEAD)" \
      || "$(kv_field "$step22_driver" TRIAL_REVISION)" != "R2" \
      || "$(kv_field "$step22_driver" TRIAL_RC)" != "8" \
      || "$(kv_field "$step22_driver" ANALYSIS_RC)" != "0" \
      || "$(kv_field "$step22_driver" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step22_driver" TRIAL_PROCESS_RESULT)" != "MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$step22_driver" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step22_driver" PATCH_LENGTH_POLICY)" != "FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56" \
      || "$(kv_field "$step22_driver" DESIGN_MODIFICATION)" != "IN_MEMORY_ONLY" \
      || "$(kv_field "$step22_driver" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step22_driver" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step22_driver" CANONICAL_RERUN)" != "NOT_RUN" \
      || "$(kv_field "$step22_driver" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$step22_driver" PVS)" != "NOT_RUN" \
      || "$(kv_field "$step22_analysis" LABEL)" != "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS" \
      || "$(kv_field "$step22_analysis" POLICY)" != "ISOLATED_IN_MEMORY_SIX_NET_MIXED_LENGTH_MET1_LANDING_PATCH_CLASSIFICATION" \
      || "$(kv_field "$step22_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step22_analysis" RESULT)" != "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED" \
      || "$(kv_field "$step22_analysis" TRIAL_ROOT)" != "$(kv_field "$step22_driver" TRIAL_ROOT)" \
      || "$(kv_field "$step22_analysis" REPORT_DRIVER_HEAD)" != "$(kv_field "$step22_driver" REPORT_DRIVER_HEAD)" \
      || "$(kv_field "$step22_analysis" TRIAL_REVISION)" != "R2" \
      || "$(kv_field "$step22_analysis" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step22_analysis" TRIAL_PROCESS_RESULT)" != "MIXED_LENGTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$step22_analysis" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step22_analysis" PATCH_CONTRACT_STATUS)" != "PASS_EXACT_SIX_MIXED_LENGTH_EXTENSIONS" \
      || "$(kv_field "$step22_analysis" PATCH_WIDTH_UM)" != "0.28" \
      || "$(kv_field "$step22_analysis" PATCH_LENGTH_POLICY)" != "FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56" \
      || "$(kv_field "$step22_analysis" PATCH_LENGTH_UM)" != "MIXED_0.56_0.84" \
      || "$(kv_field "$step22_analysis" PATCH_ATTEMPTED_COUNT)" != "6" \
      || "$(kv_field "$step22_analysis" PATCH_APPLIED_COUNT)" != "6" \
      || "$(kv_field "$step22_analysis" COMMAND_PASS_COUNT)" != "24" \
      || "$(kv_field "$step22_analysis" COMMAND_FAIL_COUNT)" != "0" \
      || "$(kv_field "$step22_analysis" PRE_DRC_VIOLATION_COUNT)" != "6" \
      || "$(kv_field "$step22_analysis" FINAL_DRC_VIOLATION_COUNT)" != "4" \
      || "$(kv_field "$step22_analysis" PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step22_analysis" FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step22_analysis" PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step22_analysis" FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step22_analysis" PRE_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step22_analysis" FINAL_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step22_analysis" PRE_MARKER_DATABASE_TOTAL)" != "27" \
      || "$(kv_field "$step22_analysis" FINAL_MARKER_DATABASE_TOTAL)" != "25" \
      || "$(kv_field "$step22_analysis" REMOVED_MARKER_SIGNATURE_COUNT)" != "6" \
      || "$(kv_field "$step22_analysis" ADDED_MARKER_SIGNATURE_COUNT)" != "4" \
      || "$(kv_field "$step22_analysis" FINAL_MIN_AREA_NETS)" != "n_9677 n_9693 n_9696 n_9697" \
      || "$(kv_field "$step22_analysis" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step22_analysis" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step22_analysis" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$step22_analysis" PVS_DECISION)" != "DO_NOT_RUN" \
      || "$(kv_field "$step22_analysis" CANONICAL_RERUN_DECISION)" != "DO_NOT_RUN_FROM_THIS_STEP" \
      || "$(kv_field "$step22_analysis" NEXT_METHOD_DECISION)" != "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD" \
      || "$(kv_field "$step22_analysis" ERROR_COUNT)" != "0" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 22 is not the reviewed four-survivor length-saturation tuple"
    echo "STEP22_STATUS=$step22_status"
    echo "STEP22_DRIVER=$step22_driver"
    echo "STEP22_ANALYSIS=$step22_analysis"
    return 1
  fi

  if [[ ! -r "$step21_post_markers" || ! -r "$step22_post_markers" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 21/22 marker evidence is missing"
    echo "STEP21_POST_MARKERS=$step21_post_markers"
    echo "STEP22_POST_MARKERS=$step22_post_markers"
    return 1
  fi
  step21_signature="$(normalized_marker_signature_sha256 "$step21_post_markers")"
  step22_signature="$(normalized_marker_signature_sha256 "$step22_post_markers")"
  step22_area_count="$(grep -cF "Actual: 0.17770000 Required: 0.20200000" "$step22_post_markers" 2>/dev/null)"
  if [[ -z "$step21_signature" || "$step21_signature" != "$step22_signature" \
      || "$step22_area_count" != "4" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 22 did not reproduce the Step 21 semantic marker signatures"
    echo "STEP21_POST_MARKER_SIGNATURE_SHA256=${step21_signature:-MISSING}"
    echo "STEP22_POST_MARKER_SIGNATURE_SHA256=${step22_signature:-MISSING}"
    echo "STEP22_0P1777_MARKER_COUNT=${step22_area_count:-MISSING}"
    return 1
  fi
  saturation_status=PASS_IDENTICAL_SEMANTIC_SIGNATURES

  source_block_root="$(kv_field "$step22_driver" SOURCE_BLOCK_ROOT)"
  source_trial_root="$(kv_field "$step22_driver" TRIAL_ROOT)"
  if [[ -z "$source_block_root" || ! -d "$source_block_root" \
      || -z "$source_trial_root" || ! -d "$source_trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 22 source roots are missing"
    echo "SOURCE_BLOCK_ROOT=${source_block_root:-MISSING}"
    echo "SOURCE_STEP22_TRIAL_ROOT=${source_trial_root:-MISSING}"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  trial_id="${TX2_SESSION_ID}_min_area_landing_patch_trial_r3"
  trial_root="$TX2_WORK_ROOT/diagnostics/$trial_id"
  trial_status="$trial_root/reports/min_area_landing_patch_trial_status.rpt"
  console="$TX2_SESSION_ROOT/logs/23_min_area_landing_patch_trial_r3.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/23_min_area_landing_patch_trial_r3"
  analysis_report="$TX2_SESSION_ROOT/reports/23_min_area_landing_patch_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/23_min_area_landing_patch_trial_driver.rpt"
  if [[ -e "$trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable Step 23 trial root already exists"
    echo "TRIAL_ROOT=$trial_root"
    return 1
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi
  if [[ "$cadence_rc" == "0" ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    export SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R3
    echo "COMMAND=SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R3 bash TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh $source_block_root $step22_analysis $trial_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh" \
      "$source_block_root" \
      "$step22_analysis" \
      "$trial_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    trial_rc=$?
  fi

  mkdir -p "$copy_dir"
  if [[ -r "$trial_root/context.rpt" ]]; then
    cp -p "$trial_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$trial_root/reports" ]]; then
    for path in "$trial_root"/reports/*.rpt "$trial_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$trial_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_min_area_landing_patch_trial.py" \
      --trial-root "$trial_root" \
      --step22-analysis "$step22_analysis" \
      --trial-revision R3 \
      --report-driver-head "$actual_head" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ ( "$trial_rc" == "0" || "$trial_rc" == "8" ) \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED" \
      && "$(kv_field "$analysis_report" TRIAL_REVISION)" == "R3" ]]; then
    status=PASS
    result=MIN_AREA_LANDING_PATCH_R3_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS
  else
    result=MIN_AREA_LANDING_PATCH_R3_CLASSIFICATION_INCOMPLETE
  fi
  trial_process_status="$(kv_field "$analysis_report" TRIAL_PROCESS_STATUS)"
  trial_process_result="$(kv_field "$analysis_report" TRIAL_PROCESS_RESULT)"
  method_status="$(kv_field "$analysis_report" METHOD_STATUS)"
  patch_direction_policy="$(kv_field "$analysis_report" PATCH_DIRECTION_POLICY)"
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP22_STATUS=$step22_status"
    echo "SOURCE_STEP22_DRIVER=$step22_driver"
    echo "SOURCE_STEP22_ANALYSIS=$step22_analysis"
    echo "SOURCE_STEP22_TRIAL_ROOT=$source_trial_root"
    echo "SOURCE_BLOCK_ROOT=$source_block_root"
    echo "STEP21_POST_MARKER_SIGNATURE_SHA256=$step21_signature"
    echo "STEP22_POST_MARKER_SIGNATURE_SHA256=$step22_signature"
    echo "STEP22_0P1777_MARKER_COUNT=$step22_area_count"
    echo "SOURCE_SATURATION_SIGNATURE_STATUS=$saturation_status"
    echo "TRIAL_REVISION=R3"
    echo "TRIAL_RC=$trial_rc"
    echo "TRIAL_ROOT=$trial_root"
    echo "TRIAL_STATUS=$trial_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "TRIAL_PROCESS_STATUS=${trial_process_status:-UNKNOWN}"
    echo "TRIAL_PROCESS_RESULT=${trial_process_result:-UNKNOWN}"
    echo "METHOD_STATUS=${method_status:-UNKNOWN}"
    echo "PATCH_DIRECTION_POLICY=${patch_direction_policy:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "DESIGN_MODIFICATION=IN_MEMORY_ONLY"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "CANONICAL_RERUN=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 300 "$console"
  fi
  record_status 23_min_area_landing_patch_trial_r3 "$status" "$analysis_rc" "$result" "$trial_root"
  [[ "$status" == "PASS" ]]
  return $?
}

min_area_landing_patch_trial_r4() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: min-area-landing-patch-trial-r4 requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 23_min_area_landing_patch_trial_r3 || return 1

  local step23_status step23_driver step23_analysis source_block_root source_trial_root
  local step23_pre_markers step23_post_markers survivor_pattern
  local step23_pre_survivor_signature step23_post_signature step23_area_count
  local width_precondition_status actual_head cd_rc cadence_rc trial_id
  local trial_root trial_status console copy_dir trial_rc analysis_report analysis_rc
  local driver_report status result path trial_process_status trial_process_result
  local method_status next_decision patch_width_policy
  step23_status="$TX2_SESSION_ROOT/status/23_min_area_landing_patch_trial_r3.rpt"
  step23_driver="$TX2_SESSION_ROOT/reports/23_min_area_landing_patch_trial_driver.rpt"
  step23_analysis="$TX2_SESSION_ROOT/reports/23_min_area_landing_patch_analysis.rpt"
  step23_pre_markers="$TX2_SESSION_ROOT/reports/23_min_area_landing_patch_trial_r3/drc_markers_pre_trial.tsv"
  step23_post_markers="$TX2_SESSION_ROOT/reports/23_min_area_landing_patch_trial_r3/drc_markers_post_trial.tsv"
  survivor_pattern='n_9677|n_9693|n_9696|n_9697'
  actual_head=UNKNOWN
  cadence_rc=NOT_RUN
  trial_rc=NOT_RUN
  analysis_rc=NOT_RUN
  status=FAIL
  result=MIN_AREA_LANDING_PATCH_R4_CLASSIFICATION_NOT_RUN
  width_precondition_status=FAIL

  if [[ "$(kv_field "$step23_status" STATUS)" != "PASS" \
      || "$(kv_field "$step23_status" RC)" != "0" \
      || "$(kv_field "$step23_status" RESULT)" != "MIN_AREA_LANDING_PATCH_R3_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS" \
      || "$(kv_field "$step23_status" HEAD_EXPECTED)" != "$TX2_EXPECTED_HEAD" \
      || "$(kv_field "$step23_status" SESSION_ROOT)" != "$TX2_SESSION_ROOT" \
      || "$(kv_field "$step23_driver" SOURCE_ARTIFACT_HEAD)" != "$TX2_EXPECTED_HEAD" \
      || "$(kv_field "$step23_driver" EXPECTED_REPORT_DRIVER_HEAD)" != "$(kv_field "$step23_driver" REPORT_DRIVER_HEAD)" \
      || "$(kv_field "$step23_driver" TRIAL_REVISION)" != "R3" \
      || "$(kv_field "$step23_driver" TRIAL_RC)" != "8" \
      || "$(kv_field "$step23_driver" ANALYSIS_RC)" != "0" \
      || "$(kv_field "$step23_driver" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step23_driver" TRIAL_PROCESS_RESULT)" != "MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$step23_driver" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step23_driver" PATCH_DIRECTION_POLICY)" != "FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE" \
      || "$(kv_field "$step23_driver" DESIGN_MODIFICATION)" != "IN_MEMORY_ONLY" \
      || "$(kv_field "$step23_driver" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step23_driver" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step23_driver" CANONICAL_RERUN)" != "NOT_RUN" \
      || "$(kv_field "$step23_driver" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$step23_driver" PVS)" != "NOT_RUN" \
      || "$(kv_field "$step23_analysis" LABEL)" != "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS" \
      || "$(kv_field "$step23_analysis" POLICY)" != "ISOLATED_IN_MEMORY_SIX_NET_MIXED_DIRECTION_MET1_LANDING_PATCH_CLASSIFICATION" \
      || "$(kv_field "$step23_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step23_analysis" RESULT)" != "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED" \
      || "$(kv_field "$step23_analysis" TRIAL_ROOT)" != "$(kv_field "$step23_driver" TRIAL_ROOT)" \
      || "$(kv_field "$step23_analysis" REPORT_DRIVER_HEAD)" != "$(kv_field "$step23_driver" REPORT_DRIVER_HEAD)" \
      || "$(kv_field "$step23_analysis" TRIAL_REVISION)" != "R3" \
      || "$(kv_field "$step23_analysis" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step23_analysis" TRIAL_PROCESS_RESULT)" != "MIXED_DIRECTION_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$step23_analysis" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step23_analysis" PATCH_CONTRACT_STATUS)" != "PASS_EXACT_SIX_MIXED_DIRECTION_EXTENSIONS" \
      || "$(kv_field "$step23_analysis" PATCH_WIDTH_UM)" != "0.28" \
      || "$(kv_field "$step23_analysis" PATCH_LENGTH_POLICY)" != "FOUR_SURVIVORS_0.84_TWO_CLOSED_0.56" \
      || "$(kv_field "$step23_analysis" PATCH_LENGTH_UM)" != "MIXED_0.56_0.84" \
      || "$(kv_field "$step23_analysis" PATCH_DIRECTION_POLICY)" != "FOUR_SURVIVORS_AWAY_FROM_SOURCE_TWO_CLOSED_TOWARD_SOURCE" \
      || "$(kv_field "$step23_analysis" PATCH_ATTEMPTED_COUNT)" != "6" \
      || "$(kv_field "$step23_analysis" PATCH_APPLIED_COUNT)" != "6" \
      || "$(kv_field "$step23_analysis" COMMAND_PASS_COUNT)" != "24" \
      || "$(kv_field "$step23_analysis" COMMAND_FAIL_COUNT)" != "0" \
      || "$(kv_field "$step23_analysis" PRE_DRC_VIOLATION_COUNT)" != "6" \
      || "$(kv_field "$step23_analysis" FINAL_DRC_VIOLATION_COUNT)" != "4" \
      || "$(kv_field "$step23_analysis" PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step23_analysis" FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step23_analysis" PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step23_analysis" FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step23_analysis" PRE_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step23_analysis" FINAL_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step23_analysis" PRE_MARKER_DATABASE_TOTAL)" != "27" \
      || "$(kv_field "$step23_analysis" FINAL_MARKER_DATABASE_TOTAL)" != "25" \
      || "$(kv_field "$step23_analysis" REMOVED_MARKER_SIGNATURE_COUNT)" != "2" \
      || "$(kv_field "$step23_analysis" ADDED_MARKER_SIGNATURE_COUNT)" != "0" \
      || "$(kv_field "$step23_analysis" FINAL_MIN_AREA_NETS)" != "n_9677 n_9693 n_9696 n_9697" \
      || "$(kv_field "$step23_analysis" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step23_analysis" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step23_analysis" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$step23_analysis" PVS_DECISION)" != "DO_NOT_RUN" \
      || "$(kv_field "$step23_analysis" CANONICAL_RERUN_DECISION)" != "DO_NOT_RUN_FROM_THIS_STEP" \
      || "$(kv_field "$step23_analysis" NEXT_METHOD_DECISION)" != "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD" \
      || "$(kv_field "$step23_analysis" ERROR_COUNT)" != "0" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 23 is not the reviewed four-survivor direction tuple"
    echo "STEP23_STATUS=$step23_status"
    echo "STEP23_DRIVER=$step23_driver"
    echo "STEP23_ANALYSIS=$step23_analysis"
    return 1
  fi

  if [[ ! -r "$step23_pre_markers" || ! -r "$step23_post_markers" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 23 marker evidence is missing"
    echo "STEP23_PRE_MARKERS=$step23_pre_markers"
    echo "STEP23_POST_MARKERS=$step23_post_markers"
    return 1
  fi
  step23_pre_survivor_signature="$(normalized_marker_signature_sha256 "$step23_pre_markers" "$survivor_pattern")"
  step23_post_signature="$(normalized_marker_signature_sha256 "$step23_post_markers")"
  step23_area_count="$(grep -cF "Actual: 0.10640000 Required: 0.20200000" "$step23_post_markers" 2>/dev/null)"
  if [[ -z "$step23_pre_survivor_signature" \
      || "$step23_pre_survivor_signature" != "$step23_post_signature" \
      || "$step23_area_count" != "4" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 23 survivors are not the four original min-area signatures"
    echo "STEP23_PRE_SURVIVOR_SIGNATURE_SHA256=${step23_pre_survivor_signature:-MISSING}"
    echo "STEP23_POST_MARKER_SIGNATURE_SHA256=${step23_post_signature:-MISSING}"
    echo "STEP23_0P1064_MARKER_COUNT=${step23_area_count:-MISSING}"
    return 1
  fi
  width_precondition_status=PASS_FOUR_ORIGINAL_SURVIVOR_SIGNATURES

  source_block_root="$(kv_field "$step23_driver" SOURCE_BLOCK_ROOT)"
  source_trial_root="$(kv_field "$step23_driver" TRIAL_ROOT)"
  if [[ -z "$source_block_root" || ! -d "$source_block_root" \
      || -z "$source_trial_root" || ! -d "$source_trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 23 source roots are missing"
    echo "SOURCE_BLOCK_ROOT=${source_block_root:-MISSING}"
    echo "SOURCE_STEP23_TRIAL_ROOT=${source_trial_root:-MISSING}"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  trial_id="${TX2_SESSION_ID}_min_area_landing_patch_trial_r4"
  trial_root="$TX2_WORK_ROOT/diagnostics/$trial_id"
  trial_status="$trial_root/reports/min_area_landing_patch_trial_status.rpt"
  console="$TX2_SESSION_ROOT/logs/24_min_area_landing_patch_trial_r4.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/24_min_area_landing_patch_trial_r4"
  analysis_report="$TX2_SESSION_ROOT/reports/24_min_area_landing_patch_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/24_min_area_landing_patch_trial_driver.rpt"
  if [[ -e "$trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable Step 24 trial root already exists"
    echo "TRIAL_ROOT=$trial_root"
    return 1
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi
  if [[ "$cadence_rc" == "0" ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    export SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R4
    echo "COMMAND=SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R4 bash TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh $source_block_root $step23_analysis $trial_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh" \
      "$source_block_root" \
      "$step23_analysis" \
      "$trial_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    trial_rc=$?
  fi

  mkdir -p "$copy_dir"
  if [[ -r "$trial_root/context.rpt" ]]; then
    cp -p "$trial_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$trial_root/reports" ]]; then
    for path in "$trial_root"/reports/*.rpt "$trial_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$trial_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_min_area_landing_patch_trial.py" \
      --trial-root "$trial_root" \
      --step23-analysis "$step23_analysis" \
      --trial-revision R4 \
      --report-driver-head "$actual_head" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  if [[ ( "$trial_rc" == "0" || "$trial_rc" == "8" ) \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED" \
      && "$(kv_field "$analysis_report" TRIAL_REVISION)" == "R4" ]]; then
    status=PASS
    result=MIN_AREA_LANDING_PATCH_R4_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS
  else
    result=MIN_AREA_LANDING_PATCH_R4_CLASSIFICATION_INCOMPLETE
  fi
  trial_process_status="$(kv_field "$analysis_report" TRIAL_PROCESS_STATUS)"
  trial_process_result="$(kv_field "$analysis_report" TRIAL_PROCESS_RESULT)"
  method_status="$(kv_field "$analysis_report" METHOD_STATUS)"
  patch_width_policy="$(kv_field "$analysis_report" PATCH_WIDTH_POLICY)"
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP23_STATUS=$step23_status"
    echo "SOURCE_STEP23_DRIVER=$step23_driver"
    echo "SOURCE_STEP23_ANALYSIS=$step23_analysis"
    echo "SOURCE_STEP23_TRIAL_ROOT=$source_trial_root"
    echo "SOURCE_BLOCK_ROOT=$source_block_root"
    echo "STEP23_PRE_SURVIVOR_SIGNATURE_SHA256=$step23_pre_survivor_signature"
    echo "STEP23_POST_MARKER_SIGNATURE_SHA256=$step23_post_signature"
    echo "STEP23_0P1064_MARKER_COUNT=$step23_area_count"
    echo "SOURCE_WIDTH_PRECONDITION_STATUS=$width_precondition_status"
    echo "TRIAL_REVISION=R4"
    echo "TRIAL_RC=$trial_rc"
    echo "TRIAL_ROOT=$trial_root"
    echo "TRIAL_STATUS=$trial_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "TRIAL_PROCESS_STATUS=${trial_process_status:-UNKNOWN}"
    echo "TRIAL_PROCESS_RESULT=${trial_process_result:-UNKNOWN}"
    echo "METHOD_STATUS=${method_status:-UNKNOWN}"
    echo "PATCH_WIDTH_POLICY=${patch_width_policy:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "DESIGN_MODIFICATION=IN_MEMORY_ONLY"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "CANONICAL_RERUN=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 320 "$console"
  fi
  record_status 24_min_area_landing_patch_trial_r4 "$status" "$analysis_rc" "$result" "$trial_root"
  [[ "$status" == "PASS" ]]
  return $?
}

min_area_landing_materialization_probe() {
  local expected_report_driver_head="$1"
  if [[ -z "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: min-area-landing-materialization-probe requires the expected report-driver HEAD"
    return 1
  fi
  load_session || return 1
  require_step_pass 24_min_area_landing_patch_trial_r4 || return 1

  local step24_status step24_driver step24_analysis source_block_root source_trial_root
  local step21_post_markers step24_post_markers step21_post_signature
  local step24_post_signature step24_area_count saturation_status
  local actual_head cd_rc cadence_rc trial_id trial_root trial_status console copy_dir
  local trial_rc analysis_report analysis_rc driver_report status result path
  local trial_process_status trial_process_result method_status capture_status
  local materialization_status next_decision materialization_class_ok
  step24_status="$TX2_SESSION_ROOT/status/24_min_area_landing_patch_trial_r4.rpt"
  step24_driver="$TX2_SESSION_ROOT/reports/24_min_area_landing_patch_trial_driver.rpt"
  step24_analysis="$TX2_SESSION_ROOT/reports/24_min_area_landing_patch_analysis.rpt"
  step21_post_markers="$TX2_SESSION_ROOT/reports/21_min_area_landing_patch_trial/drc_markers_post_trial.tsv"
  step24_post_markers="$TX2_SESSION_ROOT/reports/24_min_area_landing_patch_trial_r4/drc_markers_post_trial.tsv"
  actual_head=UNKNOWN
  cadence_rc=NOT_RUN
  trial_rc=NOT_RUN
  analysis_rc=NOT_RUN
  status=FAIL
  result=MIN_AREA_LANDING_MATERIALIZATION_CLASSIFICATION_NOT_RUN
  saturation_status=FAIL
  materialization_class_ok=NO

  if [[ "$(kv_field "$step24_status" STATUS)" != "PASS" \
      || "$(kv_field "$step24_status" RC)" != "0" \
      || "$(kv_field "$step24_status" RESULT)" != "MIN_AREA_LANDING_PATCH_R4_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS" \
      || "$(kv_field "$step24_status" HEAD_EXPECTED)" != "$TX2_EXPECTED_HEAD" \
      || "$(kv_field "$step24_status" SESSION_ROOT)" != "$TX2_SESSION_ROOT" \
      || "$(kv_field "$step24_driver" SOURCE_ARTIFACT_HEAD)" != "$TX2_EXPECTED_HEAD" \
      || "$(kv_field "$step24_driver" EXPECTED_REPORT_DRIVER_HEAD)" != "$(kv_field "$step24_driver" REPORT_DRIVER_HEAD)" \
      || "$(kv_field "$step24_driver" TRIAL_REVISION)" != "R4" \
      || "$(kv_field "$step24_driver" TRIAL_RC)" != "8" \
      || "$(kv_field "$step24_driver" ANALYSIS_RC)" != "0" \
      || "$(kv_field "$step24_driver" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step24_driver" TRIAL_PROCESS_RESULT)" != "MIXED_WIDTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$step24_driver" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step24_driver" PATCH_WIDTH_POLICY)" != "FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28" \
      || "$(kv_field "$step24_driver" DESIGN_MODIFICATION)" != "IN_MEMORY_ONLY" \
      || "$(kv_field "$step24_driver" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step24_driver" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step24_driver" CANONICAL_RERUN)" != "NOT_RUN" \
      || "$(kv_field "$step24_driver" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$step24_driver" PVS)" != "NOT_RUN" \
      || "$(kv_field "$step24_analysis" LABEL)" != "SPADMIC_TX_PACKET_MIN_AREA_LANDING_PATCH_ANALYSIS" \
      || "$(kv_field "$step24_analysis" POLICY)" != "ISOLATED_IN_MEMORY_SIX_NET_MIXED_WIDTH_MET1_LANDING_PATCH_CLASSIFICATION" \
      || "$(kv_field "$step24_analysis" STATUS)" != "PASS" \
      || "$(kv_field "$step24_analysis" RESULT)" != "MIN_AREA_LANDING_PATCH_TRIAL_CLASSIFIED" \
      || "$(kv_field "$step24_analysis" TRIAL_ROOT)" != "$(kv_field "$step24_driver" TRIAL_ROOT)" \
      || "$(kv_field "$step24_analysis" REPORT_DRIVER_HEAD)" != "$(kv_field "$step24_driver" REPORT_DRIVER_HEAD)" \
      || "$(kv_field "$step24_analysis" TRIAL_REVISION)" != "R4" \
      || "$(kv_field "$step24_analysis" TRIAL_PROCESS_STATUS)" != "FAIL" \
      || "$(kv_field "$step24_analysis" TRIAL_PROCESS_RESULT)" != "MIXED_WIDTH_MET1_LANDING_EXTENSIONS_CHANGED_NOT_CLOSED" \
      || "$(kv_field "$step24_analysis" METHOD_STATUS)" != "REJECTED_OR_INCOMPLETE" \
      || "$(kv_field "$step24_analysis" PATCH_CONTRACT_STATUS)" != "PASS_EXACT_SIX_MIXED_WIDTH_EXTENSIONS" \
      || "$(kv_field "$step24_analysis" PATCH_WIDTH_POLICY)" != "FOUR_SURVIVORS_0.56_TWO_CLOSED_0.28" \
      || "$(kv_field "$step24_analysis" PATCH_WIDTH_UM)" != "MIXED_0.28_0.56" \
      || "$(kv_field "$step24_analysis" PATCH_LENGTH_POLICY)" != "UNIFORM_0.56" \
      || "$(kv_field "$step24_analysis" PATCH_LENGTH_UM)" != "0.56" \
      || "$(kv_field "$step24_analysis" PATCH_DIRECTION_POLICY)" != "ALL_TOWARD_SOURCE" \
      || "$(kv_field "$step24_analysis" PATCH_ATTEMPTED_COUNT)" != "6" \
      || "$(kv_field "$step24_analysis" PATCH_APPLIED_COUNT)" != "6" \
      || "$(kv_field "$step24_analysis" COMMAND_PASS_COUNT)" != "24" \
      || "$(kv_field "$step24_analysis" COMMAND_FAIL_COUNT)" != "0" \
      || "$(kv_field "$step24_analysis" PRE_DRC_VIOLATION_COUNT)" != "6" \
      || "$(kv_field "$step24_analysis" FINAL_DRC_VIOLATION_COUNT)" != "4" \
      || "$(kv_field "$step24_analysis" PRE_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step24_analysis" FINAL_REGULAR_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step24_analysis" PRE_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step24_analysis" FINAL_SPECIAL_CONNECTIVITY_VIOLATION_COUNT)" != "0" \
      || "$(kv_field "$step24_analysis" PRE_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step24_analysis" FINAL_EXCLUDED_ANTENNA_MARKER_COUNT)" != "21" \
      || "$(kv_field "$step24_analysis" PRE_MARKER_DATABASE_TOTAL)" != "27" \
      || "$(kv_field "$step24_analysis" FINAL_MARKER_DATABASE_TOTAL)" != "25" \
      || "$(kv_field "$step24_analysis" REMOVED_MARKER_SIGNATURE_COUNT)" != "6" \
      || "$(kv_field "$step24_analysis" ADDED_MARKER_SIGNATURE_COUNT)" != "4" \
      || "$(kv_field "$step24_analysis" FINAL_MIN_AREA_NETS)" != "n_9677 n_9693 n_9696 n_9697" \
      || "$(kv_field "$step24_analysis" SAVE_DESIGN)" != "NOT_RUN" \
      || "$(kv_field "$step24_analysis" EXPORT)" != "NOT_RUN" \
      || "$(kv_field "$step24_analysis" IMMUTABLE_PVS_STAGING)" != "NOT_RUN" \
      || "$(kv_field "$step24_analysis" PVS_DECISION)" != "DO_NOT_RUN" \
      || "$(kv_field "$step24_analysis" CANONICAL_RERUN_DECISION)" != "DO_NOT_RUN_FROM_THIS_STEP" \
      || "$(kv_field "$step24_analysis" NEXT_METHOD_DECISION)" != "STOP_AND_REVIEW_PATCH_EVIDENCE_BEFORE_NEW_METHOD" \
      || "$(kv_field "$step24_analysis" ERROR_COUNT)" != "0" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 24 is not the reviewed four-survivor width tuple"
    echo "STEP24_STATUS=$step24_status"
    echo "STEP24_DRIVER=$step24_driver"
    echo "STEP24_ANALYSIS=$step24_analysis"
    return 1
  fi

  if [[ ! -r "$step21_post_markers" || ! -r "$step24_post_markers" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 21 or Step 24 marker evidence is missing"
    echo "STEP21_POST_MARKERS=$step21_post_markers"
    echo "STEP24_POST_MARKERS=$step24_post_markers"
    return 1
  fi
  step21_post_signature="$(normalized_marker_signature_sha256 "$step21_post_markers")"
  step24_post_signature="$(normalized_marker_signature_sha256 "$step24_post_markers")"
  step24_area_count="$(grep -cF "Actual: 0.17770000 Required: 0.20200000" "$step24_post_markers" 2>/dev/null)"
  if [[ -z "$step21_post_signature" \
      || "$step21_post_signature" != "$step24_post_signature" \
      || "$step24_area_count" != "4" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 24 does not reproduce the Step 21 width-saturation signatures"
    echo "STEP21_POST_MARKER_SIGNATURE_SHA256=${step21_post_signature:-MISSING}"
    echo "STEP24_POST_MARKER_SIGNATURE_SHA256=${step24_post_signature:-MISSING}"
    echo "STEP24_0P1777_MARKER_COUNT=${step24_area_count:-MISSING}"
    return 1
  fi
  saturation_status=PASS_IDENTICAL_STEP21_STEP24_SEMANTIC_SIGNATURES

  source_block_root="$(kv_field "$step24_driver" SOURCE_BLOCK_ROOT)"
  source_trial_root="$(kv_field "$step24_driver" TRIAL_ROOT)"
  if [[ -z "$source_block_root" || ! -d "$source_block_root" \
      || -z "$source_trial_root" || ! -d "$source_trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 24 source roots are missing"
    echo "SOURCE_BLOCK_ROOT=${source_block_root:-MISSING}"
    echo "SOURCE_STEP24_TRIAL_ROOT=${source_trial_root:-MISSING}"
    return 1
  fi

  cd "$TX2_REPO" 2>/dev/null
  cd_rc=$?
  if [[ "$cd_rc" -eq 0 ]]; then
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
  fi
  if [[ "$actual_head" != "$expected_report_driver_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: wrong report-driver HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "ACTUAL_HEAD=$actual_head"
    return 1
  fi

  trial_id="${TX2_SESSION_ID}_min_area_landing_materialization_probe"
  trial_root="$TX2_WORK_ROOT/diagnostics/$trial_id"
  trial_status="$trial_root/reports/min_area_landing_patch_trial_status.rpt"
  console="$TX2_SESSION_ROOT/logs/25_min_area_landing_materialization_probe.console.log"
  copy_dir="$TX2_SESSION_ROOT/reports/25_min_area_landing_materialization_probe"
  analysis_report="$TX2_SESSION_ROOT/reports/25_min_area_landing_materialization_analysis.rpt"
  driver_report="$TX2_SESSION_ROOT/reports/25_min_area_landing_materialization_probe_driver.rpt"
  if [[ -e "$trial_root" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: immutable Step 25 probe root already exists"
    echo "TRIAL_ROOT=$trial_root"
    return 1
  fi

  if [[ "$cd_rc" -eq 0 ]]; then
    load_cadence
    cadence_rc=$?
  fi
  if [[ "$cadence_rc" == "0" ]]; then
    export SPADMIC_WORK_ROOT="$TX2_WORK_ROOT"
    export SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R5
    echo "COMMAND=SPADMIC_MIN_AREA_LANDING_TRIAL_REVISION=R5 bash TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh $source_block_root $step24_analysis $trial_id spadmic_tx_packet_core"
    bash "$TX2_REPO/TOP/pnr/scripts/run_innovus_ooc_min_area_landing_patch_trial.sh" \
      "$source_block_root" \
      "$step24_analysis" \
      "$trial_id" \
      spadmic_tx_packet_core \
      >"$console" 2>&1
    trial_rc=$?
  fi

  mkdir -p "$copy_dir"
  if [[ -r "$trial_root/context.rpt" ]]; then
    cp -p "$trial_root/context.rpt" "$copy_dir/context.rpt"
  fi
  if [[ -d "$trial_root/reports" ]]; then
    for path in "$trial_root"/reports/*.rpt "$trial_root"/reports/*.tsv; do
      if [[ -r "$path" ]]; then
        cp -p "$path" "$copy_dir/$(basename "$path")"
      fi
    done
  fi

  if [[ -r "$trial_status" ]]; then
    python3 "$TX2_REPO/TOP/pnr/scripts/analyze_tx_packet_min_area_landing_patch_trial.py" \
      --trial-root "$trial_root" \
      --step24-analysis "$step24_analysis" \
      --trial-revision R5 \
      --report-driver-head "$actual_head" \
      --report "$analysis_report"
    analysis_rc=$?
  fi

  materialization_status="$(kv_field "$analysis_report" MATERIALIZATION_STATUS)"
  case "$materialization_status" in
    REQUESTED_0P56_WIDTH_MATERIALIZED|WIDE_REQUEST_CANONICALIZED_TO_0P28|NO_LOCAL_MET1_WIRE_DELTA|MIXED_LOCAL_MET1_MATERIALIZATION)
      materialization_class_ok=YES
      ;;
  esac
  if [[ ( "$trial_rc" == "0" || "$trial_rc" == "8" ) \
      && "$analysis_rc" == "0" \
      && "$(kv_field "$analysis_report" LABEL)" == "SPADMIC_TX_PACKET_MIN_AREA_LANDING_MATERIALIZATION_ANALYSIS" \
      && "$(kv_field "$analysis_report" STATUS)" == "PASS" \
      && "$(kv_field "$analysis_report" RESULT)" == "MIN_AREA_LANDING_MATERIALIZATION_PROBE_CLASSIFIED" \
      && "$(kv_field "$analysis_report" TRIAL_REVISION)" == "R5" \
      && "$(kv_field "$analysis_report" METHOD_STATUS)" == "DIAGNOSTIC_CAPTURE_COMPLETE" \
      && "$(kv_field "$analysis_report" MATERIALIZATION_CAPTURE_STATUS)" == "COMPLETE" \
      && "$materialization_class_ok" == "YES" ]]; then
    status=PASS
    result=MIN_AREA_LANDING_MATERIALIZATION_CLASSIFIED_NO_SAVE_EXPORT_OR_PVS
  else
    result=MIN_AREA_LANDING_MATERIALIZATION_CLASSIFICATION_INCOMPLETE
  fi
  trial_process_status="$(kv_field "$analysis_report" TRIAL_PROCESS_STATUS)"
  trial_process_result="$(kv_field "$analysis_report" TRIAL_PROCESS_RESULT)"
  method_status="$(kv_field "$analysis_report" METHOD_STATUS)"
  capture_status="$(kv_field "$analysis_report" MATERIALIZATION_CAPTURE_STATUS)"
  next_decision="$(kv_field "$analysis_report" NEXT_METHOD_DECISION)"

  {
    echo "SOURCE_ARTIFACT_HEAD=$TX2_EXPECTED_HEAD"
    echo "EXPECTED_REPORT_DRIVER_HEAD=$expected_report_driver_head"
    echo "REPORT_DRIVER_HEAD=$actual_head"
    echo "SOURCE_STEP24_STATUS=$step24_status"
    echo "SOURCE_STEP24_DRIVER=$step24_driver"
    echo "SOURCE_STEP24_ANALYSIS=$step24_analysis"
    echo "SOURCE_STEP24_TRIAL_ROOT=$source_trial_root"
    echo "SOURCE_BLOCK_ROOT=$source_block_root"
    echo "STEP21_POST_MARKER_SIGNATURE_SHA256=$step21_post_signature"
    echo "STEP24_POST_MARKER_SIGNATURE_SHA256=$step24_post_signature"
    echo "STEP24_0P1777_MARKER_COUNT=$step24_area_count"
    echo "SOURCE_WIDTH_SATURATION_STATUS=$saturation_status"
    echo "TRIAL_REVISION=R5"
    echo "TRIAL_RC=$trial_rc"
    echo "TRIAL_ROOT=$trial_root"
    echo "TRIAL_STATUS=$trial_status"
    echo "ANALYSIS_RC=$analysis_rc"
    echo "ANALYSIS_REPORT=$analysis_report"
    echo "TRIAL_PROCESS_STATUS=${trial_process_status:-UNKNOWN}"
    echo "TRIAL_PROCESS_RESULT=${trial_process_result:-UNKNOWN}"
    echo "METHOD_STATUS=${method_status:-UNKNOWN}"
    echo "MATERIALIZATION_CAPTURE_STATUS=${capture_status:-UNKNOWN}"
    echo "MATERIALIZATION_STATUS=${materialization_status:-UNKNOWN}"
    echo "NEXT_METHOD_DECISION=${next_decision:-UNKNOWN}"
    echo "DESIGN_MODIFICATION=IN_MEMORY_ONLY"
    echo "SAVE_DESIGN=NOT_RUN"
    echo "EXPORT=NOT_RUN"
    echo "CANONICAL_RERUN=NOT_RUN"
    echo "IMMUTABLE_PVS_STAGING=NOT_RUN"
    echo "PVS=NOT_RUN"
  } >"$driver_report"
  cat "$driver_report"
  if [[ -r "$analysis_report" ]]; then
    cat "$analysis_report"
  elif [[ -r "$console" ]]; then
    tail -n 340 "$console"
  fi
  record_status 25_min_area_landing_materialization_probe "$status" "$analysis_rc" "$result" "$trial_root"
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
  pg-analyze)
    pg_analyze
    ;;
  pg-help)
    pg_help
    ;;
  pg-via-trial)
    pg_via_trial "$ARGUMENT_1"
    ;;
  pg-via-drc-probe)
    pg_via_drc_probe
    ;;
  pg-via-1x1-trial)
    pg_via_1x1_trial
    ;;
  preroute-pg-rerun)
    preroute_pg_rerun "$ARGUMENT_1"
    ;;
  preroute-pg-postfiller-rerun)
    preroute_pg_postfiller_rerun "$ARGUMENT_1"
    ;;
  postfiller-stage-probe)
    postfiller_stage_probe "$ARGUMENT_1"
    ;;
  postcts-via1-analyze)
    postcts_via1_analyze "$ARGUMENT_1"
    ;;
  preroute-pg-no-restitch-rerun)
    preroute_pg_no_restitch_rerun "$ARGUMENT_1"
    ;;
  final-closure-analyze)
    final_closure_analyze "$ARGUMENT_1"
    ;;
  min-area-second-pass-trial)
    echo "STOP_HERE_DO_NOT_CONTINUE: Step 18 R1 is immutable failed evidence; use min-area-second-pass-trial-r2"
    ;;
  min-area-second-pass-trial-r2)
    min_area_second_pass_trial_r2 "$ARGUMENT_1"
    ;;
  min-area-geometry-probe)
    min_area_geometry_probe "$ARGUMENT_1"
    ;;
  min-area-landing-patch-trial)
    min_area_landing_patch_trial "$ARGUMENT_1"
    ;;
  min-area-landing-patch-trial-r2)
    min_area_landing_patch_trial_r2 "$ARGUMENT_1"
    ;;
  min-area-landing-patch-trial-r3)
    min_area_landing_patch_trial_r3 "$ARGUMENT_1"
    ;;
  min-area-landing-patch-trial-r4)
    min_area_landing_patch_trial_r4 "$ARGUMENT_1"
    ;;
  min-area-landing-materialization-probe)
    min_area_landing_materialization_probe "$ARGUMENT_1"
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
