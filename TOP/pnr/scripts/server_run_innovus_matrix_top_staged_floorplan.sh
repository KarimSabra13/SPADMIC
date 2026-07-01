#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix-top staged Innovus floorplan wrapper
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
RUN_ID="${1:-matrix_top_staged_fp_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"
MATRIX_CSV="${SPADMIC_MATRIX_PIN_CSV:-$REPO_ROOT/position/docs/matrix_handoffs/20260626_matrice3_final_lef_extract_norm/matrice3_pin_coordinates.csv}"
MATRIX_LEF="${SPADMIC_MATRIX_LEF:-/group/validmgr/PROJET/Prj_xh018/ksabra/lef/matrice3.lef}"
PAD_POLICY="${SPADMIC_MATRIX_TOP_PAD_POLICY:-$PNR_ROOT/inputs/matrix_top_pad_policy_template.csv}"
BOX_RING_SOURCE="${SPADMIC_TOP_BOX_RING_SOURCE:-/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/SPADMIC}"
GENERATED_DIR="$RUN_ROOT/generated"

export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
export MPTDC_PNR_SIGNAL_TOP_LAYER="${MPTDC_PNR_SIGNAL_TOP_LAYER:-MET3}"
export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER="${MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER:-METTP}"
export MPTDC_PNR_POWER_LAYER="${MPTDC_PNR_POWER_LAYER:-METTP}"
export MPTDC_PNR_PHASE_TOP_LAYER="${MPTDC_PNR_PHASE_TOP_LAYER:-METTP}"

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
  echo "PAD_POLICY=$PAD_POLICY"
  echo "BOX_RING_SOURCE=$BOX_RING_SOURCE"
  echo "DIE_WIDTH_UM=${SPADMIC_MATRIX_TOP_DIE_WIDTH_UM:-4293.179}"
  echo "DIE_HEIGHT_UM=${SPADMIC_MATRIX_TOP_DIE_HEIGHT_UM:-3209.173}"
  echo "PAD_RING_DEPTH_UM=${SPADMIC_MATRIX_TOP_PAD_KEEPOUT_UM:-164.0}"
  echo "MPTDC_FULL_BOUNDARY_WIDTH_UM=${SPADMIC_MPTDC_FULL_WIDTH_UM:-1061.20}"
  echo "MPTDC_FULL_BOUNDARY_HEIGHT_UM=${SPADMIC_MPTDC_FULL_HEIGHT_UM:-801.92}"
  echo "MPTDC_DIMENSION_MARGIN_PCT=${SPADMIC_MPTDC_DIMENSION_MARGIN_PCT:-5.0}"
  echo "MPTDC_HALO_UM=${SPADMIC_MPTDC_HALO_UM:-20.0}"
  echo "MPTDC_GAP_UM=${SPADMIC_MPTDC_GAP_UM:-20.0}"
  echo "MPTDC_XH018_STACK=$MPTDC_XH018_STACK"
  echo "MPTDC_STDCELL_FAMILY=$MPTDC_STDCELL_FAMILY"
  echo "MPTDC_PNR_ROUTE_LAYER_NAMES=$MPTDC_PNR_ROUTE_LAYER_NAMES"
  echo "MPTDC_PNR_SIGNAL_TOP_LAYER=$MPTDC_PNR_SIGNAL_TOP_LAYER"
  echo "MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER=$MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER"
  echo "BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "STATUS_SHORT_BEGIN"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo "STATUS_SHORT_END"
} > "$RUN_ROOT/run_manifest.txt"
git -C "$REPO_ROOT" status --short > "$RUN_ROOT/git_status_short.txt" 2>/dev/null || true

python3 "$PNR_ROOT/scripts/gen_matrix_top_floorplan_plan.py" \
  --csv "$MATRIX_CSV" \
  --pad-policy "$PAD_POLICY" \
  --out "$GENERATED_DIR" \
  --run-id "$RUN_ID" \
  --die-width-um "${SPADMIC_MATRIX_TOP_DIE_WIDTH_UM:-4293.179}" \
  --die-height-um "${SPADMIC_MATRIX_TOP_DIE_HEIGHT_UM:-3209.173}" \
  --pad-keepout-um "${SPADMIC_MATRIX_TOP_PAD_KEEPOUT_UM:-164.0}" \
  --box-ring-source "$BOX_RING_SOURCE" \
  --matrix-left-margin-um "${SPADMIC_MATRIX_LEFT_MARGIN_UM:-164.0}" \
  --mptdc-width-um "${SPADMIC_MPTDC_FULL_WIDTH_UM:-1061.20}" \
  --mptdc-height-um "${SPADMIC_MPTDC_FULL_HEIGHT_UM:-801.92}" \
  --mptdc-dimension-margin-pct "${SPADMIC_MPTDC_DIMENSION_MARGIN_PCT:-5.0}" \
  --mptdc-halo-um "${SPADMIC_MPTDC_HALO_UM:-20.0}" \
  --mptdc-gap-um "${SPADMIC_MPTDC_GAP_UM:-20.0}" \
  --scenario-a-mptdc-width-um "${SPADMIC_MPTDC_CORE_WIDTH_UM:-1020.88}" \
  --scenario-a-mptdc-height-um "${SPADMIC_MPTDC_CORE_HEIGHT_UM:-761.60}" \
  --scenario-a-mptdc-gap-um "${SPADMIC_MPTDC_CORE_GAP_UM:-40.0}" \
  --horizontal-extension-pct "0.0"

