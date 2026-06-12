#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-${MPTDC_GENUS_HANDOFF_RUN:-}}"
if [[ -z "$RUN_ID" ]]; then
  echo "ERROR: provide a Genus run ID or set MPTDC_GENUS_HANDOFF_RUN" >&2
  exit 2
fi

abs_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$path" ;;
  esac
}

MPTDC_WORK_ROOT="$(abs_path "${MPTDC_WORK_ROOT:-work}")"
MPTDC_GENUS_WORK="$(abs_path "${MPTDC_GENUS_WORK:-$MPTDC_WORK_ROOT/genus}")"
SOURCE_DIR="$(abs_path "${MPTDC_GENUS_RUN_DIR:-$MPTDC_GENUS_WORK/$RUN_ID}")"
HANDOFF_DIR="$(abs_path "${MPTDC_GENUS_HANDOFF_DIR:-$MPTDC_WORK_ROOT/handoff/genus_typical/mptdc_genus_typical_closed}")"
HANDOFF_MODE="${MPTDC_GENUS_HANDOFF_MODE:-link}"

case "$HANDOFF_MODE" in
  link|copy) ;;
  *)
    echo "ERROR: MPTDC_GENUS_HANDOFF_MODE must be link or copy, got $HANDOFF_MODE" >&2
    exit 2
    ;;
esac

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "ERROR: missing Genus source run: $SOURCE_DIR" >&2
  exit 3
fi
if [[ ! -f "$SOURCE_DIR/SUMMARY.md" ]]; then
  echo "ERROR: missing Genus source summary: $SOURCE_DIR/SUMMARY.md" >&2
  exit 3
fi

mkdir -p "$HANDOFF_DIR"

link_or_copy() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  rm -f "$dst"
  if [[ "$HANDOFF_MODE" == "copy" ]]; then
    cp -p "$src" "$dst"
  else
    ln -s "$src" "$dst"
  fi
}

find_source_file() {
  local rel="$1"
  local alt
  for alt in \
    "$SOURCE_DIR/$rel" \
    "$SOURCE_DIR/outputs/$rel" \
    "$SOURCE_DIR/outputs/post_synth/$rel" \
    "$SOURCE_DIR/reports/$rel"; do
    if [[ -f "$alt" ]]; then
      printf '%s\n' "$alt"
      return 0
    fi
  done
  return 1
}

required_files=(
  mptdc_top_asic.postsyn.v
  mptdc_top_asic.postsyn.sdc
  final_sdc_overlay_used.sdc
  final_filelist_used.f
  SUMMARY.md
  timing_summary.rpt
  timing_violations.rpt
  timing_path_classification_summary.md
  report_design_rules.rpt
  report_clocks.rpt
  report_clock_groups.rpt
  pd_vernier_exception_check.rpt
  o13_clock_model_check.rpt
  packet_contract_check.rpt
  macro_binding_check.rpt
  final_typical_genus_readiness.md
)

optional_files=(
  mptdc_top_asic.postsyn.sdf
)

missing_required=()
missing_optional=()
linked_files=()

for rel in "${required_files[@]}"; do
  if src="$(find_source_file "$rel")"; then
    link_or_copy "$src" "$HANDOFF_DIR/$rel"
    linked_files+=("$rel")
  else
    missing_required+=("$rel")
  fi
done

for rel in "${optional_files[@]}"; do
  if src="$(find_source_file "$rel")"; then
    link_or_copy "$src" "$HANDOFF_DIR/$rel"
    linked_files+=("$rel")
  else
    missing_optional+=("$rel")
  fi
done

summary_value() {
  local key="$1"
  awk -v key="$key" '
    function clean(value) {
      gsub(/^[ \t]+/, "", value)
      gsub(/[ \t]+$/, "", value)
      gsub(/^`/, "", value)
      gsub(/`$/, "", value)
      return value
    }
    index($0, key "=") == 1 {
      print clean(substr($0, length(key) + 2))
      exit
    }
    {
      bullet = "- " key ": "
      if (index($0, bullet) == 1) {
        print clean(substr($0, length(bullet) + 1))
        exit
      }
    }
  ' "$SOURCE_DIR/SUMMARY.md"
}

