#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$SYN_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_current_head_genus_baseline}"
SNAPSHOT_TAG="genus_${RUN_ID}"
RESULT_DIR="$REPO_ROOT/results/genus/$RUN_ID"
SNAPSHOT_DIR="$MPTDC_DIR/lab_snapshots/$SNAPSHOT_TAG"
GENUS_LOG="$RESULT_DIR/genus_${RUN_ID}.log"

mkdir -p "$RESULT_DIR" "$SYN_DIR/logs"

{
  echo "Run ID: $RUN_ID"
  echo "Snapshot tag: $SNAPSHOT_TAG"
  echo "Date: $(date -Iseconds)"
  echo "Repository root: $REPO_ROOT"
  echo "Branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "HEAD: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo
  echo "git status --short:"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
} | tee "$RESULT_DIR/run_manifest.txt"

if ! command -v genus >/dev/null 2>&1; then
  {
    echo "ERROR: genus not found in PATH."
    echo "This script must be run on the lab server with Cadence Genus available."
  } | tee -a "$GENUS_LOG"
  GENUS_RC=127
else
  echo "[GENUS] Starting synthesis flow"
  (
    cd "$SCRIPT_DIR"
    genus -files genus.tcl -log ../logs/genus.log
  ) 2>&1 | tee "$GENUS_LOG"
  GENUS_RC=${PIPESTATUS[0]}
fi

echo "[SNAPSHOT] Collecting Genus snapshot into $SNAPSHOT_DIR"
if bash "$SCRIPT_DIR/collect_snapshot.sh" "$SNAPSHOT_TAG" >> "$GENUS_LOG" 2>&1; then
  SNAPSHOT_RC=0
else
  SNAPSHOT_RC=$?
  echo "WARNING: collect_snapshot.sh failed with rc=$SNAPSHOT_RC" | tee -a "$GENUS_LOG"
fi

if [[ -d "$SNAPSHOT_DIR" ]]; then
  cp -a "$SNAPSHOT_DIR/." "$RESULT_DIR/"
fi

cp "$GENUS_LOG" "$RESULT_DIR/genus_${RUN_ID}.log" 2>/dev/null || true

extract_first_match() {
  local file="$1"
  local pattern="$2"
  if [[ -f "$file" ]]; then
    grep -Ei "$pattern" "$file" | head -1 | sed 's/[[:space:]]\+$//'
  fi
}

TIMING_SUMMARY="$RESULT_DIR/timing_summary.rpt"
TIMING_VIOLATIONS="$RESULT_DIR/timing_violations.rpt"
REPORT_QOR="$RESULT_DIR/report_qor.rpt"
REPORT_AREA="$RESULT_DIR/report_area.rpt"
REPORT_DRC="$RESULT_DIR/report_design_rules.rpt"
LATCH_AUDIT="$RESULT_DIR/latch_audit.rpt"
CDC_AUDIT="$RESULT_DIR/cdc_manual_audit.rpt"

WNS_LINE="$(extract_first_match "$TIMING_SUMMARY" 'WNS|worst.*slack|slack')"
TNS_LINE="$(extract_first_match "$TIMING_SUMMARY" 'TNS|total.*negative')"
VIOL_LINE="$(extract_first_match "$TIMING_SUMMARY" 'violat|endpoint|path')"
AREA_LINE="$(extract_first_match "$REPORT_AREA" 'total|area')"
QOR_LINE="$(extract_first_match "$REPORT_QOR" 'WNS|TNS|area|instances|sequential|combinational')"
DRC_LINE="$(extract_first_match "$REPORT_DRC" 'violat|transition|capacitance|fanout')"
LATCH_LINE="$(extract_first_match "$LATCH_AUDIT" 'latch|EXPECTED|PASS|FAIL')"
CDC_LINE="$(extract_first_match "$CDC_AUDIT" 'CDC|held|PASS|FAIL|waiver')"

{
  echo "# Genus Server Run Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Snapshot tag: \`$SNAPSHOT_TAG\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Genus exit code: $GENUS_RC"
  echo "- Snapshot exit code: ${SNAPSHOT_RC:-0}"
  echo "- Result directory: \`results/genus/$RUN_ID/\`"
  echo "- Lab snapshot: \`MPTDC/lab_snapshots/$SNAPSHOT_TAG/\`"
  echo
  echo "## Extracted Lines"
  echo
  echo "- WNS line: ${WNS_LINE:-not found}"
  echo "- TNS line: ${TNS_LINE:-not found}"
  echo "- Violation line: ${VIOL_LINE:-not found}"
  echo "- QoR line: ${QOR_LINE:-not found}"
  echo "- Area line: ${AREA_LINE:-not found}"
  echo "- Design-rule line: ${DRC_LINE:-not found}"
  echo "- Latch audit line: ${LATCH_LINE:-not found}"
  echo "- CDC audit line: ${CDC_LINE:-not found}"
  echo
  echo "## Key Files Present"
  echo
  for file in \
    "genus_${RUN_ID}.log" \
    timing_violations.rpt \
    timing_summary.rpt \
    report_design_rules.rpt \
    check_timing_intent.rpt \
    latch_audit.rpt \
    cdc_manual_audit.rpt \
    timing_meas_ctrl_hotspots.rpt \
    timing_context_bank_hotspots.rpt \
    timing_drain_ctrl_hotspots.rpt \
    timing_fifo_hotspots.rpt \
    report_clocks.rpt \
    report_clocks_generated.rpt \
    report_constraints.rpt \
    report_qor.rpt \
    report_area.rpt; do
    if [[ -f "$RESULT_DIR/$file" ]]; then
      echo "- present: \`$file\`"
    else
      echo "- missing: \`$file\`"
    fi
  done
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"

if [[ $GENUS_RC -ne 0 ]]; then
  exit "$GENUS_RC"
fi
if [[ ${SNAPSHOT_RC:-0} -ne 0 ]]; then
  exit "$SNAPSHOT_RC"
fi

exit 0

