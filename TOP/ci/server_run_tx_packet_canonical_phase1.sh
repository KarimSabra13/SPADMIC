#!/usr/bin/env bash
# =============================================================================
# TX packet-core canonical rebuild: staged server gate driver.
#
# Every subcommand is intentionally independent. This driver never launches
# Innovus or PVS, never edits historical OA/GDS/PVS inputs, and contains no
# explicit exit command. Status is written to reports instead of relying on
# login-shell control flow.
# =============================================================================

set +e

WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
ACTIVE_ENV="${SPADMIC_TX_PACKET_ACTIVE_ENV:-$WORK_ROOT/diagnostics/tx_packet_canonical_active.env}"
REPO_DEFAULT="/home/validmgr/ksabra/2026_SPAD/SPADMIC"
COMMAND="${1:-help}"
ARGUMENT="${2:-}"

usage() {
  cat <<'USAGE'
Usage:
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh init <expected-head>
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh sync
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh preflight
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh xcelium-focus
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh xcelium-full
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh xcelium-report
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh genus
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh genus-report
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh package
  bash TOP/ci/server_run_tx_packet_canonical_phase1.sh status

Run one subcommand at a time. Review its STEP_STATUS before continuing.
The active session pointer defaults to:
  /sim/ksabra/SPADMIC_work/diagnostics/tx_packet_canonical_active.env
USAGE
}

append_active_assignment() {
  local name="$1"
  local value="$2"
  printf 'export %s=%q\n' "$name" "$value" >> "$ACTIVE_ENV"
}

