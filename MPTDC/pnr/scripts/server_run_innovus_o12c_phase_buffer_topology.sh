#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-20260608_o12c_phase_buffer_topology}"
SOURCE_RUN_ID="${MPTDC_O12C_SOURCE_RUN_ID:-20260608_o12_phase_buffer_pnr_abs1}"
RUN_MODE="${MPTDC_O12C_MODE:-report_only}"
if [[ "${MPTDC_O12C_VALIDATE_ONLY:-0}" == "1" ]]; then
  RUN_MODE="validate_only"
fi

RESULT_DIR="$REPO_ROOT/results/innovus/$RUN_ID"
LOG_DIR="$RESULT_DIR/logs"
MANIFEST_DIR="$RESULT_DIR/manifests"
mkdir -p "$LOG_DIR" "$MANIFEST_DIR"

SUMMARY="$RESULT_DIR/SUMMARY.md"
RUN_LOG="$LOG_DIR/o12c_phase_buffer_topology_wrapper.log"

case "$RUN_MODE" in
  validate_only|report_only|buhdx4_place|buhdx8_place|buhdx12_place|twostage_place) ;;
  *)
    echo "ERROR: unsupported MPTDC_O12C_MODE=$RUN_MODE" | tee "$RUN_LOG"
    echo "Supported: validate_only, report_only, buhdx4_place, buhdx8_place, buhdx12_place, twostage_place" | tee -a "$RUN_LOG"
    exit 2
    ;;
esac

{
  echo "# O12C Phase Buffer Topology Wrapper"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "run_id: $RUN_ID"
  echo "run_mode: $RUN_MODE"
  echo "source_run_id: $SOURCE_RUN_ID"
  echo "labels: O12C_PHASE_BUFFER_TOPOLOGY_AND_PLACEMENT_CLOSURE NOT_FINAL_SIGNOFF"
  echo
  echo "git status --short --untracked-files=no:"
  git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null || true
} | tee "$MANIFEST_DIR/run_manifest.txt" | tee "$RUN_LOG"

if [[ "$RUN_MODE" == "validate_only" || "$RUN_MODE" == "report_only" ]]; then
  export MPTDC_O12B_SOURCE_RUN_ID="$SOURCE_RUN_ID"
  export MPTDC_O12B_NET_DEBUG="${MPTDC_O12C_NET_DEBUG:-1}"
  if [[ "$RUN_MODE" == "validate_only" ]]; then
    export MPTDC_O12B_VALIDATE_ONLY=1
  else
    unset MPTDC_O12B_VALIDATE_ONLY
  fi
  bash "$SCRIPT_DIR/server_run_innovus_o12b_phase_buffer_balance.sh" "$RUN_ID" 2>&1 | tee -a "$RUN_LOG"
  RC=${PIPESTATUS[0]}
  {
    echo
    echo "# O12C Wrapper Overlay"
    echo
    echo "- O12C run mode: \`$RUN_MODE\`"
    echo "- Report engine: patched O12B phase-buffer balance reporter."
    echo "- Source run: \`$SOURCE_RUN_ID\`"
    echo "- Wrapper result: \`$RC\`"
    echo "- Signoff: \`NO\`"
  } >> "$SUMMARY" 2>/dev/null || true
  exit "$RC"
fi

{
  echo "# O12C Phase Buffer Topology Wrapper Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run mode: \`$RUN_MODE\`"
  echo "- Source run ID: \`$SOURCE_RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- REPORT_COMPLETE: \`NO\`"
  echo "- Labels: \`O12C_PHASE_BUFFER_TOPOLOGY_AND_PLACEMENT_CLOSURE\`, \`NOT_FINAL_SIGNOFF\`"
  echo
  echo "Placement modes are prepared as Tcl hooks but are not auto-run from a routed checkpoint."
  echo "Use \`MPTDC/pnr/scripts/innovus_o12c_phase_buffer_place.tcl\` inside a fresh placement/routing experiment after selecting explicit buffer row origins."
  echo
  echo "Required origin variables before using the placement hook:"
  echo
  echo "- \`MPTDC_O12C_SLOW_BUF_X\`"
  echo "- \`MPTDC_O12C_SLOW_BUF_Y\`"
  echo "- \`MPTDC_O12C_FAST_BUF_X\`"
  echo "- \`MPTDC_O12C_FAST_BUF_Y\`"
  echo "- optional: \`MPTDC_O12C_PHASE_BUF_PITCH_UM\`"
  echo "- optional: \`MPTDC_O12C_PHASE_BUF_ORIENT\`"
} | tee "$SUMMARY" | tee -a "$RUN_LOG"

exit 2
