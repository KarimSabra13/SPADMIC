#!/usr/bin/env bash
# Replay a same-block GUI PVS DRC template inside an immutable handoff package.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=TOP/pnr/scripts/lib_pvs_handoff.sh
source "$SCRIPT_DIR/lib_pvs_handoff.sh"

PACKAGE=""
TEMPLATE=""
TEMPLATE_GDS=""
TEMPLATE_TOP=""
VARIANT="base"
RUN_ID=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: run_pvs_drc_handoff.sh --package DIR --template DIR \
  --template-gds FILE --template-top CELL [--variant base|density] \
  [--run-id ID] [--dry-run]

The GUI template must be for the same block/hierarchy. The script clones it;
the original template remains read-only.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package) PACKAGE="$2"; shift 2 ;;
    --template) TEMPLATE="$2"; shift 2 ;;
    --template-gds) TEMPLATE_GDS="$2"; shift 2 ;;
    --template-top) TEMPLATE_TOP="$2"; shift 2 ;;
    --variant) VARIANT="$2"; shift 2 ;;
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
[[ -n "$TEMPLATE_GDS" && -n "$TEMPLATE_TOP" ]] || spadmic_pvs_die "template GDS and top are required"
[[ "$VARIANT" == "base" || "$VARIANT" == "density" ]] \
  || spadmic_pvs_die "DRC variant must be base or density"
spadmic_pvs_check_head "$REPO_ROOT"
PVS_BIN="$(spadmic_pvs_binary)"
NAME="$(spadmic_pvs_manifest_value "$PACKAGE" layout_top)"
GDS="$PACKAGE/gds/$NAME.gds"
spadmic_pvs_require_file "$GDS"
python3 "$SCRIPT_DIR/audit_innovus_handoff.py" "$PACKAGE"
HANDOFF_AUDIT_RC=$?
echo "HANDOFF_AUDIT_RC=$HANDOFF_AUDIT_RC"
[[ "$HANDOFF_AUDIT_RC" -eq 0 ]] || exit "$HANDOFF_AUDIT_RC"
RUN_ID="${RUN_ID:-drc_${VARIANT}_$(date +%Y%m%d_%H%M%S)}"
RUN_DIR="$PACKAGE/pvs/drc/$RUN_ID"

REPLAY_ARGS=(--mode drc --template "$TEMPLATE" --run-dir "$RUN_DIR" --cadence-pvs "$PVS_BIN"
  --replace "$TEMPLATE_GDS=$GDS" --replace "$TEMPLATE_TOP=$NAME"
  --expected-layout-top "$NAME" --expected-gds "$GDS")
if [[ "$VARIANT" == "density" ]]; then
  REPLAY_ARGS+=(--preprocessor-define DENSITY)
else
  REPLAY_ARGS+=(--preprocessor-undefine DENSITY)
fi
python3 "$SCRIPT_DIR/replay_pvs_handoff_template.py" "${REPLAY_ARGS[@]}"
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
    echo "PVS_DRC_STATUS=DRY_RUN_READY"
    echo "PVS_DRC_VARIANT=${VARIANT^^}"
    echo "PACKAGE=$PACKAGE"
    echo "GDS=$GDS"
    echo "GDS_SHA256=$(sha256sum "$GDS" | awk '{print $1}')"
  } | tee "$RUN_DIR/pvs_drc_status.rpt"
  spadmic_pvs_hash_run "$RUN_DIR"
  exit 0
fi

(cd "$RUN_DIR" && bash ./run.pvs) >"$RUN_DIR/pvs.stdout.log" 2>&1
PVS_RC=$?
python3 "$SCRIPT_DIR/parse_pvs_handoff_result.py" --mode drc --run-dir "$RUN_DIR" \
  --status "$RUN_DIR/pvs_drc_status.rpt" --tool-rc "$PVS_RC"
PARSE_RC=$?
echo "PVS_DRC_VARIANT=${VARIANT^^}" >> "$RUN_DIR/pvs_drc_status.rpt"
echo "PACKAGE=$PACKAGE" >> "$RUN_DIR/pvs_drc_status.rpt"
echo "GDS=$GDS" >> "$RUN_DIR/pvs_drc_status.rpt"
echo "GDS_SHA256=$(sha256sum "$GDS" | awk '{print $1}')" >> "$RUN_DIR/pvs_drc_status.rpt"
spadmic_pvs_hash_run "$RUN_DIR"
echo "PVS_RC=$PVS_RC"
echo "PARSE_RC=$PARSE_RC"
exit "$PARSE_RC"
