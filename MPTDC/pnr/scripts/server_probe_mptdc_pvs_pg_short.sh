#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

DEFAULT_INNOVUS_WORK="/sim/ksabra/SPADMIC_work/innovus"

SOURCE_CHECKPOINT=""
SOURCE_DEF=""
PVS_SHORTS=""
RUN_ID=""
MODE="analyze"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
INNOVUS_WORK_VALUE="${MPTDC_INNOVUS_WORK:-$DEFAULT_INNOVUS_WORK}"
TOP_CELL_VALUE="${MPTDC_CHECKPOINT_REPAIR_TOP:-mptdc_axis_core}"
BRIDGE_WINDOW="48.0 598.0 113.0 688.5"
DELETE_MARGIN_UM="0.05"
MAX_DELETE_SPAN_UM="90.0"

usage() {
  cat <<'USAGE'
Usage:
  server_probe_mptdc_pvs_pg_short.sh --checkpoint <enc.dat> --pvs-shorts <file> [options]

Options:
  --checkpoint <path>       Source Innovus checkpoint directory, usually repaired_route.enc.dat.
  --pvs-shorts <path>       PVS LVS find-shorts report, e.g. mptdc_axis_core_lvs.sum.shorts.
  --source-def <path>       Optional matching DEF to copy into the safe evidence bundle.
  --run-id <id>             Result run id under the Innovus work root.
  --mode <mode>             analyze or surgical_proof. Default: analyze.
  --bridge-window "<box>"   Lower-left proof window in microns. Default: "48.0 598.0 113.0 688.5".
  --delete-margin-um <num>  Area expansion around selected BLOCKWIRE candidates. Default: 0.05.
  --max-delete-span-um <n>  Reject candidate BLOCKWIREs longer than this span. Default: 90.0.
  --expected-head <sha>     Require repository HEAD to match this commit.
  --innovus-work <path>     Innovus run root. Default: /sim/ksabra/SPADMIC_work/innovus.
  --top-cell <name>         Top cell for restoreDesign. Default: mptdc_axis_core.
  -h, --help                Show this help.

This wrapper never restores directly from the accepted source checkpoint. It
first creates a physical safe copy inside the new run directory, then restores
and probes that copy through server_repair_mptdc_route_checkpoint.sh.

Recommended first run:
  --mode analyze

Use --mode surgical_proof only after reviewing the analysis report. Surgical
proof mode is intentionally bounded to short BLOCKWIRE special-net candidates in
the lower-left bridge window and does not run broad sroute or edit the source
checkpoint in place.
USAGE
}

abs_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$path" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --checkpoint)
      SOURCE_CHECKPOINT="$(abs_path "${2:?missing --checkpoint value}")"
      shift 2
      ;;
    --pvs-shorts)
      PVS_SHORTS="$(abs_path "${2:?missing --pvs-shorts value}")"
      shift 2
      ;;
    --source-def)
      SOURCE_DEF="$(abs_path "${2:?missing --source-def value}")"
      shift 2
      ;;
    --run-id)
      RUN_ID="${2:?missing --run-id value}"
      shift 2
      ;;
    --mode)
      MODE="${2:?missing --mode value}"
      shift 2
      ;;
    --bridge-window)
      BRIDGE_WINDOW="${2:?missing --bridge-window value}"
      shift 2
      ;;
    --delete-margin-um)
      DELETE_MARGIN_UM="${2:?missing --delete-margin-um value}"
      shift 2
      ;;
    --max-delete-span-um)
      MAX_DELETE_SPAN_UM="${2:?missing --max-delete-span-um value}"
      shift 2
      ;;
    --expected-head)
      EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"
      shift 2
      ;;
    --innovus-work)
      INNOVUS_WORK_VALUE="$(abs_path "${2:?missing --innovus-work value}")"
      shift 2
      ;;
    --top-cell)
      TOP_CELL_VALUE="${2:?missing --top-cell value}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      echo "ERROR: unexpected positional argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$SOURCE_CHECKPOINT" || -z "$PVS_SHORTS" ]]; then
  echo "ERROR: --checkpoint and --pvs-shorts are required" >&2
  usage >&2
  exit 2
