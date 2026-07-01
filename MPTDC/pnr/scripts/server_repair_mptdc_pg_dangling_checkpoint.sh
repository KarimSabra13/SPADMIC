#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

DEFAULT_INNOVUS_WORK="/sim/ksabra/SPADMIC_work/innovus"

SOURCE_CHECKPOINT=""
SOURCE_DEF=""
RUN_ID=""
MODE="analyze"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
INNOVUS_WORK_VALUE="${MPTDC_INNOVUS_WORK:-$DEFAULT_INNOVUS_WORK}"
TOP_CELL_VALUE="${MPTDC_CHECKPOINT_REPAIR_TOP:-mptdc_axis_core}"
ALLOW_LONG_DELETE="0"
DELETE_METHOD="dbdeleteobj_then_editdelete"

usage() {
  cat <<'USAGE'
Usage:
  server_repair_mptdc_pg_dangling_checkpoint.sh --checkpoint <enc.dat> [options]

Options:
  --checkpoint <path>       Source Innovus checkpoint directory, usually repaired_route.enc.dat.
  --source-def <path>       Optional matching DEF to copy into the safe source bundle.
  --run-id <id>             Result run id under the Innovus work root.
  --mode <mode>             analyze, delete_short, or delete_all. Default: analyze.
  --allow-long-delete       Allow repair mode to delete long exact-matched sWire segments.
  --delete-method <method>  dbdeleteobj, editdelete, or dbdeleteobj_then_editdelete.
  --expected-head <sha>     Require repository HEAD to match this commit.
  --innovus-work <path>     Innovus run root. Default: /sim/ksabra/SPADMIC_work/innovus.
  --top-cell <name>         Top cell for restoreDesign. Default: mptdc_axis_core.
  -h, --help                Show this help.

This wrapper never restores directly from the accepted source checkpoint. It
first creates a physical safe copy inside the new run directory, then restores
and probes or repairs that copy.

Recommended first run:
  --mode analyze

Only use --mode delete_all --allow-long-delete after reviewing the analysis
report and accepting that the exact matched special-wire segments may be long
PG stripe/ring segments rather than small leftover stubs.
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
    --allow-long-delete)
      ALLOW_LONG_DELETE="1"
      shift
      ;;
    --delete-method)
      DELETE_METHOD="${2:?missing --delete-method value}"
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

if [[ -z "$SOURCE_CHECKPOINT" ]]; then
  echo "ERROR: --checkpoint is required" >&2
  usage >&2
  exit 2
fi

case "$MODE" in
  analyze|analysis|delete_short|delete_all|delete_all_candidates|repair) ;;
  *)
    echo "ERROR: unsupported --mode '$MODE'" >&2
    usage >&2
    exit 2
    ;;
esac

case "$DELETE_METHOD" in
  dbdeleteobj|editdelete|dbdeleteobj_then_editdelete) ;;
  *)
    echo "ERROR: unsupported --delete-method '$DELETE_METHOD'" >&2
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
  echo "ERROR: tracked working tree is dirty. Commit or restore tracked edits before this checkpoint repair." >&2
  git status --short --untracked-files=no >&2
  exit 3
fi

if [[ ! -e "$SOURCE_CHECKPOINT" ]]; then
  echo "ERROR: source checkpoint does not exist: $SOURCE_CHECKPOINT" >&2
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

RUN_ID="${RUN_ID:-20260702_mptdc_pg_dangling_${MODE}_$(date +%H%M%S)}"
RESULT_DIR="$INNOVUS_WORK_VALUE/$RUN_ID"
SAFE_SOURCE_DIR="$RESULT_DIR/source_checkpoint_safe"
MANIFEST_DIR="$RESULT_DIR/manifests"
REPORT_DIR="$RESULT_DIR/reports"
LOG_DIR="$RESULT_DIR/logs"
COMMANDS_FILE="$MANIFEST_DIR/pg_dangling_commands.tcl"
SAFE_CHECKPOINT="$SAFE_SOURCE_DIR/$(basename "$SOURCE_CHECKPOINT")"

if [[ -e "$RESULT_DIR" ]]; then
  echo "ERROR: result directory already exists; choose a new --run-id: $RESULT_DIR" >&2
  exit 3
fi

mkdir -p "$SAFE_SOURCE_DIR" "$MANIFEST_DIR" "$REPORT_DIR" "$LOG_DIR"

echo "SAFE_COPY_SOURCE=$SOURCE_CHECKPOINT"
echo "SAFE_COPY_DEST=$SAFE_CHECKPOINT"
cp -aL "$SOURCE_CHECKPOINT" "$SAFE_CHECKPOINT"

SAFE_DEF=""
if [[ -n "$SOURCE_DEF" ]]; then
  SAFE_DEF="$SAFE_SOURCE_DIR/$(basename "$SOURCE_DEF")"
  cp -aL "$SOURCE_DEF" "$SAFE_DEF"
fi

{
  echo "# MPTDC PG Dangling Safe Source Manifest"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git rev-parse --abbrev-ref HEAD)"
  echo "head: $ACTUAL_HEAD"
  echo "run_id: $RUN_ID"
  echo "result_dir: $RESULT_DIR"
  echo "mode: $MODE"
  echo "allow_long_delete: $ALLOW_LONG_DELETE"
  echo "delete_method: $DELETE_METHOD"
  echo "source_checkpoint: $SOURCE_CHECKPOINT"
  echo "safe_checkpoint: $SAFE_CHECKPOINT"
  echo "source_def: ${SOURCE_DEF:-unset}"
  echo "safe_def: ${SAFE_DEF:-unset}"
  if [[ -d "$SAFE_CHECKPOINT" ]]; then
    echo "safe_checkpoint_file_count: $(find "$SAFE_CHECKPOINT" -type f | wc -l)"
  else
    echo "safe_checkpoint_file_count: 1"
  fi
} > "$MANIFEST_DIR/safe_source_manifest.txt"

{
  echo "set ::env(MPTDC_PG_DANGLING_MODE) {$MODE}"
  echo "set ::env(MPTDC_PG_DANGLING_ALLOW_LONG_DELETE) {$ALLOW_LONG_DELETE}"
  echo "set ::env(MPTDC_PG_DANGLING_DELETE_METHOD) {$DELETE_METHOD}"
  echo "mptdc_ckpt_source_tcl {$SCRIPT_DIR/innovus_mptdc_pg_dangling_checkpoint_tools.tcl}"
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

export MPTDC_PG_DANGLING_MODE="$MODE"
export MPTDC_PG_DANGLING_ALLOW_LONG_DELETE="$ALLOW_LONG_DELETE"
export MPTDC_PG_DANGLING_DELETE_METHOD="$DELETE_METHOD"

"$SCRIPT_DIR/server_repair_mptdc_route_checkpoint.sh" "${repair_args[@]}"
rc=$?

echo "PG_DANGLING_RC=$rc"
echo "PG_DANGLING_RESULT_DIR=$RESULT_DIR"
echo "PG_DANGLING_SAFE_CHECKPOINT=$SAFE_CHECKPOINT"
echo "PG_DANGLING_ANALYSIS_REPORT=$REPORT_DIR/pg_dangling_analysis_status.rpt"
echo "PG_DANGLING_STATUS_REPORT=$REPORT_DIR/checkpoint_repair_status.rpt"
exit "$rc"