load_session() {
  if [[ ! -r "$ACTIVE_ENV" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: active session file is missing"
    echo "ACTIVE_ENV=$ACTIVE_ENV"
    echo "Run the init subcommand first."
    return 1
  fi

  # shellcheck disable=SC1090
  source "$ACTIVE_ENV"
  local required
  for required in \
    TX_REPO \
    TX_WORK_ROOT \
    TX_EXPECTED_HEAD \
    TX_SESSION_ID \
    TX_SESSION_ROOT \
    TX_XCELIUM_RUN \
    TX_GENUS_RUN
  do
    if [[ -z "${!required:-}" ]]; then
      echo "STOP_HERE_DO_NOT_CONTINUE: missing $required in $ACTIVE_ENV"
      return 1
    fi
  done

  mkdir -p \
    "$TX_SESSION_ROOT/logs" \
    "$TX_SESSION_ROOT/reports" \
    "$TX_SESSION_ROOT/status" \
    "$TX_SESSION_ROOT/packages"
  return $?
}

status_field() {
  local step="$1"
  local key="$2"
  local report="$TX_SESSION_ROOT/status/${step}.rpt"
  if [[ -r "$report" ]]; then
    awk -F= -v key="$key" '$1 == key {value = substr($0, index($0, "=") + 1)} END {print value}' "$report"
  fi
}

record_status() {
  local step="$1"
  local status="$2"
  local rc="$3"
  local result="$4"
  local report="$TX_SESSION_ROOT/status/${step}.rpt"
  local utc
  utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  {
    echo "LABEL=SPADMIC_TX_PACKET_CANONICAL_PHASE1"
    echo "STEP=$step"
    echo "DATE_UTC=$utc"
    echo "HEAD_EXPECTED=$TX_EXPECTED_HEAD"
    echo "STATUS=$status"
    echo "RC=$rc"
    echo "RESULT=$result"
    echo "SESSION_ROOT=$TX_SESSION_ROOT"
    echo "POLICY=ONE_OPERATOR_COMMAND_PER_GATE_NO_AUTO_ADVANCE"
  } | tee "$report"

  {
    echo
    echo "[$utc] STEP=$step STATUS=$status RC=$rc RESULT=$result"
    echo "REPORT=$report"
  } >> "$TX_SESSION_ROOT/execution_journal.rpt"
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
  if [[ -z "$expected_head" ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: init requires the expected Git HEAD"
    usage
    return 1
  fi

  local stamp session_id session_root mkdir_rc
  stamp="$(date +%Y%m%d_%H%M%S)"
  session_id="tx_packet_canonical_phase1_${stamp}"
  session_root="$WORK_ROOT/diagnostics/$session_id"
  mkdir -p "$session_root/logs" "$session_root/reports" "$session_root/status" "$session_root/packages"
  mkdir_rc=$?

  if [[ "$mkdir_rc" -ne 0 ]]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: cannot create session root"
    echo "SESSION_ROOT=$session_root"
    return 1
  fi

  mkdir -p "$(dirname "$ACTIVE_ENV")"
  : > "$ACTIVE_ENV"
  append_active_assignment TX_REPO "${SPADMIC_TX_REPO:-$REPO_DEFAULT}"
  append_active_assignment TX_WORK_ROOT "$WORK_ROOT"
  append_active_assignment TX_EXPECTED_HEAD "$expected_head"
  append_active_assignment TX_SESSION_ID "$session_id"
  append_active_assignment TX_SESSION_ROOT "$session_root"
  append_active_assignment TX_XCELIUM_RUN "xcelium_tx_packet_canonical_${stamp}"
  append_active_assignment TX_GENUS_RUN "genus_ooc_tx_packet_core_canonical_${stamp}"

  load_session
  local load_rc=$?
  if [[ "$load_rc" -ne 0 ]]; then
    return 1
  fi

  {
    echo "LABEL=SPADMIC_TX_PACKET_CANONICAL_OBJECTIVE"
    echo "DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "CURRENT_SCOPE=P03_SERVER_GATE_1_RTL_AND_GENUS"
    echo "CANONICAL_TOP=spadmic_tx_packet_core"
    echo "GOAL=PROVE_SCALAR_RTL_MAPPING_AND_FRESH_PACKET_OOC_GENUS_BEFORE_PNR"
    echo "HISTORICAL_HV_POLICY=READ_ONLY_EVIDENCE_NOT_A_REPLAY_SOURCE"
    echo "NESTED_PIN_HYPOTHESIS=NOT_PRIMARY_HISTORICAL_MISMATCH_CAUSE"
    echo "ACTIVE_SOURCE_INTERFACE=64_UNIQUE_SRC_DATA_SCALARS"
    echo "PHYSICAL_GATES=INNOVUS_AND_PVS_NOT_RUN_IN_THIS_PHASE"
    echo "GATE_SEPARATION=RTL_GENUS_INNOVUS_PG_DRC_ANTENNA_PVS_DRC_LVS"
    echo "STOP_RULE=DO_NOT_ADVANCE_AFTER_ANY_NON_PASS_PREREQUISITE"
    echo "FINAL_HANDOFF_READY=NO"
  } | tee "$TX_SESSION_ROOT/00_objective_and_policy.rpt"

  {
    echo "SPADMIC TX packet canonical phase-1 execution journal"
    echo "SESSION_ID=$TX_SESSION_ID"
    echo "SESSION_ROOT=$TX_SESSION_ROOT"
    echo "EXPECTED_HEAD=$TX_EXPECTED_HEAD"
    echo "ACTIVE_ENV=$ACTIVE_ENV"
  } > "$TX_SESSION_ROOT/execution_journal.rpt"

  record_status 00_init PASS 0 SESSION_INITIALIZED
  echo "ACTIVE_ENV=$ACTIVE_ENV"
  echo "SESSION_ROOT=$TX_SESSION_ROOT"
  return 0
}

sync_repo() {
  load_session || return 1

  local cd_rc checkout_rc pull_rc actual_head status
  cd "$TX_REPO" 2>/dev/null
  cd_rc=$?
  checkout_rc=NOT_RUN
  pull_rc=NOT_RUN
  actual_head=UNKNOWN
  status=FAIL

  if [[ "$cd_rc" -eq 0 ]]; then
    git checkout SPADMIC_test 2>&1 | tee "$TX_SESSION_ROOT/logs/01_git_checkout.log"
    checkout_rc=${PIPESTATUS[0]}
    git pull --ff-only origin SPADMIC_test 2>&1 | tee "$TX_SESSION_ROOT/logs/01_git_pull.log"
    pull_rc=${PIPESTATUS[0]}
    actual_head="$(git rev-parse HEAD 2>/dev/null)"
    git status --short --branch | tee "$TX_SESSION_ROOT/reports/01_git_status.rpt"
  fi

  if [[ "$cd_rc" -eq 0 && "$checkout_rc" -eq 0 && "$pull_rc" -eq 0 && "$actual_head" == "$TX_EXPECTED_HEAD" ]]; then
    status=PASS
  fi

  {
    echo "COMMAND_CHECKOUT=git checkout SPADMIC_test"
    echo "COMMAND_PULL=git pull --ff-only origin SPADMIC_test"
    echo "CD_RC=$cd_rc"
    echo "CHECKOUT_RC=$checkout_rc"
    echo "PULL_RC=$pull_rc"
    echo "EXPECTED_HEAD=$TX_EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$actual_head"
    echo "DIRTY_TREE_POLICY=RECORD_ONLY_DO_NOT_TOUCH_UNRELATED_FILES"
  } | tee "$TX_SESSION_ROOT/reports/01_sync_details.rpt"

  record_status 01_sync "$status" "$pull_rc" REPOSITORY_HEAD_CHECKED
  [[ "$status" == "PASS" ]]
  return $?
}

preflight() {
  load_session || return 1
  require_step_pass 01_sync || {
    record_status 02_preflight BLOCKED NOT_RUN PREREQUISITE_01_SYNC_NOT_PASS
    return 1
  }

  cd "$TX_REPO" 2>/dev/null
  local cd_rc=$?
  if [[ "$cd_rc" -ne 0 ]]; then
    record_status 02_preflight FAIL "$cd_rc" REPOSITORY_DIRECTORY_UNAVAILABLE
    return 1
  fi
  load_cadence
  local eda_rc=$?
  local xrun_path genus_path generator_rc tests_rc diff_rc status
  xrun_path="$(command -v xrun 2>/dev/null)"
  genus_path="$(command -v genus 2>/dev/null)"

  python3 TOP/scripts/generate_tx_src_data_flat.py --check 2>&1 | tee "$TX_SESSION_ROOT/logs/02_generator_check.log"
  generator_rc=${PIPESTATUS[0]}
  python3 -m unittest discover -s TOP/pnr/tests -p 'test_*.py' 2>&1 | tee "$TX_SESSION_ROOT/logs/02_python_tests.log"
  tests_rc=${PIPESTATUS[0]}
  git diff --check 2>&1 | tee "$TX_SESSION_ROOT/logs/02_git_diff_check.log"
  diff_rc=${PIPESTATUS[0]}
  status=FAIL

  if [[ "$cd_rc" -eq 0 && "$eda_rc" -eq 0 && -n "$xrun_path" && -n "$genus_path" && "$generator_rc" -eq 0 && "$tests_rc" -eq 0 && "$diff_rc" -eq 0 ]]; then
    status=PASS
  fi

  {
    echo "CD_RC=$cd_rc"
    echo "EDA_RC=$eda_rc"
    echo "XRUN_PATH=${xrun_path:-MISSING}"
    echo "GENUS_PATH=${genus_path:-MISSING}"
    echo "GENERATOR_CHECK_RC=$generator_rc"
    echo "PYTHON_TEST_RC=$tests_rc"
    echo "GIT_DIFF_CHECK_RC=$diff_rc"
  } | tee "$TX_SESSION_ROOT/reports/02_preflight_details.rpt"

  record_status 02_preflight "$status" "$tests_rc" STATIC_AND_TOOL_PREFLIGHT_COMPLETE
  [[ "$status" == "PASS" ]]
  return $?
}

xcelium_focus() {
  load_session || return 1
  require_step_pass 02_preflight || {
    record_status 03_xcelium_focus BLOCKED NOT_RUN PREREQUISITE_02_PREFLIGHT_NOT_PASS
    return 1
  }

  cd "$TX_REPO" 2>/dev/null
  local cd_rc=$?
  if [[ "$cd_rc" -ne 0 ]]; then
    record_status 03_xcelium_focus FAIL "$cd_rc" REPOSITORY_DIRECTORY_UNAVAILABLE
    return 1
  fi
  load_cadence
  local eda_rc=$?
  if [[ "$eda_rc" -ne 0 ]]; then
    record_status 03_xcelium_focus FAIL "$eda_rc" CADENCE_ENVIRONMENT_UNAVAILABLE
    return 1
  fi
  local fail_count=0 test_name test_rc source_log status
  local summary="$TX_SESSION_ROOT/reports/03_xcelium_focus_summary.tsv"
  local tests=(
    tb_spadmic_tx_src_data_flat_mapping_unit
    tb_spadmic_event_bundle_tx_unit
    tb_spadmic_tx_egress_core_unit
    tb_spadmic_tx_egress_cluster_unit
    tb_spadmic_top_matrix_v1_shell_unit
  )

  printf 'test\trc\tverdict\n' > "$summary"
  for test_name in "${tests[@]}"; do
    echo "===== XCELIUM FOCUS: $test_name ====="
    bash TOP/scripts/sim/run_tb.sh "$test_name" 2>&1 | tee "$TX_SESSION_ROOT/logs/03_${test_name}.console.log"
    test_rc=${PIPESTATUS[0]}
    if [[ "$test_rc" -eq 0 ]]; then
      printf '%s\t%s\tPASS\n' "$test_name" "$test_rc" >> "$summary"
    else
      printf '%s\t%s\tFAIL\n' "$test_name" "$test_rc" >> "$summary"
      fail_count=$((fail_count + 1))
    fi
    source_log="$TX_REPO/TOP/build/directed/$test_name/run.log"
    if [[ -r "$source_log" ]]; then
      cp -p "$source_log" "$TX_SESSION_ROOT/logs/03_${test_name}.run.log"
    fi
  done

  status=FAIL
  if [[ "$eda_rc" -eq 0 && "$fail_count" -eq 0 ]]; then
    status=PASS
  fi
  cat "$summary"
  record_status 03_xcelium_focus "$status" "$fail_count" FIVE_CANONICAL_BOUNDARY_TESTS_COMPLETE
  [[ "$status" == "PASS" ]]
  return $?
}

xcelium_full() {
  load_session || return 1
  require_step_pass 03_xcelium_focus || {
    record_status 04_xcelium_full BLOCKED NOT_RUN PREREQUISITE_03_XCELIUM_FOCUS_NOT_PASS
    return 1
  }

  cd "$TX_REPO" 2>/dev/null
  local cd_rc=$?
  if [[ "$cd_rc" -ne 0 ]]; then
    record_status 04_xcelium_full FAIL "$cd_rc" REPOSITORY_DIRECTORY_UNAVAILABLE
    return 1
  fi
  load_cadence
  local eda_rc=$?
  if [[ "$eda_rc" -ne 0 ]]; then
    record_status 04_xcelium_full FAIL "$eda_rc" CADENCE_ENVIRONMENT_UNAVAILABLE
    return 1
  fi
  echo "COMMAND=bash TOP/ci/server_run_matrix_top_xcelium.sh $TX_XCELIUM_RUN"
  bash TOP/ci/server_run_matrix_top_xcelium.sh "$TX_XCELIUM_RUN" 2>&1 | tee "$TX_SESSION_ROOT/logs/04_xcelium_full.console.log"
  local run_rc=${PIPESTATUS[0]}
  local run_root="$TX_WORK_ROOT/xcelium/$TX_XCELIUM_RUN"
  local status=FAIL
  if [[ "$eda_rc" -eq 0 && "$run_rc" -eq 0 ]]; then
    status=PASS
  fi
  for file_name in SUMMARY.md test_summary.txt run_manifest.txt; do
    if [[ -r "$run_root/$file_name" ]]; then
      cp -p "$run_root/$file_name" "$TX_SESSION_ROOT/reports/04_xcelium_${file_name}"
    fi
  done
  record_status 04_xcelium_full "$status" "$run_rc" FULL_MATRIX_TOP_XCELIUM_REGRESSION_COMPLETE
  [[ "$status" == "PASS" ]]
  return $?
}

xcelium_report() {
  load_session || return 1
  local run_root="$TX_WORK_ROOT/xcelium/$TX_XCELIUM_RUN"
  local report="$TX_SESSION_ROOT/reports/05_xcelium_review.rpt"
  local failure_report="$TX_SESSION_ROOT/reports/05_xcelium_failure_markers.rpt"
  local report_driver_head tail_file failure_marker_count

  report_driver_head="$(git -C "$TX_REPO" rev-parse HEAD 2>/dev/null)"
  : > "$failure_report"
  if [[ -r "$run_root/test_summary.txt" ]]; then
    grep -nE '^(FAIL|MISSING)[[:space:]]' "$run_root/test_summary.txt" >> "$failure_report"
  fi
  for tail_file in "$run_root"/logs/*.tail; do
    if [[ -r "$tail_file" ]]; then
      grep -nE 'UVM_(ERROR|FATAL)|(^|[^[:alnum:]_])(FATAL|ERROR)[[:space:]]*:|\*(E|F),' "$tail_file" \
        | sed "s#^#$tail_file:#" >> "$failure_report"
    fi
  done
  failure_marker_count="$(wc -l < "$failure_report" | tr -d ' ')"

  {
    echo "LABEL=SPADMIC_TX_PACKET_XCELIUM_REVIEW"
    echo "RUN_ROOT=$run_root"
    echo "SOURCE_STEP_STATUS=$(status_field 04_xcelium_full STATUS)"
    echo "REPORT_DRIVER_HEAD=${report_driver_head:-UNKNOWN}"
    echo "FAILURE_MARKER_COUNT=$failure_marker_count"
    echo
    echo "===== TEST SUMMARY ====="
    if [[ -r "$run_root/test_summary.txt" ]]; then
      cat "$run_root/test_summary.txt"
    else
      echo "MISSING=$run_root/test_summary.txt"
    fi
    echo
    echo "===== FAILURE MARKERS ====="
    if [[ -s "$failure_report" ]]; then
      cat "$failure_report"
    else
      echo "NONE"
    fi
  } | tee "$report"
  record_status 05_xcelium_report CAPTURED 0 XCELIUM_REVIEW_REPORT_READY
  return 0
}

run_genus() {
  load_session || return 1
  require_step_pass 04_xcelium_full || {
    record_status 06_genus BLOCKED NOT_RUN PREREQUISITE_04_XCELIUM_FULL_NOT_PASS
    return 1
  }

  cd "$TX_REPO" 2>/dev/null
  local cd_rc=$?
  if [[ "$cd_rc" -ne 0 ]]; then
    record_status 06_genus FAIL "$cd_rc" REPOSITORY_DIRECTORY_UNAVAILABLE
    return 1
  fi
  load_cadence
  local eda_rc=$?
  if [[ "$eda_rc" -ne 0 ]]; then
    record_status 06_genus FAIL "$eda_rc" CADENCE_ENVIRONMENT_UNAVAILABLE
    return 1
  fi
  echo "COMMAND=bash TOP/syn/scripts/run_genus_ooc_block.sh tx_packet_core $TX_GENUS_RUN"
  bash TOP/syn/scripts/run_genus_ooc_block.sh tx_packet_core "$TX_GENUS_RUN" 2>&1 | tee "$TX_SESSION_ROOT/logs/06_genus.console.log"
  local run_rc=${PIPESTATUS[0]}
  local run_root="$TX_WORK_ROOT/genus/$TX_GENUS_RUN"
  local block_root="$run_root/tx_packet_core"
  local status=FAIL
  if [[ "$eda_rc" -eq 0 && "$run_rc" -eq 0 && -s "$block_root/outputs/tx_packet_core.postsyn.v" ]]; then
    status=PASS
  fi
  if [[ -r "$run_root/SUMMARY.md" ]]; then
    cp -p "$run_root/SUMMARY.md" "$TX_SESSION_ROOT/reports/06_genus_run_SUMMARY.md"
  fi
  if [[ -r "$block_root/SUMMARY.md" ]]; then
    cp -p "$block_root/SUMMARY.md" "$TX_SESSION_ROOT/reports/06_genus_block_SUMMARY.md"
  fi
  record_status 06_genus "$status" "$run_rc" GENUS_TOOL_FLOW_COMPLETE_REPORT_REVIEW_REQUIRED
  [[ "$status" == "PASS" ]]
  return $?
}

genus_report() {
  load_session || return 1
  local run_root="$TX_WORK_ROOT/genus/$TX_GENUS_RUN"
  local block_root="$run_root/tx_packet_core"
  local netlist="$block_root/outputs/tx_packet_core.postsyn.v"
  local sdc="$block_root/outputs/tx_packet_core.postsyn.sdc"
  local report="$TX_SESSION_ROOT/reports/07_genus_review.rpt"
  local nested_count=MISSING scalar_count=MISSING
  local report_driver_head
  report_driver_head="$(git -C "$TX_REPO" rev-parse HEAD 2>/dev/null)"
  local critical_reports=(
    reports/elaboration/check_design_post_elab.rpt
    reports/timing/check_timing_intent.rpt
    reports/timing/report_clocks.rpt
    reports/timing/report_timing_post_opt.rpt
    reports/qor/report_qor.rpt
    reports/messages/warning_classification.rpt
  )
  local rel source

  if [[ -s "$netlist" ]]; then
    nested_count="$(grep -Ec 'src_data_i\[[^]]+\]\[' "$netlist")"
    scalar_count="$(grep -oE 'src_data_i_s[0-3]_b([0-9]|1[0-5])' "$netlist" | sort -u | wc -l | tr -d ' ')"
  fi

  {
    echo "LABEL=SPADMIC_TX_PACKET_GENUS_REVIEW"
    echo "RUN_ROOT=$run_root"
    echo "BLOCK_ROOT=$block_root"
    echo "GENUS_TOOL_STEP_STATUS=$(status_field 06_genus STATUS)"
    echo "REPORT_DRIVER_HEAD=${report_driver_head:-UNKNOWN}"
    echo "NESTED_SRC_DATA_NAME_COUNT=$nested_count"
    echo "UNIQUE_SCALAR_SRC_DATA_NAME_COUNT=$scalar_count"
    echo "CLOSURE_STATUS=REVIEW_REQUIRED_NOT_INFERRED_FROM_TOOL_RC"
    echo
    echo "===== RUN SUMMARY ====="
    if [[ -r "$run_root/SUMMARY.md" ]]; then
      cat "$run_root/SUMMARY.md"
    else
      echo "MISSING=$run_root/SUMMARY.md"
    fi
    echo
    echo "===== BLOCK SUMMARY ====="
    if [[ -r "$block_root/SUMMARY.md" ]]; then
      cat "$block_root/SUMMARY.md"
    else
      echo "MISSING=$block_root/SUMMARY.md"
    fi
    echo
    echo "===== FOCUSED GATE LINES ====="
    for rel in "${critical_reports[@]}"; do
      source="$block_root/$rel"
      echo
      echo "--- $rel ---"
      if [[ -r "$source" ]]; then
        wc -l "$source"
        grep -nEi 'error|fatal|unresolved|unclocked|unconstrained|slack|wns|tns|violat|fail' "$source" | tail -120
      else
        echo "MISSING=$source"
      fi
    done
    echo
    echo "===== COMPLETE CLOCK REPORT ====="
    if [[ -r "$block_root/reports/timing/report_clocks.rpt" ]]; then
      cat "$block_root/reports/timing/report_clocks.rpt"
    else
      echo "MISSING=$block_root/reports/timing/report_clocks.rpt"
    fi
    echo
    echo "===== TIMING INTENT CATEGORIES ====="
    if [[ -r "$block_root/reports/timing/check_timing_intent.rpt" ]]; then
      grep -nEi -B 2 -A 8 \
        'unclocked|unconstrained|no[[:space:]_]+clock|clock.*missing|sequential|endpoint|input.*delay|output.*delay' \
        "$block_root/reports/timing/check_timing_intent.rpt"
    else
      echo "MISSING=$block_root/reports/timing/check_timing_intent.rpt"
    fi
    echo
    echo "===== COMPLETE QOR REPORT ====="
    if [[ -r "$block_root/reports/qor/report_qor.rpt" ]]; then
      cat "$block_root/reports/qor/report_qor.rpt"
    else
      echo "MISSING=$block_root/reports/qor/report_qor.rpt"
    fi
    echo
    echo "===== COMPLETE WARNING CLASSIFICATION ====="
    if [[ -r "$block_root/reports/messages/warning_classification.rpt" ]]; then
      cat "$block_root/reports/messages/warning_classification.rpt"
    else
      echo "MISSING=$block_root/reports/messages/warning_classification.rpt"
    fi
    echo
    echo "===== OUTPUT HASHES ====="
    if [[ -s "$netlist" ]]; then
      sha256sum "$netlist"
    else
      echo "MISSING_OR_EMPTY=$netlist"
    fi
    if [[ -s "$sdc" ]]; then
      sha256sum "$sdc"
    else
      echo "MISSING_OR_EMPTY=$sdc"
    fi
  } | tee "$report"

  for rel in "${critical_reports[@]}"; do
    source="$block_root/$rel"
    if [[ -r "$source" ]]; then
      cp -p "$source" "$TX_SESSION_ROOT/reports/07_$(basename "$source")"
    fi
  done
  if [[ -s "$netlist" ]]; then
    cp -p "$netlist" "$TX_SESSION_ROOT/reports/07_tx_packet_core.postsyn.v"
  fi
  if [[ -s "$sdc" ]]; then
    cp -p "$sdc" "$TX_SESSION_ROOT/reports/07_tx_packet_core.postsyn.sdc"
  fi

  record_status 07_genus_report CAPTURED 0 GENUS_REVIEW_AND_CANONICAL_INTERFACE_EVIDENCE_READY
  return 0
}

package_evidence() {
  load_session || return 1
  local package="$TX_SESSION_ROOT/packages/${TX_SESSION_ID}_text_evidence.tar.gz"
  tar -czf "$package" \
    -C "$TX_SESSION_ROOT" \
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
  } | tee "$TX_SESSION_ROOT/reports/08_package_details.rpt"
  record_status 08_package "$status" "$tar_rc" TEXT_ONLY_EVIDENCE_PACKAGE_COMPLETE
  [[ "$status" == "PASS" ]]
  return $?
}

show_status() {
  load_session || return 1
  echo "ACTIVE_ENV=$ACTIVE_ENV"
  echo "SESSION_ROOT=$TX_SESSION_ROOT"
  echo "EXPECTED_HEAD=$TX_EXPECTED_HEAD"
  echo
  local report
  for report in "$TX_SESSION_ROOT"/status/*.rpt; do
    if [[ -r "$report" ]]; then
      echo "===== $(basename "$report") ====="
      cat "$report"
    fi
  done
  return 0
}

case "$COMMAND" in
  init)
    init_session "$ARGUMENT"
    ;;
  sync)
    sync_repo
    ;;
  preflight)
    preflight
    ;;
  xcelium-focus)
    xcelium_focus
    ;;
  xcelium-full)
    xcelium_full
    ;;
  xcelium-report)
    xcelium_report
    ;;
  genus)
    run_genus
    ;;
  genus-report)
    genus_report
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

# Keep the operator's interactive shell safe. Gate truth lives in status files.
:
