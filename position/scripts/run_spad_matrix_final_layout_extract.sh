#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POSITION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$POSITION_DIR/.." && pwd)"

SOURCE_DIR=""
LEF_PATH=""
MACRO_NAME=""
RUN_ID=""
OUT_DIR=""
EXPECTED_AXIS_COUNT=64
MAX_DEPTH=8
SVG_LABELS="all"

usage() {
  cat <<'USAGE'
Usage:
  run_spad_matrix_final_layout_extract.sh --source-dir <server_matrix_dir> [options]

Read-only source extraction for the finalized analog SPAD matrix handoff.
The script never writes under --source-dir. Outputs go under work/position by
default.

Options:
  --source-dir <path>          Final matrix handoff directory.
  --lef <path>                 Explicit LEF to parse. Otherwise all LEFs under source-dir are parsed.
  --macro <name>               Extract only this macro from each selected LEF.
  --run-id <id>                Output run ID. Default: timestamped final_spad_matrix_extract.
  --out-dir <path>             Explicit output directory outside source-dir.
  --expected-axis-count <n>    Expected X/Y/Z line count. Default: 64.
  --max-depth <n>              Inventory search depth. Default: 8.
  --svg-labels none|all        Draw pin labels in SVG. Default: all.
  -h, --help                   Show this help.

Generated top-level outputs:
  FINAL_MATRIX_EXTRACTION_SUMMARY.md
  source_readonly_manifest.txt
  source_file_inventory.tsv
  source_directory_inventory.tsv
  candidate_lefs.txt
  candidate_layout_files.txt
  lef_extracts/<lef_name>/...
USAGE
}

abs_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$path" ;;
  esac
}

safe_name() {
  printf '%s' "$1" | sed 's#[/[:space:].]#_#g; s#[^A-Za-z0-9_+-]#_#g; s#^_*##; s#_*$##'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-dir)
      SOURCE_DIR="$(abs_path "${2:?missing --source-dir value}")"
      shift 2
      ;;
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
    --max-depth)
      MAX_DEPTH="${2:?missing --max-depth value}"
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

if [[ -z "$SOURCE_DIR" ]]; then
  echo "ERROR: --source-dir is required." >&2
  usage >&2
  exit 2
fi
if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "ERROR: source directory not found: $SOURCE_DIR" >&2
  echo "Check the path spelling. Previous project paths used /group/validmgr, but this command uses exactly the path passed in --source-dir." >&2
  exit 2
fi

if [[ -n "$LEF_PATH" && ! -f "$LEF_PATH" ]]; then
  echo "ERROR: explicit LEF not found: $LEF_PATH" >&2
  exit 2
fi

RUN_ID="${RUN_ID:-$(date +%Y%m%d_%H%M%S)_final_spad_matrix_extract}"
case "$RUN_ID" in
  ""|"/"|"."|*"/"*|*".."*)
    echo "ERROR: RUN_ID must be a simple directory name, got '$RUN_ID'." >&2
    exit 2
    ;;
esac

POSITION_WORK_ROOT="$(abs_path "${POSITION_WORK_ROOT:-work/position}")"
OUT_DIR="${OUT_DIR:-$POSITION_WORK_ROOT/matrix_handoff/$RUN_ID}"

