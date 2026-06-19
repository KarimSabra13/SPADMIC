#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSITION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$POSITION_DIR/.." && pwd)"

LEF_PATH=""
MACRO_NAME=""
RUN_ID=""
OUT_DIR=""
EXPECTED_AXIS_COUNT=64
SVG_LABELS="none"

usage() {
  cat <<'USAGE'
Usage:
  run_spad_matrix_abstract_extract.sh --lef <SPAD_MATRIX.lef> [options]

Options:
  --macro <name>              Macro name inside LEF. Required when LEF has multiple macros.
  --run-id <id>               Output run ID. Default: timestamped matrix_abstract_extract.
  --out-dir <path>            Explicit output directory.
  --expected-axis-count <n>    Expected X/Y/Z line count. Default: 64.
  --svg-labels none|all       Draw pin labels in SVG. Default: none.
  -h, --help                  Show this help.

Outputs:
  matrix_macro_summary.json
  matrix_pin_summary.csv
  matrix_pin_shapes.csv
  matrix_pin_map.svg
  matrix_handoff_report.md
  position_pnr_seed.tcl
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
    --lef)
      LEF_PATH="$(abs_path "${2:?missing --lef value}")"
      shift 2
      ;;
    --macro)
      MACRO_NAME="${2:?missing --macro value}"
      shift 2
      ;;
    --run-id)
      RUN_ID="${2:?missing --run-id value}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$(abs_path "${2:?missing --out-dir value}")"
      shift 2
      ;;
    --expected-axis-count)
      EXPECTED_AXIS_COUNT="${2:?missing --expected-axis-count value}"
      shift 2
      ;;
    --svg-labels)
      SVG_LABELS="${2:?missing --svg-labels value}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$LEF_PATH" ]]; then
  echo "ERROR: --lef is required." >&2
  usage >&2
  exit 2
fi
if [[ ! -f "$LEF_PATH" ]]; then
  echo "ERROR: LEF file not found: $LEF_PATH" >&2
  exit 2
fi

RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)_spad_matrix_abstract_extract}"
case "$RUN_ID" in
  ""|"/"|"."|*"/"*|*".."*)
    echo "ERROR: RUN_ID must be a simple directory name, got '$RUN_ID'." >&2
    exit 2
    ;;
esac

POSITION_WORK_ROOT="$(abs_path "${POSITION_WORK_ROOT:-work/position}")"
OUT_DIR="${OUT_DIR:-$POSITION_WORK_ROOT/matrix_handoff/$RUN_ID}"
mkdir -p "$OUT_DIR/logs"
RUN_LOG="$OUT_DIR/logs/extract_spad_matrix_abstract.log"

{
  echo "# SPAD Matrix Abstract Extract"
  echo "date=$(date -Iseconds)"
  echo "repo=$REPO_ROOT"
  echo "branch=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "run_id=$RUN_ID"
  echo "lef=$LEF_PATH"
  echo "macro=${MACRO_NAME:-auto}"
  echo "out_dir=$OUT_DIR"
  echo "expected_axis_count=$EXPECTED_AXIS_COUNT"
  echo "svg_labels=$SVG_LABELS"
  echo
  echo "git status --short --untracked-files=no:"
  git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null || true
  echo
} | tee "$RUN_LOG"

ARGS=(
  --lef "$LEF_PATH"
  --out-dir "$OUT_DIR"
  --expected-axis-count "$EXPECTED_AXIS_COUNT"
  --svg-labels "$SVG_LABELS"
)
if [[ -n "$MACRO_NAME" ]]; then
  ARGS+=(--macro "$MACRO_NAME")
fi

python3 "$SCRIPT_DIR/extract_spad_matrix_abstract.py" "${ARGS[@]}" 2>&1 | tee -a "$RUN_LOG"