fi

case "$MODE" in
  analyze|analysis|surgical_proof) ;;
  *)
    echo "ERROR: unsupported --mode '$MODE'" >&2
    usage >&2
    exit 2
    ;;
esac

cd "$REPO_ROOT"

ACTUAL_HEAD="$(git rev-parse HEAD)"
echo "REPO_ROOT=$REPO_ROOT"
echo "BRANCH=$(git rev-parse --abbrev-ref HEAD)"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
if [[ -n "$EXPECTED_HEAD_VALUE" ]]; then
  echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"
  test "$ACTUAL_HEAD" = "$EXPECTED_HEAD_VALUE"
else
  echo "EXPECTED_HEAD_HINT=$ACTUAL_HEAD"
fi

if [[ -n "$(git status --short --untracked-files=no)" ]]; then
  echo "ERROR: tracked working tree is dirty. Commit or restore tracked edits before this checkpoint probe." >&2
  git status --short --untracked-files=no >&2
  exit 3
fi

if [[ ! -e "$SOURCE_CHECKPOINT" ]]; then
  echo "ERROR: source checkpoint does not exist: $SOURCE_CHECKPOINT" >&2
  exit 3
fi
if [[ ! -f "$PVS_SHORTS" ]]; then
  echo "ERROR: PVS shorts report does not exist: $PVS_SHORTS" >&2
  exit 3
fi
if [[ -n "$SOURCE_DEF" && ! -f "$SOURCE_DEF" ]]; then
  echo "ERROR: source DEF does not exist: $SOURCE_DEF" >&2
  exit 3
fi
if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus not found in PATH; run this on the lab server." >&2
  exit 127
fi

RUN_ID="${RUN_ID:-20260702_mptdc_pvs_pg_short_${MODE}_$(date +%H%M%S)}"
RESULT_DIR="$INNOVUS_WORK_VALUE/$RUN_ID"
SAFE_SOURCE_DIR="$RESULT_DIR/source_checkpoint_safe"
EVIDENCE_DIR="$RESULT_DIR/evidence"
MANIFEST_DIR="$RESULT_DIR/manifests"
REPORT_DIR="$RESULT_DIR/reports"
LOG_DIR="$RESULT_DIR/logs"
COMMANDS_FILE="$MANIFEST_DIR/pvs_pg_short_commands.tcl"
SAFE_CHECKPOINT="$SAFE_SOURCE_DIR/$(basename "$SOURCE_CHECKPOINT")"
SAFE_PVS_SHORTS="$EVIDENCE_DIR/$(basename "$PVS_SHORTS")"

if [[ -e "$RESULT_DIR" ]]; then
  echo "ERROR: result directory already exists; choose a new --run-id: $RESULT_DIR" >&2
  exit 3
fi

mkdir -p "$SAFE_SOURCE_DIR" "$EVIDENCE_DIR" "$MANIFEST_DIR" "$REPORT_DIR" "$LOG_DIR"

echo "SAFE_COPY_SOURCE=$SOURCE_CHECKPOINT"
echo "SAFE_COPY_DEST=$SAFE_CHECKPOINT"
cp -aL "$SOURCE_CHECKPOINT" "$SAFE_CHECKPOINT"
cp -aL "$PVS_SHORTS" "$SAFE_PVS_SHORTS"

SAFE_DEF=""
if [[ -n "$SOURCE_DEF" ]]; then
  SAFE_DEF="$EVIDENCE_DIR/$(basename "$SOURCE_DEF")"
  cp -aL "$SOURCE_DEF" "$SAFE_DEF"
fi

