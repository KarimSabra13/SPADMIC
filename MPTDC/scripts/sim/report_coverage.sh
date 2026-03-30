#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Merge Cadence/Xrun per-covtest coverage buckets and generate IMC
#           aggregate + expanded HTML reports.
# Usage   : bash scripts/sim/report_coverage.sh [--cov-root DIR]
#           [--merge-name NAME] [--keep-cmd-file]
# Notes   : xrun writes one UCD per -covtest under cov_work/scope/<covtest>/.
#           IMC reporting therefore requires an explicit merge step first.
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COV_ROOT="$REPO_ROOT/build/coverage_campaign"
MERGE_NAME="merged_cov"
KEEP_CMD_FILE=0

normalize_repo_path() {
  local raw_path="$1"
  if [[ "$raw_path" == /* ]]; then
    printf '%s\n' "$raw_path"
  else
    printf '%s\n' "$REPO_ROOT/$raw_path"
  fi
}

ensure_repo_path() {
  local checked_path="$1"
  case "$checked_path" in
    "$REPO_ROOT"/*) ;;
    *)
      echo "Error: coverage artifacts must stay inside the repository: $checked_path" >&2
      exit 1
      ;;
  esac
}

require_tool() {
  local tool_name="$1"
  if ! command -v "$tool_name" >/dev/null 2>&1; then
    echo "Error: required tool '$tool_name' not found in PATH" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cov-root)
      COV_ROOT="$2"
      shift 2
      ;;
    --merge-name)
      MERGE_NAME="$2"
      shift 2
      ;;
    --keep-cmd-file)
      KEEP_CMD_FILE=1
      shift
      ;;
    -h|--help)
      cat <<EOF
Usage: $0 [options]

Options:
  --cov-root DIR       Coverage root directory (default: build/coverage_campaign)
  --merge-name NAME    Name of merged run under cov_work/scope/ (default: merged_cov)
  --keep-cmd-file      Keep the generated temporary IMC command file

Outputs:
  <cov-root>/cov_work/scope/<merge-name>/
  <cov-root>/cov_report_aggregate/
  <cov-root>/cov_report_expand/
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

require_tool imc

COV_ROOT="$(normalize_repo_path "$COV_ROOT")"
ensure_repo_path "$COV_ROOT"

COV_WORK="$COV_ROOT/cov_work"
SCOPE_DIR="$COV_WORK/scope"
MERGED_RUN="$SCOPE_DIR/$MERGE_NAME"
AGGREGATE_REPORT="$COV_ROOT/cov_report_aggregate"
EXPAND_REPORT="$COV_ROOT/cov_report_expand"

if [[ ! -d "$SCOPE_DIR" ]]; then
  echo "Error: coverage scope directory not found: $SCOPE_DIR" >&2
  exit 1
fi

mapfile -t RUN_DIRS < <(find "$SCOPE_DIR" -mindepth 1 -maxdepth 1 -type d ! -name "$MERGE_NAME" | sort)

if [[ ${#RUN_DIRS[@]} -eq 0 ]]; then
  echo "Error: no per-covtest run directories found under $SCOPE_DIR" >&2
  exit 1
fi

IMC_CMD_FILE="$(mktemp "${TMPDIR:-/tmp}/mptdc_imc_cov_XXXX.cmd")"
if [[ $KEEP_CMD_FILE -eq 0 ]]; then
  trap 'rm -f "$IMC_CMD_FILE"' EXIT
fi

rm -rf "$MERGED_RUN" "$AGGREGATE_REPORT" "$EXPAND_REPORT"

{
  printf 'merge'
  for run_dir in "${RUN_DIRS[@]}"; do
    printf ' {%s}' "$run_dir"
  done
  printf ' -overwrite -out {%s}\n' "$MERGED_RUN"
  printf 'load -run {%s}\n' "$MERGED_RUN"
  printf 'report_metrics -out {%s} -detail -kind aggregate\n' "$AGGREGATE_REPORT"
  printf 'report_metrics -out {%s} -detail -kind expand\n' "$EXPAND_REPORT"
  printf 'exit\n'
} > "$IMC_CMD_FILE"

echo "Merging ${#RUN_DIRS[@]} coverage runs from $SCOPE_DIR ..."
imc -init "$IMC_CMD_FILE" -nocopyright

echo ""
echo "Merged run:        $MERGED_RUN"
echo "Aggregate report:  $AGGREGATE_REPORT/index.html"
echo "Expanded report:   $EXPAND_REPORT/index.html"

if command -v python3 >/dev/null 2>&1 && [[ -f "$AGGREGATE_REPORT/tree.json" ]]; then
  echo ""
  python3 - "$AGGREGATE_REPORT/tree.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8", errors="replace") as fh:
    data = json.load(fh)

root = data[0] if isinstance(data, list) and data else {}
print(f"Overall average grade: {root.get('All Average Grd', 'n/a')}")
print(f"Overall coverage:      {root.get('All Cov', 'n/a')}")
PY
fi

if [[ $KEEP_CMD_FILE -eq 1 ]]; then
  echo ""
  echo "IMC command file kept at: $IMC_CMD_FILE"
fi
