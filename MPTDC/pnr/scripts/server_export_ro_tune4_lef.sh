#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_export_ro_tune4_lef}"
RESULT_DIR="$REPO_ROOT/results/osc_pd/$RUN_ID/real_abstract_lef"
LOG="$RESULT_DIR/export.log"
ENV_FILE="$MPTDC_DIR/analog_handoff/real_ro_tune4_abstract.env"
OUTPUT_LEF="$RESULT_DIR/RO_tune4_real_abstract.lef"

mkdir -p "$RESULT_DIR"
exec > >(tee "$LOG") 2>&1

echo "# O1 RO_tune4 LEF Export"
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

extract_lef_summaries() {
  local lef="$1"
  awk '
    /^[[:space:]]*MACRO[[:space:]]+/ {macro=$2; print "MACRO " macro}
    /^[[:space:]]*CLASS[[:space:]]+/ {print}
    /^[[:space:]]*ORIGIN[[:space:]]+/ {print}
    /^[[:space:]]*SIZE[[:space:]]+/ {print}
    /^[[:space:]]*SYMMETRY[[:space:]]+/ {print}
  ' "$lef" > "$RESULT_DIR/lef_macro_summary.txt"

  {
    echo "macro,pin_name,direction,use,layer,rect"
    awk '
      /^[[:space:]]*MACRO[[:space:]]+/ {macro=$2}
      /^[[:space:]]*PIN[[:space:]]+/ {pin=$2; direction=""; use=""; layer=""; rect=""}
      pin != "" && /^[[:space:]]*DIRECTION[[:space:]]+/ {direction=$2; gsub(/;/, "", direction)}
      pin != "" && /^[[:space:]]*USE[[:space:]]+/ {use=$2; gsub(/;/, "", use)}
      pin != "" && /^[[:space:]]*LAYER[[:space:]]+/ {layer=$2; gsub(/;/, "", layer)}
      pin != "" && /^[[:space:]]*RECT[[:space:]]+/ {
        rect=$0
        sub(/^[[:space:]]*RECT[[:space:]]+/, "", rect)
        gsub(/;/, "", rect)
      }
      pin != "" && /^[[:space:]]*END[[:space:]]+/ && $2 == pin {
        print macro "," pin "," direction "," use "," layer ",\"" rect "\""
        pin=""
      }
    ' "$lef"
  } > "$RESULT_DIR/lef_pin_summary.csv"

  awk '
    /^[[:space:]]*OBS[[:space:]]*$/ {inobs=1; print; next}
    inobs {print}
    inobs && /^[[:space:]]*END[[:space:]]*$/ {inobs=0}
  ' "$lef" > "$RESULT_DIR/lef_obs_summary.txt"
}

macro_name_from_lef() {
  awk '/^[[:space:]]*MACRO[[:space:]]+/ {print $2; exit}' "$1"
}

status=0
reason=""

if [[ ! -d "$O1_RO_LIB_ROOT" ]]; then
  status=2
  reason="O1_RO_LIB_ROOT missing: $O1_RO_LIB_ROOT"
elif [[ ! -d "$O1_RO_ABSTRACT_DIR" ]]; then
  status=2
  reason="O1_RO_ABSTRACT_DIR missing: $O1_RO_ABSTRACT_DIR"
