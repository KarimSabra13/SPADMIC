#!/usr/bin/env bash
# Replay a same-block GUI PVS LVS template inside an immutable handoff package.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=TOP/pnr/scripts/lib_pvs_handoff.sh
source "$SCRIPT_DIR/lib_pvs_handoff.sh"

PACKAGE=""
TEMPLATE=""
TEMPLATE_GDS=""
TEMPLATE_SOURCE=""
TEMPLATE_LAYOUT_TOP=""
TEMPLATE_SOURCE_TOP=""
TEMPLATE_CDL=""
TEMPLATE_HCELL=""
HCELL=""
RUN_ID=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: run_pvs_lvs_handoff.sh --package DIR --template DIR \
  --template-gds FILE --template-source FILE \
  --template-layout-top CELL --template-source-top CELL \
  --template-cdl FILE [--template-hcell FILE --hcell FILE] \
  [--run-id ID] [--dry-run]

Create the first LVS template once in the PVS GUI for the same hierarchy,
then use this wrapper for deterministic replay. MATCH is never inferred from
return code alone.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) PACKAGE="$2"; shift 2 ;;
    --template) TEMPLATE="$2"; shift 2 ;;
    --template-gds) TEMPLATE_GDS="$2"; shift 2 ;;
    --template-source) TEMPLATE_SOURCE="$2"; shift 2 ;;
    --template-layout-top) TEMPLATE_LAYOUT_TOP="$2"; shift 2 ;;
    --template-source-top) TEMPLATE_SOURCE_TOP="$2"; shift 2 ;;
    --template-cdl) TEMPLATE_CDL="$2"; shift 2 ;;
    --template-hcell) TEMPLATE_HCELL="$2"; shift 2 ;;
    --hcell) HCELL="$2"; shift 2 ;;
    --run-id) RUN_ID="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; spadmic_pvs_die "unknown option: $1" ;;
  esac
done

spadmic_pvs_require_dir "$PACKAGE"
spadmic_pvs_require_dir "$TEMPLATE"
PACKAGE="$(cd "$PACKAGE" && pwd -P)"
TEMPLATE="$(cd "$TEMPLATE" && pwd -P)"
for value in "$TEMPLATE_GDS" "$TEMPLATE_SOURCE" "$TEMPLATE_LAYOUT_TOP" "$TEMPLATE_SOURCE_TOP" "$TEMPLATE_CDL"; do
  [[ -n "$value" ]] || spadmic_pvs_die "all template GDS/source/top values are required"
done
spadmic_pvs_check_head "$REPO_ROOT"
PVS_BIN="$(spadmic_pvs_binary)"
LAYOUT_TOP="$(spadmic_pvs_manifest_value "$PACKAGE" layout_top)"
SOURCE_TOP="$(spadmic_pvs_manifest_value "$PACKAGE" source_top)"
GDS="$PACKAGE/gds/$LAYOUT_TOP.gds"
SOURCE="$PACKAGE/netlist/$SOURCE_TOP.lvs.pg.v"
spadmic_pvs_require_file "$GDS"
spadmic_pvs_require_file "$SOURCE"
python3 "$SCRIPT_DIR/audit_innovus_handoff.py" "$PACKAGE"
HANDOFF_AUDIT_RC=$?
echo "HANDOFF_AUDIT_RC=$HANDOFF_AUDIT_RC"
[[ "$HANDOFF_AUDIT_RC" -eq 0 ]] || exit "$HANDOFF_AUDIT_RC"
SOURCE_PREP_STATUS="$PACKAGE/reports/lvs_source_preparation.rpt"
spadmic_pvs_require_file "$SOURCE_PREP_STATUS"
grep -q '^STATUS=PASS$' "$SOURCE_PREP_STATUS" \
  || spadmic_pvs_die "canonical LVS source preparation did not pass"
grep -q '^PIN_PARITY_STATUS=PASS$' "$SOURCE_PREP_STATUS" \
  || spadmic_pvs_die "LEF/source top pin parity did not pass"
RUN_ID="${RUN_ID:-lvs_$(date +%Y%m%d_%H%M%S)}"
RUN_DIR="$PACKAGE/pvs/lvs/$RUN_ID"

ARGS=(--mode lvs --template "$TEMPLATE" --run-dir "$RUN_DIR" --cadence-pvs "$PVS_BIN"
  --replace "$TEMPLATE_GDS=$GDS" --replace "$TEMPLATE_SOURCE=$SOURCE"
  --replace "$TEMPLATE_LAYOUT_TOP=$LAYOUT_TOP" --replace "$TEMPLATE_SOURCE_TOP=$SOURCE_TOP"
  --expected-layout-top "$LAYOUT_TOP" --expected-source-top "$SOURCE_TOP"
  --expected-gds "$GDS" --expected-source "$SOURCE")
CDL="$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"
spadmic_pvs_require_file "$CDL"
ARGS+=(--replace "$TEMPLATE_CDL=$CDL" --expected-cdl "$CDL")
if [[ -n "$TEMPLATE_HCELL" || -n "$HCELL" ]]; then
  [[ -n "$TEMPLATE_HCELL" && -n "$HCELL" ]] || spadmic_pvs_die "both template and new HCell paths are required"
  spadmic_pvs_require_file "$HCELL"
  ARGS+=(--replace "$TEMPLATE_HCELL=$HCELL")
fi
python3 "$SCRIPT_DIR/replay_pvs_handoff_template.py" "${ARGS[@]}"
PATCH_RC=$?
echo "PATCH_RC=$PATCH_RC"
[[ "$PATCH_RC" -eq 0 ]] || exit "$PATCH_RC"
grep -q '^STATUS=PASS$' "$RUN_DIR/replay_contract_status.rpt" \
  || spadmic_pvs_die "strict PVS replay contract did not pass"
grep -q '^STATUS=PASS$' "$RUN_DIR/output_isolation.rpt" \
  || spadmic_pvs_die "PVS execution/output isolation did not pass"
spadmic_pvs_require_external_references "$RUN_DIR/external_references.rpt"

if [[ "$DRY_RUN" -eq 1 ]]; then
  {
    echo "PVS_LVS_STATUS=DRY_RUN_READY"
    echo "PACKAGE=$PACKAGE"
    echo "GDS=$GDS"
    echo "GDS_SHA256=$(sha256sum "$GDS" | awk '{print $1}')"
    echo "LVS_SOURCE=$SOURCE"
    echo "LVS_SOURCE_SHA256=$(sha256sum "$SOURCE" | awk '{print $1}')"
  } | tee "$RUN_DIR/pvs_lvs_status.rpt"
  spadmic_pvs_hash_run "$RUN_DIR"
  exit 0
fi

(cd "$RUN_DIR" && bash ./run.pvs) >"$RUN_DIR/pvs.stdout.log" 2>&1
PVS_RC=$?
python3 "$SCRIPT_DIR/parse_pvs_handoff_result.py" --mode lvs --run-dir "$RUN_DIR" \
  --status "$RUN_DIR/pvs_lvs_status.rpt" --tool-rc "$PVS_RC"
PARSE_RC=$?
echo "PACKAGE=$PACKAGE" >> "$RUN_DIR/pvs_lvs_status.rpt"
echo "GDS=$GDS" >> "$RUN_DIR/pvs_lvs_status.rpt"
echo "GDS_SHA256=$(sha256sum "$GDS" | awk '{print $1}')" >> "$RUN_DIR/pvs_lvs_status.rpt"
echo "LVS_SOURCE=$SOURCE" >> "$RUN_DIR/pvs_lvs_status.rpt"
echo "LVS_SOURCE_SHA256=$(sha256sum "$SOURCE" | awk '{print $1}')" >> "$RUN_DIR/pvs_lvs_status.rpt"
spadmic_pvs_hash_run "$RUN_DIR"
echo "PVS_RC=$PVS_RC"
echo "PARSE_RC=$PARSE_RC"
exit "$PARSE_RC"
