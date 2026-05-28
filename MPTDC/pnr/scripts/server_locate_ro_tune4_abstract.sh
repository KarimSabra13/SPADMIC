#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_locate_ro_tune4}"
RESULT_DIR="$REPO_ROOT/results/osc_pd/$RUN_ID/real_abstract_locator"
LOG="$RESULT_DIR/locator.log"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
CDS_OVERRIDE="$MPTDC_DIR/analog_handoff/cds_analog_override.lib"

mkdir -p "$RESULT_DIR"
exec > >(tee "$LOG") 2>&1

echo "# O1 RO_tune4 Abstract Locator"
echo "date: $(date -Iseconds)"
echo "hostname: $(hostname)"
echo "repo: $REPO_ROOT"
echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
echo

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: missing env file: $ENV_FILE"
  exit 2
fi

# shellcheck source=/dev/null
source "$ENV_FILE"

cp "$CDS_OVERRIDE" "$RESULT_DIR/cds_lib_override.txt" 2>/dev/null || true

status=0
{
  echo "O1_RO_LIB_NAME=$O1_RO_LIB_NAME"
  echo "O1_RO_CELL_NAME=$O1_RO_CELL_NAME"
  echo "O1_RO_VIEW_NAME=$O1_RO_VIEW_NAME"
  echo "O1_RO_LIB_ROOT=$O1_RO_LIB_ROOT"
  echo "O1_RO_ABSTRACT_DIR=$O1_RO_ABSTRACT_DIR"
  echo "O1_RO_ABSTRACT_LAYOUT_OA=$O1_RO_ABSTRACT_LAYOUT_OA"
  echo

  if [[ -d "$O1_RO_LIB_ROOT" ]]; then
    echo "LIB_ROOT_EXISTS=yes"
  else
    echo "LIB_ROOT_EXISTS=no"
    status=1
  fi

  if [[ -d "$O1_RO_ABSTRACT_DIR" ]]; then
    echo "ABSTRACT_DIR_EXISTS=yes"
  else
    echo "ABSTRACT_DIR_EXISTS=no"
    status=1
  fi

  if [[ -f "$O1_RO_ABSTRACT_LAYOUT_OA" ]]; then
    echo "LAYOUT_OA_EXISTS=yes"
  else
    echo "LAYOUT_OA_EXISTS=no"
    status=1
  fi

  if [[ -f "$O1_RO_ABSTRACT_DIR/master.tag" ]]; then
    echo "MASTER_TAG_EXISTS=yes"
  else
    echo "MASTER_TAG_EXISTS=no"
    status=1
  fi

  if [[ -r "$O1_RO_ABSTRACT_DIR" ]]; then
    echo "ABSTRACT_DIR_READABLE=yes"
  else
    echo "ABSTRACT_DIR_READABLE=no"
    status=1
  fi

  if [[ -x "$O1_RO_ABSTRACT_DIR" ]]; then
    echo "ABSTRACT_DIR_SEARCHABLE=yes"
  else
    echo "ABSTRACT_DIR_SEARCHABLE=no"
    status=1
  fi
} > "$RESULT_DIR/abstract_path_status.txt"

cat "$RESULT_DIR/abstract_path_status.txt"

{
  echo "ls -la $O1_RO_ABSTRACT_DIR"
  if [[ -d "$O1_RO_ABSTRACT_DIR" ]]; then
    ls -la "$O1_RO_ABSTRACT_DIR"
    echo
    echo "du -sh $O1_RO_ABSTRACT_DIR"
    du -sh "$O1_RO_ABSTRACT_DIR" || true
  else
    echo "MISSING: $O1_RO_ABSTRACT_DIR"
  fi
} > "$RESULT_DIR/abstract_files.txt"

{
  echo "Searching for nearby LEF/GDS/Liberty files under $O1_RO_LIB_ROOT"
  if [[ -d "$O1_RO_LIB_ROOT" ]]; then
    find "$O1_RO_LIB_ROOT" -maxdepth 5 \
      \( -iname "*RO_tune4*.lef" -o -iname "*.lef" \
         -o -iname "*RO_tune4*.gds" -o -iname "*.gds" \
         -o -iname "*RO_tune4*.lib" -o -iname "*.lib" \) -print | sort
  else
    echo "MISSING: $O1_RO_LIB_ROOT"
  fi
} > "$RESULT_DIR/nearby_lef_gds_lib_search.txt"

{
  echo "# O1 Real Abstract Locator Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- Abstract directory: \`$O1_RO_ABSTRACT_DIR\`"
  echo "- layout.oa: \`$O1_RO_ABSTRACT_LAYOUT_OA\`"
  echo "- Status file: \`abstract_path_status.txt\`"
  echo "- Nearby file search: \`nearby_lef_gds_lib_search.txt\`"
  echo
  if [[ $status -eq 0 ]]; then
    echo "LOCATOR_STATUS=PASS"
  else
    echo "LOCATOR_STATUS=FAILED"
    echo "O1A_REAL_ABSTRACT_RUN_BLOCKED=YES"
    echo "REASON=RO_tune4 abstract path or required OA files are missing/unreadable"
  fi
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"
exit "$status"