source_real="$(cd "$SOURCE_DIR" && pwd -P)"
out_parent="$(mkdir -p "$(dirname "$OUT_DIR")" && cd "$(dirname "$OUT_DIR")" && pwd -P)"
out_base="$(basename "$OUT_DIR")"
out_real="$out_parent/$out_base"
case "$out_real" in
  "$source_real"|"$source_real"/*)
    echo "ERROR: output directory must not be inside source directory." >&2
    echo "source=$source_real" >&2
    echo "out=$out_real" >&2
    exit 2
    ;;
esac

mkdir -p "$OUT_DIR/logs" "$OUT_DIR/lef_extracts"
RUN_LOG="$OUT_DIR/logs/final_layout_extract.log"

{
  echo "# Final SPAD Matrix Layout Extract"
  echo "date=$(date -Iseconds)"
  echo "repo=$REPO_ROOT"
  echo "branch=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "run_id=$RUN_ID"
  echo "source_dir=$SOURCE_DIR"
  echo "source_realpath=$source_real"
  echo "lef=${LEF_PATH:-auto_all}"
  echo "macro=${MACRO_NAME:-all_or_auto}"
  echo "out_dir=$OUT_DIR"
  echo "expected_axis_count=$EXPECTED_AXIS_COUNT"
  echo "max_depth=$MAX_DEPTH"
  echo "svg_labels=$SVG_LABELS"
  echo "READ_ONLY_SOURCE=YES"
  echo
  echo "git status --short --untracked-files=no:"
  git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null || true
  echo
} | tee "$RUN_LOG"

echo "INFO: inventorying source files read-only..." | tee -a "$RUN_LOG"
{
  printf "path\tsize_bytes\tmtime\tmode\n"
  find "$SOURCE_DIR" -maxdepth "$MAX_DEPTH" -type f -printf '%p\t%s\t%TY-%Tm-%TdT%TH:%TM:%TS\t%M\n' | sort
} > "$OUT_DIR/source_file_inventory.tsv"

{
  printf "path\tmtime\tmode\n"
  find "$SOURCE_DIR" -maxdepth "$MAX_DEPTH" -type d -printf '%p\t%TY-%Tm-%TdT%TH:%TM:%TS\t%M\n' | sort
} > "$OUT_DIR/source_directory_inventory.tsv"

find "$SOURCE_DIR" -maxdepth "$MAX_DEPTH" -type f \( \
  -iname '*.lef' -o -iname '*.tlef' -o -iname '*.LEF' -o -iname '*.TLEF' \
\) -print | sort > "$OUT_DIR/candidate_lefs.txt"

find "$SOURCE_DIR" -maxdepth "$MAX_DEPTH" -type f \( \
  -iname '*.gds' -o -iname '*.gdsii' -o -iname '*.oas' -o -iname '*.def' -o \
  -iname '*.GDS' -o -iname '*.GDSII' -o -iname '*.OAS' -o -iname '*.DEF' \
\) -print | sort > "$OUT_DIR/candidate_layout_files.txt"

find "$SOURCE_DIR" -maxdepth "$MAX_DEPTH" -type f \( \
  -iname '*.cdl' -o -iname '*.spi' -o -iname '*.sp' -o -iname '*.v' -o -iname '*.lib' -o \
  -iname '*.CDL' -o -iname '*.SPI' -o -iname '*.SP' -o -iname '*.V' -o -iname '*.LIB' \
\) -print | sort > "$OUT_DIR/candidate_netlist_model_files.txt"

mapfile -t LEFS < "$OUT_DIR/candidate_lefs.txt"
if [[ -n "$LEF_PATH" ]]; then
  LEFS=("$LEF_PATH")
fi

{
  echo "# Final SPAD Matrix Extraction Summary"
  echo
  echo "RUN_ID=$RUN_ID"
  echo "SOURCE_DIR=$SOURCE_DIR"
  echo "OUTPUT_DIR=$OUT_DIR"
  echo "READ_ONLY_SOURCE=YES"
  echo "FILE_COUNT=$(($(wc -l < "$OUT_DIR/source_file_inventory.tsv") - 1))"
  echo "DIRECTORY_COUNT=$(($(wc -l < "$OUT_DIR/source_directory_inventory.tsv") - 1))"
  echo "LEF_CANDIDATE_COUNT=${#LEFS[@]}"
  echo "LAYOUT_FILE_COUNT=$(wc -l < "$OUT_DIR/candidate_layout_files.txt")"
  echo "NETLIST_MODEL_FILE_COUNT=$(wc -l < "$OUT_DIR/candidate_netlist_model_files.txt")"
  echo
  echo "## Candidate LEFs"
  echo
  if [[ "${#LEFS[@]}" -eq 0 ]]; then
    echo "No LEF files found. Export a LEF abstract from OA/GDS, then rerun with --lef."
  else
    for lef in "${LEFS[@]}"; do
      echo "- $lef"
    done
  fi
  echo
  echo "## Candidate Layout Files"
  echo
  if [[ -s "$OUT_DIR/candidate_layout_files.txt" ]]; then
    sed 's/^/- /' "$OUT_DIR/candidate_layout_files.txt"
  else
    echo "No GDS/OAS/DEF files found within max depth."
  fi
} > "$OUT_DIR/FINAL_MATRIX_EXTRACTION_SUMMARY.md"

if [[ "${#LEFS[@]}" -eq 0 ]]; then
  echo "WARN: no LEF files found; inventory-only extraction complete: $OUT_DIR" | tee -a "$RUN_LOG"
  exit 0
fi

EXTRACTED_INDEX="$OUT_DIR/extracted_lef_dirs.tsv"
printf "lef\textract_dir\tstatus\n" > "$EXTRACTED_INDEX"

for lef in "${LEFS[@]}"; do
  if [[ ! -f "$lef" ]]; then
    printf "%s\t\tMISSING\n" "$lef" >> "$EXTRACTED_INDEX"
    echo "WARN: candidate LEF disappeared or is unreadable: $lef" | tee -a "$RUN_LOG"
    continue
  fi
  rel="$lef"
  case "$lef" in
    "$SOURCE_DIR"/*) rel="${lef#"$SOURCE_DIR"/}" ;;
  esac
  lef_out="$OUT_DIR/lef_extracts/$(safe_name "$rel")"
  mkdir -p "$lef_out"
  echo "INFO: listing macros in $lef" | tee -a "$RUN_LOG"
  if ! python3 "$SCRIPT_DIR/extract_spad_matrix_abstract.py" --lef "$lef" --list-macros > "$lef_out/macro_list.csv"; then
    printf "%s\t%s\tLIST_MACROS_FAILED\n" "$lef" "$lef_out" >> "$EXTRACTED_INDEX"
    continue
  fi
  echo "INFO: extracting LEF geometry from $lef" | tee -a "$RUN_LOG"
  ARGS=(
    --lef "$lef"
    --out-dir "$lef_out"
    --expected-axis-count "$EXPECTED_AXIS_COUNT"
    --svg-labels "$SVG_LABELS"
  )
  if [[ -n "$MACRO_NAME" ]]; then
    ARGS+=(--macro "$MACRO_NAME")
  else
    ARGS+=(--all-macros)
  fi
  if python3 "$SCRIPT_DIR/extract_spad_matrix_abstract.py" "${ARGS[@]}" 2>&1 | tee -a "$RUN_LOG"; then
    printf "%s\t%s\tPASS\n" "$lef" "$lef_out" >> "$EXTRACTED_INDEX"
  else
    printf "%s\t%s\tEXTRACT_FAILED\n" "$lef" "$lef_out" >> "$EXTRACTED_INDEX"
  fi
done

{
  echo
  echo "## Extracted LEF Directories"
  echo
  tail -n +2 "$EXTRACTED_INDEX" | while IFS=$'\t' read -r lef extract_dir status; do
    echo "- status=$status lef=$lef extract_dir=$extract_dir"
  done
} >> "$OUT_DIR/FINAL_MATRIX_EXTRACTION_SUMMARY.md"

echo "FINAL_SPAD_MATRIX_EXTRACT_OUT=$OUT_DIR" | tee -a "$RUN_LOG"
echo "FINAL_SPAD_MATRIX_SUMMARY=$OUT_DIR/FINAL_MATRIX_EXTRACTION_SUMMARY.md" | tee -a "$RUN_LOG"