else
  mapfile -t lef_candidates < <(find "$O1_RO_LIB_ROOT" -maxdepth 5 \
    \( -iname "*RO_tune4*.lef" -o -iname "*.lef" \) -print | sort)

  printf "%s\n" "${lef_candidates[@]}" > "$RESULT_DIR/lef_candidates.txt"

  selected_lef=""
  for candidate in "${lef_candidates[@]}"; do
    if [[ "$(basename "$candidate")" == *RO_tune4* ]]; then
      selected_lef="$candidate"
      break
    fi
  done
  if [[ -z "$selected_lef" && ${#lef_candidates[@]} -gt 0 ]]; then
    selected_lef="${lef_candidates[0]}"
  fi

  if [[ -n "$selected_lef" ]]; then
    echo "Found existing LEF candidate: $selected_lef"
    cp "$selected_lef" "$OUTPUT_LEF"
    extract_lef_summaries "$OUTPUT_LEF"
    macro_name="$(macro_name_from_lef "$OUTPUT_LEF")"
    if [[ "$macro_name" != "$O1_RO_CELL_NAME" ]]; then
      status=3
      reason="Existing LEF macro name '$macro_name' does not match expected '$O1_RO_CELL_NAME'"
    fi
  else
    echo "No existing LEF found under $O1_RO_LIB_ROOT"
    {
      echo "Available tool probes:"
      for tool in abstract virtuoso si lefout; do
        printf "%-10s " "$tool"
        command -v "$tool" || true
      done
    } > "$RESULT_DIR/available_export_tools.txt"
    cat "$RESULT_DIR/available_export_tools.txt"

    if [[ "${O1_ENABLE_VIRTUOSO_LEF_EXPORT:-0}" == "1" ]] && command -v virtuoso >/dev/null 2>&1; then
      SKILL="$RESULT_DIR/export_ro_tune4_lef.il"
      {
        echo "; Experimental site-specific export hook."
        echo "; Review with CAD support before relying on it for signoff."
        echo "printf(\"O1 export request for %s/%s/%s\\n\" \"$O1_RO_LIB_NAME\" \"$O1_RO_CELL_NAME\" \"$O1_RO_VIEW_NAME\")"
        echo "exit()"
      } > "$SKILL"
      virtuoso -nograph -replay "$SKILL" || status=$?
      if [[ ! -f "$OUTPUT_LEF" ]]; then
        status=4
        reason="Virtuoso export hook ran but did not create $OUTPUT_LEF"
      fi
    else
      status=4
      reason="No existing LEF found and automatic OA-to-LEF export is not enabled or not available"
      {
        echo "# Analog Designer LEF Export Request"
        echo
        echo "Please export LEF for SPADMIC/RO_tune4/abstract."
        echo
        echo "Required content:"
        echo "- macro name RO_tune4 or documented alias"
        echo "- all phase output pins"
        echo "- supply pins"
        echo "- enable/reset/test/tune pins"
        echo "- macro size"
        echo "- obstructions"
        echo "- legal orientation"
        echo "- pin layers/shapes/coordinates"
      } > "$RESULT_DIR/analog_designer_lef_request.md"
    fi
  fi
fi

if [[ -f "$OUTPUT_LEF" && ! -f "$RESULT_DIR/lef_macro_summary.txt" ]]; then
  extract_lef_summaries "$OUTPUT_LEF"
fi

{
  echo "# O1 RO_tune4 LEF Export Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)\`"
  echo "- OA abstract: \`$O1_RO_ABSTRACT_DIR\`"
  echo "- Output LEF: \`$OUTPUT_LEF\`"
  echo
  if [[ $status -eq 0 ]]; then
    echo "LEF_EXPORT_STATUS=PASS"
    echo "O1A_REAL_ABSTRACT_RUN_BLOCKED=NO"
    echo "O1_RO_LEF_PATH=$OUTPUT_LEF"
    if command -v sha256sum >/dev/null 2>&1; then
      echo "LEF_SHA256=$(sha256sum "$OUTPUT_LEF" | awk '{print $1}')"
    fi
  else
    echo "LEF_EXPORT_STATUS=FAILED"
    echo "O1A_REAL_ABSTRACT_RUN_BLOCKED=YES"
    echo "REASON=$reason"
  fi
  echo
  echo "Files:"
  for file in lef_candidates.txt available_export_tools.txt RO_tune4_real_abstract.lef lef_macro_summary.txt lef_pin_summary.csv lef_obs_summary.txt analog_designer_lef_request.md; do
    if [[ -f "$RESULT_DIR/$file" ]]; then
      echo "- present: \`$file\`"
    else
      echo "- missing: \`$file\`"
    fi
  done
} > "$RESULT_DIR/SUMMARY.md"

cat "$RESULT_DIR/SUMMARY.md"
exit "$status"
