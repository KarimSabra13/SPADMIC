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
RUN_ID=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: run_pvs_drc_handoff.sh --package DIR --template DIR \
  --template-gds FILE --template-top CELL [--run-id ID] [--dry-run]

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
    --run-id) RUN_ID="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; spadmic_pvs_die "unknown option: $1" ;;
  esac
done

spadmic_pvs_require_dir "$PACKAGE"
spadmic_pvs_require_dir "$TEMPLATE"
[[ -n "$TEMPLATE_GDS" && -n "$TEMPLATE_TOP" ]] || spadmic_pvs_die "template GDS and top are required"
spadmic_pvs_check_head "$REPO_ROOT"
PVS_BIN="$(spadmic_pvs_binary)"
NAME="$(spadmic_pvs_manifest_value "$PACKAGE" layout_top)"
GDS="$PACKAGE/gds/$NAME.gds"
spadmic_pvs_require_file "$GDS"
RUN_ID="${RUN_ID:-drc_$(date +%Y%m%d_%H%M%S)}"
RUN_DIR="$PACKAGE/pvs/drc/$RUN_ID"

python3 "$SCRIPT_DIR/replay_pvs_handoff_template.py" \
  --mode drc --template "$TEMPLATE" --run-dir "$RUN_DIR" --cadence-pvs "$PVS_BIN" \
  --replace "$TEMPLATE_GDS=$GDS" --replace "$TEMPLATE_TOP=$NAME"
PATCH_RC=$?
echo "PATCH_RC=$PATCH_RC"
[[ "$PATCH_RC" -eq 0 ]] || exit "$PATCH_RC"
spadmic_pvs_require_external_references "$RUN_DIR/external_references.rpt"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "PVS_DRC_STATUS=DRY_RUN_READY" | tee "$RUN_DIR/pvs_drc_status.rpt"
  spadmic_pvs_hash_run "$RUN_DIR"
  exit 0
fi

(cd "$RUN_DIR" && bash ./run.pvs) >"$RUN_DIR/pvs.stdout.log" 2>&1
PVS_RC=$?
python3 "$SCRIPT_DIR/parse_pvs_handoff_result.py" --mode drc --run-dir "$RUN_DIR" \
  --status "$RUN_DIR/pvs_drc_status.rpt" --tool-rc "$PVS_RC"
PARSE_RC=$?
spadmic_pvs_hash_run "$RUN_DIR"
echo "PVS_RC=$PVS_RC"
echo "PARSE_RC=$PARSE_RC"
exit "$PARSE_RC"
