#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix TOP — server Xcelium regression wrapper
#
# Intended server use:
#   cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
#   source /eda/cadence/eda_2023-2024
#   export SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
#   bash TOP/ci/server_run_matrix_top_xcelium.sh <run_id>
#
# This script is intentionally server-facing. It does not claim success when
# xrun is missing and it keeps generated Xcelium work under SPADMIC_WORK_ROOT.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
MPTDC_ROOT="$REPO_ROOT/MPTDC"
POSITION_TB_ROOT="$REPO_ROOT/position/tb"
ARB_TB_ROOT="$REPO_ROOT/arb/tb"
RUN_ID="${1:-matrix_top_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
RUN_ROOT="$WORK_ROOT/xcelium/$RUN_ID"

TESTS=(
  tb_spadmic_arb_modes
  tb_spadmic_arb_stress
  tb_spadmic_i2c_control_plane_unit
  tb_spadmic_i2c_matrix_top_16b_unit
  tb_spadmic_matrix_or_tree_unit
  tb_spadmic_matrix_snapshot_frontend_unit
  tb_spadmic_matrix_reset_ctrl_unit
  tb_spadmic_event_coordinator_modes_unit
  tb_spadmic_position_snapshot_packetizer_unit
  tb_spadmic_position_modes_unit
  tb_spadmic_position_snapshot_cluster_unit
  tb_spadmic_output_fifo_unit
  tb_spadmic_output_fifo_ddr_marker_unit
  tb_spadmic_ddr16_tx_pairer_unit
  tb_spadmic_matrix_cfg_ctrl_unit
  tb_spadmic_matrix_cfg_cout_readback_unit
  tb_spadmic_event_bundle_tx_unit
  tb_spadmic_matrix_top_csr_unit
  tb_spadmic_matrix_top_csr_16b_unit
  tb_spadmic_top_matrix_v1_shell_unit
  tb_spadmic_top_output_pressure_unit
  tb_spadmic_top_output_fifo_pressure_integration_unit
  tb_spadmic_top_matrix_v1_both_full_unit
  tb_spadmic_top_matrix_v1_skew_campaign
  tb_spadmic_top_reset_during_event_unit
  tb_spadmic_top_reset_during_matrix_cfg_unit
  tb_spadmic_top_mode_transition_unit
  tb_spadmic_top_sequencer_unit
  tb_spadmic_stress_csr
  tb_spadmic_stress_position
  tb_spadmic_ddr_tx_unit
)

find_tb() {
  local tb="$1"
  local dir
  for dir in "$TOP_ROOT/tb" "$TOP_ROOT/tb/unit" "$TOP_ROOT/tb/int" "$POSITION_TB_ROOT" "$ARB_TB_ROOT"; do
    if [[ -f "$dir/${tb}.sv" ]]; then
      printf '%s\n' "$dir/${tb}.sv"
      return 0
    fi
  done
  return 1
}

write_summary_header() {
  {
    echo "# SPADMIC Matrix TOP Xcelium Run"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Repository: \`$REPO_ROOT\`"
    echo "- Run directory: \`$RUN_ROOT\`"
    echo "- Command: \`bash TOP/ci/server_run_matrix_top_xcelium.sh $RUN_ID\`"
    echo "- Branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
    echo "- Commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
    if [[ -f "$RUN_ROOT/xrun_version.txt" ]]; then
      echo "- Xrun version: \`$(head -1 "$RUN_ROOT/xrun_version.txt" | sed 's/[`|]/_/g')\`"
    fi
    echo "- Status: see Final Result"
    echo
    echo "## Tests"
    echo
    echo "| Test | Result | Notes |"
    echo "| --- | --- | --- |"
  } > "$RUN_ROOT/SUMMARY.md"
}

append_failure_detail() {
  local tb="$1" log="$2" tail_file="$3"
  local first_error
  first_error="$(grep -m 1 -E "(ERROR|FATAL|\\*E,|UVM_ERROR|UVM_FATAL|FAIL)" "$log" 2>/dev/null || true)"
  if [[ -z "$first_error" ]]; then
    first_error="No explicit ERROR/FATAL marker found; inspect the log tail."
  fi
  {
    echo
    echo "### Failure Detail: \`$tb\`"
    echo
    echo "- First error: \`$(printf '%s' "$first_error" | sed 's/[`|]/_/g')\`"
    echo "- Tail file: \`logs/${tb}.tail\`"
    echo
    echo '```text'
    tail -40 "$tail_file" 2>/dev/null || true
    echo '```'
  } >> "$RUN_ROOT/SUMMARY.md"
}

append_summary_footer() {
  local pass="$1" fail="$2" missing="$3"
  {
    echo
    echo "## Final Result"
    echo
    echo "- PASS: $pass"
    echo "- FAIL: $fail"
    echo "- MISSING: $missing"
    echo
    if [[ "$fail" -eq 0 && "$missing" -eq 0 ]]; then
      echo "Result: PASS for the required Xcelium regression scope."
    else
      echo "Result: FAIL. Inspect logs and failure tails before making RTL decisions."
    fi
    echo
    echo "## Limitations"
    echo
    echo "- This is Xcelium functional simulation, not CDC/RDC signoff."
    echo "- This is not Genus, Innovus, STA, DRC/LVS, PEX, MMMC, DDR macro timing, or matrix macro timing signoff."
  } >> "$RUN_ROOT/SUMMARY.md"
}

