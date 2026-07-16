#!/usr/bin/env bash
# Open a validated PVS LVS run from a disposable review copy.

set -u -o pipefail

RUN_DIR=""
VIEW="results"
REVIEW_ROOT="${TMPDIR:-/tmp}/${USER:-unknown}/spadmic_pvs_lvs_gui_review"
PREPARE_ONLY=0
GUI_BIN=""

usage() {
  cat <<'EOF'
Usage:
  open_pvs_lvs_gui_review.sh --run-dir DIR [--view results|setup]
    [--review-root DIR] [--gui-bin FILE] [--prepare-only]

The source PVS run must contain an explicit report-level LVS MATCH. The script
copies the complete run to a new disposable directory before opening Cadence:

  results  open the PVS LVS debug/result browser
  setup    open the PVS GUI with the copied LVS preset

The source run is never opened directly because Cadence GUIs may write locks,
presets, indexes, or review state.
EOF
}

die() {
  echo "STOP_HERE_DO_NOT_CONTINUE: $*" >&2
  exit 1
}

kv_field() {
  local path="$1"
  local key="$2"
  awk -F= -v key="$key" \
    '$1 == key {value = substr($0, index($0, "=") + 1)} END {print value}' \
    "$path"
}

resolve_gui_bin() {
  local name="$1"
  local candidate

  if [[ -n "$GUI_BIN" ]]; then
    [[ -x "$GUI_BIN" ]] || die "requested GUI binary is not executable: $GUI_BIN"
    printf '%s\n' "$GUI_BIN"
    return 0
  fi

  candidate="$(command -v "$name" 2>/dev/null)"
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  for candidate in \
    "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/$name" \
    "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/tools/bin/$name" \
    "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/tools.lnx86/pvs/bin/64bit/$name"
  do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      RUN_DIR="$2"
      shift 2
      ;;
    --view)
      VIEW="$2"
      shift 2
      ;;
    --review-root)
      REVIEW_ROOT="$2"
      shift 2
      ;;
    --gui-bin)
      GUI_BIN="$2"
      shift 2
      ;;
    --prepare-only)
      PREPARE_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "unknown option: $1"
      ;;
  esac
done

[[ -n "$RUN_DIR" ]] || die "--run-dir is required"
[[ "$VIEW" == "results" || "$VIEW" == "setup" ]] \
  || die "--view must be results or setup"
[[ -d "$RUN_DIR" ]] || die "PVS LVS run directory is missing: $RUN_DIR"
RUN_DIR="$(cd "$RUN_DIR" && pwd -P)"

STATUS_REPORT="$RUN_DIR/pvs_lvs_status.rpt"
REPLAY_REPORT="$RUN_DIR/replay_contract_status.rpt"
ISOLATION_REPORT="$RUN_DIR/output_isolation.rpt"
REFERENCE_REPORT="$RUN_DIR/external_references.rpt"
INVENTORY_REPORT="$RUN_DIR/pvs_result_evidence_inventory.rpt"

for required in \
  "$STATUS_REPORT" \
  "$REPLAY_REPORT" \
  "$ISOLATION_REPORT" \
  "$REFERENCE_REPORT" \
  "$INVENTORY_REPORT" \
  "$RUN_DIR/pvs_file.index" \
  "$RUN_DIR/.preset.autosave" \
  "$RUN_DIR/pvslvsctl" \
  "$RUN_DIR/svdb/matched"
do
  [[ -s "$required" ]] || die "required LVS review evidence is missing or empty: $required"
done

[[ "$(kv_field "$STATUS_REPORT" PVS_RC)" == "0" ]] \
  || die "PVS tool return code is not zero"
[[ "$(kv_field "$STATUS_REPORT" PVS_LVS_STATUS)" == "MATCH" ]] \
  || die "PVS LVS status is not MATCH"
[[ "$(kv_field "$STATUS_REPORT" LVS_NEGATIVE_MATCH_COUNT)" == "0" ]] \
  || die "negative LVS result evidence is present"
POSITIVE_COUNT="$(kv_field "$STATUS_REPORT" LVS_POSITIVE_MATCH_COUNT)"
[[ "$POSITIVE_COUNT" =~ ^[0-9]+$ && "$POSITIVE_COUNT" -gt 0 ]] \
  || die "no positive report-level LVS result evidence is present"
[[ "$(kv_field "$REPLAY_REPORT" STATUS)" == "PASS" ]] \
  || die "strict PVS replay contract did not pass"
[[ "$(kv_field "$REPLAY_REPORT" MODE)" == "LVS" ]] \
  || die "replay contract mode is not LVS"