{
  echo "# MPTDC PVS PG Short Safe Source Manifest"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git rev-parse --abbrev-ref HEAD)"
  echo "head: $ACTUAL_HEAD"
  echo "run_id: $RUN_ID"
  echo "result_dir: $RESULT_DIR"
  echo "mode: $MODE"
  echo "bridge_window_um: $BRIDGE_WINDOW"
  echo "delete_margin_um: $DELETE_MARGIN_UM"
  echo "max_delete_span_um: $MAX_DELETE_SPAN_UM"
  echo "source_checkpoint: $SOURCE_CHECKPOINT"
  echo "safe_checkpoint: $SAFE_CHECKPOINT"
  echo "source_def: ${SOURCE_DEF:-unset}"
  echo "safe_def: ${SAFE_DEF:-unset}"
  echo "pvs_shorts: $PVS_SHORTS"
  echo "safe_pvs_shorts: $SAFE_PVS_SHORTS"
  if [[ -d "$SAFE_CHECKPOINT" ]]; then
    echo "safe_checkpoint_file_count: $(find "$SAFE_CHECKPOINT" -type f | wc -l)"
  else
    echo "safe_checkpoint_file_count: 1"
  fi
} > "$MANIFEST_DIR/safe_source_manifest.txt"

{
  echo "set ::env(MPTDC_PVS_PG_SHORT_AUTORUN) {0}"
  echo "set ::env(MPTDC_PVS_PG_SHORT_MODE) {$MODE}"
  echo "set ::env(MPTDC_PVS_PG_SHORTS_FILE) {$SAFE_PVS_SHORTS}"
  echo "set ::env(MPTDC_PVS_PG_SHORT_SOURCE_DEF) {${SAFE_DEF:-}}"
  echo "set ::env(MPTDC_PVS_PG_SHORT_BRIDGE_WINDOW_UM) {$BRIDGE_WINDOW}"
  echo "set ::env(MPTDC_PVS_PG_SHORT_DELETE_MARGIN_UM) {$DELETE_MARGIN_UM}"
  echo "set ::env(MPTDC_PVS_PG_SHORT_MAX_DELETE_SPAN_UM) {$MAX_DELETE_SPAN_UM}"
  echo "mptdc_ckpt_source_tcl {$SCRIPT_DIR/innovus_mptdc_pvs_pg_short_probe.tcl}"
  echo "mptdc_pvs_pg_short_run"
  echo "mptdc_ckpt_assert_geometry_regular_clean"
} > "$COMMANDS_FILE"

repair_args=(
  --run-id "$RUN_ID"
  --checkpoint "$SAFE_CHECKPOINT"
  --commands-file "$COMMANDS_FILE"
  --top-cell "$TOP_CELL_VALUE"
  --innovus-work "$INNOVUS_WORK_VALUE"
)
if [[ -n "$EXPECTED_HEAD_VALUE" ]]; then
  repair_args+=(--expected-head "$EXPECTED_HEAD_VALUE")
fi

export MPTDC_PVS_PG_SHORT_MODE="$MODE"
export MPTDC_PVS_PG_SHORTS_FILE="$SAFE_PVS_SHORTS"
export MPTDC_PVS_PG_SHORT_SOURCE_DEF="$SAFE_DEF"
export MPTDC_PVS_PG_SHORT_BRIDGE_WINDOW_UM="$BRIDGE_WINDOW"
export MPTDC_PVS_PG_SHORT_DELETE_MARGIN_UM="$DELETE_MARGIN_UM"
export MPTDC_PVS_PG_SHORT_MAX_DELETE_SPAN_UM="$MAX_DELETE_SPAN_UM"

"$SCRIPT_DIR/server_repair_mptdc_route_checkpoint.sh" "${repair_args[@]}"
rc=$?

echo "PVS_PG_SHORT_RC=$rc"
echo "PVS_PG_SHORT_RESULT_DIR=$RESULT_DIR"
echo "PVS_PG_SHORT_SAFE_CHECKPOINT=$SAFE_CHECKPOINT"
echo "PVS_PG_SHORT_MAP_REPORT=$REPORT_DIR/pvs_pg_short_polygon_map.rpt"
echo "PVS_PG_SHORT_CSV_REPORT=$REPORT_DIR/pvs_pg_short_specialnet_map.csv"
echo "PVS_PG_SHORT_STATUS_REPORT=$REPORT_DIR/pvs_pg_short_root_cause_status.rpt"
echo "PVS_PG_SHORT_CHECKPOINT_STATUS=$REPORT_DIR/checkpoint_repair_status.rpt"
exit "$rc"