{
  echo "# SPADMIC Matrix TOP Staged Innovus Floorplan Run"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run directory: \`$RUN_ROOT\`"
  echo "- Matrix CSV: \`$MATRIX_CSV\`"
  echo "- Matrix LEF: \`$MATRIX_LEF\`"
  echo "- Pad policy: \`$PAD_POLICY\`"
  echo "- BOX_RING/OA source: \`$BOX_RING_SOURCE\`"
  echo "- XH018 stack: \`$MPTDC_XH018_STACK\`"
  echo "- Standard-cell family: \`$MPTDC_STDCELL_FAMILY\`"
  echo "- Route layers: \`$MPTDC_PNR_ROUTE_LAYER_NAMES\`"
  echo "- Ordinary signal top layer: \`$MPTDC_PNR_SIGNAL_TOP_LAYER\`"
  echo "- Effective top floor layer: \`$MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER\`"
  echo "- Branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
  echo "- Commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- Generated top plan: \`generated/top_floorplan_summary.md\`"
  echo "- Signoff: non-signoff staged floorplan feasibility"
} > "$RUN_ROOT/SUMMARY.md"

PLAN_STATUS="$(awk -F= '$1 == "STATUS" {print $2; exit}' "$GENERATED_DIR/feasibility_status.txt")"
PLAN_ISSUES="$(awk -F= '$1 == "ISSUES" {print $2; exit}' "$GENERATED_DIR/feasibility_status.txt")"

if [[ "$PLAN_STATUS" != "PASS" ]]; then
  {
    echo
    echo "## Result"
    echo
    echo "- Result: STOPPED_BEFORE_INNOVUS"
    echo "- Plan status: \`$PLAN_STATUS\`"
    echo "- Plan issues: \`${PLAN_ISSUES:-none}\`"
    echo
    echo "The staged flow intentionally stops here. Do not run placement until the floorplan geometry is resolved."
  } >> "$RUN_ROOT/SUMMARY.md"
  cat "$RUN_ROOT/SUMMARY.md"
  exit 5
fi

if ! command -v innovus >/dev/null 2>&1; then
  {
    echo
    echo "## Result"
    echo
    echo "- Result: FAIL"
    echo "- First error: \`innovus not found in PATH\`"
    echo "- Plan status before Innovus: \`$PLAN_STATUS\`"
    echo "- Plan issues: \`${PLAN_ISSUES:-none}\`"
  } >> "$RUN_ROOT/SUMMARY.md"
  cat "$RUN_ROOT/SUMMARY.md"
  exit 3
fi

cat > "$RUN_ROOT/run_innovus_staged_floorplan.tcl" <<EOF
set ::env(SPADMIC_INNOVUS_RUN_ROOT) {$RUN_ROOT}
set ::env(SPADMIC_MATRIX_LEF) {$MATRIX_LEF}
set ::env(SPADMIC_MATRIX_TOP_REGIONS_TCL) {$GENERATED_DIR/top_floorplan_regions.tcl}
source {$PNR_ROOT/templates/matrix_top_staged_floorplan.tcl}
exit
EOF

set +e
innovus -no_gui -files "$RUN_ROOT/run_innovus_staged_floorplan.tcl" \
  > "$RUN_ROOT/logs/innovus_staged_floorplan.stdout.log" 2>&1
rc=$?
set -e

tail -120 "$RUN_ROOT/logs/innovus_staged_floorplan.stdout.log" \
  > "$RUN_ROOT/logs/innovus_staged_floorplan.tail" || true

{
  echo
  echo "## Result"
  echo
  echo "- Innovus exit code: $rc"
  if [[ "$rc" -eq 0 ]]; then
    echo "- Result: PASS for staged planning-seed execution only"
  else
    echo "- Result: FAIL, see \`logs/innovus_staged_floorplan.tail\`"
  fi
  echo
  echo "This is not placement, route, CTS, DRC/LVS, PG, PEX, MMMC, or signoff."
} >> "$RUN_ROOT/SUMMARY.md"

cat "$RUN_ROOT/SUMMARY.md"
exit "$rc"