if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: run directory already exists: $RUN_ROOT" >&2
  exit 2
fi

mkdir -p "$RUN_ROOT/logs" "$RUN_ROOT/work"

{
  echo "RUN_ID=$RUN_ID"
  echo "DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "TOP_ROOT=$TOP_ROOT"
  echo "MPTDC_ROOT=$MPTDC_ROOT"
  echo "WORK_ROOT=$WORK_ROOT"
  echo "BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "STATUS_SHORT_BEGIN"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo "STATUS_SHORT_END"
} > "$RUN_ROOT/run_manifest.txt"

git -C "$REPO_ROOT" status --short > "$RUN_ROOT/git_status_short.txt" || true

if ! command -v xrun >/dev/null 2>&1; then
  echo "ERROR: xrun not found. Source the Cadence environment first." | tee "$RUN_ROOT/test_summary.txt"
  echo "xrun not found" > "$RUN_ROOT/xrun_version.txt"
  write_summary_header
  echo "| all | FAIL | xrun not found; source /eda/cadence/eda_2023-2024 |" >> "$RUN_ROOT/SUMMARY.md"
  {
    echo
    echo "## Failure Detail"
    echo
    echo "First error: \`xrun not found\`"
  } >> "$RUN_ROOT/SUMMARY.md"
  append_summary_footer 0 1 0
  exit 3
fi

xrun -version > "$RUN_ROOT/xrun_version.txt" 2>&1 || true

source "$TOP_ROOT/scripts/sim/resolve_flist.sh"
resolve_flist "$MPTDC_ROOT" "$MPTDC_ROOT/rtl/filelist.f" "$RUN_ROOT/mptdc.f"
resolve_flist "$TOP_ROOT" "$TOP_ROOT/filelist.f" "$RUN_ROOT/top.f"

write_summary_header
: > "$RUN_ROOT/test_summary.txt"

PASS=0
FAIL=0
MISSING=0
FAILED_TESTS=()
MISSING_TESTS=()

for tb in "${TESTS[@]}"; do
  echo "=== $tb ==="
  if ! TB_FILE="$(find_tb "$tb")"; then
    echo "MISSING $tb" | tee -a "$RUN_ROOT/test_summary.txt"
    echo "| \`$tb\` | MISSING | Testbench file not found |" >> "$RUN_ROOT/SUMMARY.md"
    MISSING=$((MISSING + 1))
    MISSING_TESTS+=("$tb")
    continue
  fi

  TEST_WORK="$RUN_ROOT/work/$tb"
  mkdir -p "$TEST_WORK"
  LOG="$RUN_ROOT/logs/${tb}.log"
  TAIL="$RUN_ROOT/logs/${tb}.tail"
  MPTDC_TB_PKG="$MPTDC_ROOT/tb/common/mptdc_tb_pkg.sv"
  EXTRA_PKG_ARGS=()
  if grep -q 'mptdc_tb_pkg' "$TB_FILE" && [[ -f "$MPTDC_TB_PKG" ]]; then
    EXTRA_PKG_ARGS=("$MPTDC_TB_PKG")
  fi

  set +e
  (
    cd "$TEST_WORK"
    xrun \
      -64 -sv -access +rwc \
      -timescale 1ps/1ps \
      -nowarn DLCVAR \
      +define+MPTDC_USE_OSC_MODEL \
      +incdir+"$REPO_ROOT" \
      +incdir+"$TOP_ROOT/tb" \
      -f "$RUN_ROOT/mptdc.f" \
      -f "$RUN_ROOT/top.f" \
      "${EXTRA_PKG_ARGS[@]}" \
      "$TB_FILE" \
      -top "$tb" \
      -xmlibdirname "$TEST_WORK/xcelium.d"
  ) > "$LOG" 2>&1
  rc=$?
  set -e

  tail -80 "$LOG" > "$TAIL" || true
  if [[ "$rc" -eq 0 ]] && grep -qE "(PASS|pass / 0 fail|0 FAIL|All tests passed)" "$LOG"; then
    echo "PASS $tb" | tee -a "$RUN_ROOT/test_summary.txt"
    echo "| \`$tb\` | PASS | log: \`logs/${tb}.log\` |" >> "$RUN_ROOT/SUMMARY.md"
    PASS=$((PASS + 1))
  else
    echo "FAIL $tb rc=$rc" | tee -a "$RUN_ROOT/test_summary.txt"
    echo "| \`$tb\` | FAIL | rc=$rc; tail: \`logs/${tb}.tail\` |" >> "$RUN_ROOT/SUMMARY.md"
    append_failure_detail "$tb" "$LOG" "$TAIL"
    FAIL=$((FAIL + 1))
    FAILED_TESTS+=("$tb")
  fi
done

{
  echo
  echo "PASS=$PASS"
  echo "FAIL=$FAIL"
  echo "MISSING=$MISSING"
  if [[ "$FAIL" -gt 0 ]]; then
    echo "FAILED_TESTS=${FAILED_TESTS[*]}"
  fi
  if [[ "$MISSING" -gt 0 ]]; then
    echo "MISSING_TESTS=${MISSING_TESTS[*]}"
  fi
} >> "$RUN_ROOT/test_summary.txt"

append_summary_footer "$PASS" "$FAIL" "$MISSING"

if [[ "$FAIL" -eq 0 && "$MISSING" -eq 0 ]]; then
  exit 0
fi
exit 1