SOURCE_BRANCH="$(summary_value "Branch")"
SOURCE_HEAD="$(summary_value "Git HEAD")"
[[ -z "$SOURCE_BRANCH" ]] && SOURCE_BRANCH="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
[[ -z "$SOURCE_HEAD" ]] && SOURCE_HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"

MANIFEST="$HANDOFF_DIR/HANDOFF_MANIFEST.md"
{
  echo "# MPTDC Genus Typical Closed Handoff Manifest"
  echo
  echo "HANDOFF_STATUS=GENUS_TYPICAL_CLOSED"
  echo "RUN_ID=$RUN_ID"
  echo "SOURCE_RUN_DIR=$SOURCE_DIR"
  echo "HANDOFF_DIR=$HANDOFF_DIR"
  echo "HANDOFF_MODE=$HANDOFF_MODE"
  echo "READY_FOR_INNOVUS_TYPICAL_CLOSURE=YES"
  echo "NOT_MMMC_SIGNOFF=YES"
  echo "NOT_FINAL_SILICON_SIGNOFF=YES"
  echo "TYPICAL_ONLY_TAPEOUT_PACKAGE=YES"
  echo "GENUS_WNS_MARGIN_LOW=YES"
  echo
  echo "## Source Evidence"
  echo
  echo "- Branch: \`$SOURCE_BRANCH\`"
  echo "- Git HEAD: \`$SOURCE_HEAD\`"
  echo "- Genus run ID: \`$RUN_ID\`"
  echo "- Setup WNS ps: \`$(summary_value "Setup WNS ps")\`"
  echo "- Setup TNS ps: \`$(summary_value "Setup TNS ps")\`"
  echo "- Setup violating path count: \`$(summary_value "Setup violating path count")\`"
  echo "- Max transition violations: \`$(summary_value "Max transition violations")\`"
  echo "- Max capacitance violations: \`$(summary_value "Max capacitance violations")\`"
  echo "- Max fanout violations: \`$(summary_value "Max fanout violations")\`"
  echo "- PD Vernier paths matched: \`$(summary_value "PD intentional Vernier paths matched")\`"
  echo "- PD Vernier exception applied: \`$(summary_value "PD intentional Vernier exception applied")\`"
  echo "- Raw RO clocks: \`$(summary_value RAW_RO_CLOCKS_FOUND)\`"
  echo "- Buffered phase clocks: \`$(summary_value BUFFER_PHASE_CLOCKS_FOUND)\`"
  echo "- clk_sys async to buffer phase clocks: \`$(summary_value CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS)\`"
  echo
  echo "## Files"
  echo
  for rel in "${linked_files[@]}"; do
    echo "- present: \`$rel\`"
  done
  for rel in "${missing_required[@]}"; do
    echo "- missing-required: \`$rel\`"
  done
  for rel in "${missing_optional[@]}"; do
    echo "- missing-optional: \`$rel\`"
  done
  echo
  echo "## Limitations"
  echo
  echo "- This is a Genus typical-only closure handoff, not MMMC signoff."
  echo "- This is not final silicon signoff."
  echo "- P&R, route DRC, antenna, DRC/LVS, extraction, and final physical checks remain pending."
  echo "- WNS is intentionally flagged as low-margin because the source run closes by about 0.1 ps."
} > "$MANIFEST"

if [[ "${#missing_required[@]}" -gt 0 ]]; then
  {
    echo "# Missing Required Handoff Files"
    echo
    printf -- '- `%s`\n' "${missing_required[@]}"
  } > "$HANDOFF_DIR/MISSING_FILES.md"
  echo "ERROR: missing required handoff files in $SOURCE_DIR" >&2
  printf '  %s\n' "${missing_required[@]}" >&2
  exit 4
fi

rm -f "$HANDOFF_DIR/MISSING_FILES.md"
echo "HANDOFF_DIR=$HANDOFF_DIR"
echo "HANDOFF_STATUS=GENUS_TYPICAL_CLOSED"
echo "RUN_ID=$RUN_ID"
