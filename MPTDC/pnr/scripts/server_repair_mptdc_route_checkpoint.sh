#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

DEFAULT_INNOVUS_WORK="/sim/ksabra/SPADMIC_work/innovus"

RUN_ID=""
SOURCE_CHECKPOINT=""
COMMANDS_FILE=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
INNOVUS_WORK_VALUE="${MPTDC_INNOVUS_WORK:-$DEFAULT_INNOVUS_WORK}"
TOP_CELL_VALUE="${MPTDC_CHECKPOINT_REPAIR_TOP:-mptdc_axis_core}"

usage() {
  cat <<'USAGE'
Usage:
  server_repair_mptdc_route_checkpoint.sh --checkpoint <enc.dat> [options]

Options:
  --run-id <id>          Repair run id under the Innovus work root.
  --checkpoint <path>    Saved Innovus checkpoint data directory or .enc path.
  --commands-file <path> File containing one Innovus Tcl repair command per line.
  --expected-head <sha>  Require repository HEAD to match this commit.
  --innovus-work <path>  Innovus run root.
  --top-cell <name>      Top cell for restoreDesign. Default: mptdc_axis_core.
  -h, --help             Show this help.

This wrapper restores an existing route checkpoint and runs targeted repair
commands. It does not rerun import, floorplan, placement, CTS, or routeDesign
from scratch.

The commands file is Tcl. For selected-net repair, prefer:
  mptdc_ckpt_route_selected_nets {net_a net_b net_c}

Commands fail fast by default. Set MPTDC_CHECKPOINT_REPAIR_KEEP_GOING=1 only for
exploratory probes where later commands should still run after a failed command.
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
    --run-id)
      RUN_ID="${2:?missing --run-id value}"
      shift 2
      ;;
    --checkpoint)
      SOURCE_CHECKPOINT="$(abs_path "${2:?missing --checkpoint value}")"
      shift 2
      ;;
    --commands-file)
      COMMANDS_FILE="$(abs_path "${2:?missing --commands-file value}")"
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
  echo "ERROR: checkpoint does not exist: $SOURCE_CHECKPOINT" >&2
  exit 3
fi
if [[ -n "$COMMANDS_FILE" && ! -r "$COMMANDS_FILE" ]]; then
  echo "ERROR: commands file is not readable: $COMMANDS_FILE" >&2
  exit 3
fi
if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus not found in PATH; run this on the lab server." >&2
  exit 127
fi

RUN_ID="${RUN_ID:-20260701_mptdc_route_checkpoint_repair_$(date +%H%M%S)}"
RESULT_DIR="$INNOVUS_WORK_VALUE/$RUN_ID"
LOG_DIR="$RESULT_DIR/logs"
REPORT_DIR="$RESULT_DIR/reports"
MANIFEST_DIR="$RESULT_DIR/manifests"
mkdir -p "$LOG_DIR" "$REPORT_DIR" "$MANIFEST_DIR"
RUN_LOG="$LOG_DIR/checkpoint_repair_wrapper.log"

export MPTDC_REPO_ROOT="$REPO_ROOT"
export MPTDC_SIGNOFF_RESULT_DIR="$RESULT_DIR"
export MPTDC_CHECKPOINT_REPAIR_SOURCE_CHECKPOINT="$SOURCE_CHECKPOINT"
export MPTDC_CHECKPOINT_REPAIR_TOP="$TOP_CELL_VALUE"
export MPTDC_CHECKPOINT_REPAIR_COMMANDS_FILE="$COMMANDS_FILE"

{
  echo "# MPTDC Route Checkpoint Repair Wrapper"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git rev-parse --abbrev-ref HEAD)"
  echo "head: $ACTUAL_HEAD"
  echo "run_id: $RUN_ID"
  echo "result_dir: $RESULT_DIR"
  echo "source_checkpoint: $SOURCE_CHECKPOINT"
  echo "commands_file: ${COMMANDS_FILE:-unset}"
  echo "top_cell: $TOP_CELL_VALUE"
  echo
  echo "git status --short --untracked-files=no:"
  git status --short --untracked-files=no
} | tee "$MANIFEST_DIR/run_manifest.txt" | tee "$RUN_LOG"

(
  cd "$SCRIPT_DIR"
  innovus -nowin -init innovus_mptdc_route_checkpoint_repair.tcl -log "$LOG_DIR/innovus_route_checkpoint_repair.log"
) 2>&1 | tee -a "$RUN_LOG"
INNOVUS_RC=${PIPESTATUS[0]}

echo "INNOVUS_RC=$INNOVUS_RC" | tee -a "$RUN_LOG"
exit "$INNOVUS_RC"