[[ "$(kv_field "$ISOLATION_REPORT" STATUS)" == "PASS" ]] \
  || die "PVS output isolation did not pass"
if grep -q '^MISSING=' "$REFERENCE_REPORT"; then
  die "the run contains missing external references"
fi

mkdir -p "$REVIEW_ROOT" || die "cannot create GUI review root: $REVIEW_ROOT"
STAMP="$(date -u +%Y%m%d_%H%M%S)"
REVIEW_DIR="$REVIEW_ROOT/$(basename "$RUN_DIR")_${VIEW}_${STAMP}"
[[ ! -e "$REVIEW_DIR" ]] || die "GUI review directory already exists: $REVIEW_DIR"
mkdir -p "$REVIEW_DIR" || die "cannot create GUI review directory: $REVIEW_DIR"
cp -a "$RUN_DIR/." "$REVIEW_DIR/" \
  || die "failed to copy the immutable LVS run into the GUI review directory"

python3 - "$RUN_DIR" "$REVIEW_DIR" <<'PY'
from pathlib import Path
import sys

source = sys.argv[1]
review = Path(sys.argv[2])

for path in review.rglob("*"):
    if not path.is_file() or path.is_symlink() or path.stat().st_size > 20 * 1024 * 1024:
        continue
    try:
        text = path.read_text()
    except (UnicodeDecodeError, OSError):
        continue
    if source in text:
        path.write_text(text.replace(source, str(review)))
PY
PATCH_RC=$?
[[ "$PATCH_RC" -eq 0 ]] || die "failed to relocate copied GUI metadata"

SOURCE_STATUS_SHA256="$(sha256sum "$STATUS_REPORT" | awk '{print $1}')"
SOURCE_MATCH_SHA256="$(sha256sum "$RUN_DIR/svdb/matched" | awk '{print $1}')"
{
  echo "LABEL=SPADMIC_PVS_LVS_GUI_REVIEW_COPY"
  echo "STATUS=PASS"
  echo "SOURCE_RUN_DIR=$RUN_DIR"
  echo "REVIEW_DIR=$REVIEW_DIR"
  echo "VIEW=$VIEW"
  echo "SOURCE_PVS_LVS_STATUS=MATCH"
  echo "SOURCE_PVS_LVS_STATUS_SHA256=$SOURCE_STATUS_SHA256"
  echo "SOURCE_SVDB_MATCHED_SHA256=$SOURCE_MATCH_SHA256"
  echo "SOURCE_RUN_MUTATION_AUTHORIZED=NO"
  echo "GUI_REVIEW_COPY_DISPOSABLE=YES"
} >"$REVIEW_DIR/gui_review_origin.rpt"

echo "LABEL=SPADMIC_PVS_LVS_GUI_REVIEW"
echo "STATUS=PASS"
echo "PVS_LVS_STATUS=MATCH"
echo "LVS_NEGATIVE_MATCH_COUNT=0"
echo "LVS_POSITIVE_MATCH_COUNT=$POSITIVE_COUNT"
echo "SOURCE_RUN_DIR=$RUN_DIR"
echo "GUI_REVIEW_DIR=$REVIEW_DIR"
echo "VIEW=$VIEW"
echo "SOURCE_RUN_MUTATION_AUTHORIZED=NO"

if [[ "$PREPARE_ONLY" -eq 1 ]]; then
  echo "GUI_LAUNCH=NOT_RUN_PREPARE_ONLY"
  exit 0
fi

[[ -n "${DISPLAY:-}" ]] \
  || die "DISPLAY is unset; reconnect to the server with trusted X11 forwarding before launching the GUI"

if [[ -r /eda/cadence/eda_2023-2024 ]]; then
  # shellcheck disable=SC1091
  set +u
  source /eda/cadence/eda_2023-2024
  set -u
fi

if [[ "$VIEW" == "results" ]]; then
  TOOL_NAME="lvsbrowser"
else
  TOOL_NAME="pvsgui"
fi
TOOL="$(resolve_gui_bin "$TOOL_NAME")" \
  || die "Cadence $TOOL_NAME was not found after loading the Cadence environment"

echo "GUI_TOOL=$TOOL"
echo "GUI_LAUNCH=STARTING_FOREGROUND"
cd "$REVIEW_DIR" || die "cannot enter GUI review directory"

if [[ "$VIEW" == "setup" ]]; then
  export PVSUI_LVS_PRESETS_FILE="$REVIEW_DIR/.preset.autosave"
fi

exec "$TOOL"
