#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix-top — server Innovus floorplan feasibility wrapper
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
RUN_ID="${1:-matrix_top_innovus_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"
MATRIX_CSV="${SPADMIC_MATRIX_PIN_CSV:-$REPO_ROOT/position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv}"
MATRIX_LEF="${SPADMIC_MATRIX_LEF:-/group/validmgr/PROJET/Prj_xh018/ksabra/lef/matrice3.lef}"
GENERATED_DIR="$RUN_ROOT/generated"

if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: run directory already exists: $RUN_ROOT" >&2
  exit 2
fi

mkdir -p "$RUN_ROOT/logs" "$RUN_ROOT/reports" "$GENERATED_DIR"

{
  echo "RUN_ID=$RUN_ID"
  echo "DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "RUN_ROOT=$RUN_ROOT"
  echo "MATRIX_CSV=$MATRIX_CSV"
  echo "MATRIX_LEF=$MATRIX_LEF"
  echo "BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "STATUS_SHORT_BEGIN"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo "STATUS_SHORT_END"
} > "$RUN_ROOT/run_manifest.txt"
git -C "$REPO_ROOT" status --short > "$RUN_ROOT/git_status_short.txt" 2>/dev/null || true

python3 "$PNR_ROOT/scripts/gen_matrix_floorplan_from_csv.py" \
  --csv "$MATRIX_CSV" \
  --out "$GENERATED_DIR" \
  --run-id "$RUN_ID"

{
  echo "# SPADMIC Matrix TOP Innovus Floorplan Run"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run directory: \`$RUN_ROOT\`"
  echo "- Matrix CSV: \`$MATRIX_CSV\`"
  echo "- Matrix LEF: \`$MATRIX_LEF\`"
  echo "- Branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
  echo "- Commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- Generated pin plan: \`generated/floorplan_summary.md\`"
  echo "- Signoff: non-signoff floorplan feasibility"
} > "$RUN_ROOT/SUMMARY.md"

if ! command -v innovus >/dev/null 2>&1; then
  {
    echo
    echo "## Result"
    echo
    echo "- Result: FAIL"
    echo "- First error: \`innovus not found in PATH\`"
    echo
    echo "Source \`/eda/cadence/eda_2023-2024\` on the server before running this script."
    echo "The CSV-driven floorplan collateral was still generated locally in the run directory."
  } >> "$RUN_ROOT/SUMMARY.md"
  cat "$RUN_ROOT/SUMMARY.md"
  exit 3
fi

cat > "$RUN_ROOT/run_innovus_floorplan_seed.tcl" <<EOF
set ::env(SPADMIC_INNOVUS_RUN_ROOT) {$RUN_ROOT}
set ::env(SPADMIC_MATRIX_LEF) {$MATRIX_LEF}
set ::env(SPADMIC_MATRIX_REGIONS_TCL) {$GENERATED_DIR/matrix_floorplan_regions.tcl}
source {$PNR_ROOT/templates/matrix_top_floorplan_seed.tcl}
exit
EOF

set +e
innovus -no_gui -files "$RUN_ROOT/run_innovus_floorplan_seed.tcl" \
  > "$RUN_ROOT/logs/innovus_floorplan_seed.stdout.log" 2>&1
rc=$?
set -e

tail -100 "$RUN_ROOT/logs/innovus_floorplan_seed.stdout.log" \
  > "$RUN_ROOT/logs/innovus_floorplan_seed.tail" || true

{
  echo
  echo "## Result"
  echo
  echo "- Innovus exit code: $rc"
  if [[ "$rc" -eq 0 ]]; then
    echo "- Result: PASS for planning-seed execution only"
  else
    echo "- Result: FAIL, see \`logs/innovus_floorplan_seed.tail\`"
  fi
  echo
  echo "This is not placement, route, CTS, DRC/LVS, PG, or signoff."
} >> "$RUN_ROOT/SUMMARY.md"

cat "$RUN_ROOT/SUMMARY.md"
exit "$rc"

