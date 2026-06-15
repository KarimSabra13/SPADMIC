#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${RUN_ID:-}"
RUN_DIR="${RUN_DIR:-}"
DEST_ROOT="${MPTDC_GENUS_HANDOFF_ROOT:-}"
MAKE_TAR=0
FORCE=0

usage() {
  cat <<'USAGE'
Usage:
  package_genus_typical_handoff.sh <RUN_ID> [options]

Options:
  --run-id <id>       Genus run ID under work/genus/.
  --run-dir <path>    Explicit Genus run directory.
  --dest-root <path>  Handoff root. Default: work/handoff/genus_typical.
  --tar              Also create <RUN_ID>.tar.gz under the handoff root.
  --force            Package even if strict acceptance checks fail.
  -h, --help         Show this help.

The script is additive. It copies curated run evidence into work/handoff and
does not delete or modify the source Genus run directory.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="${2:?missing --run-id value}"
      shift 2
      ;;
    --run-dir)
      RUN_DIR="${2:?missing --run-dir value}"
      shift 2
      ;;
    --dest-root)
      DEST_ROOT="${2:?missing --dest-root value}"
      shift 2
      ;;
    --tar)
      MAKE_TAR=1
      shift
      ;;
    --force)
      FORCE=1
      shift
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
      if [[ -z "$RUN_ID" && -z "$RUN_DIR" ]]; then
        if [[ -d "$1" ]]; then
          RUN_DIR="$1"
        else
          RUN_ID="$1"
        fi
      else
        echo "ERROR: unexpected positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

MPTDC_WORK_ROOT="${MPTDC_WORK_ROOT:-work}"
case "$MPTDC_WORK_ROOT" in
  /*) ;;
  *) MPTDC_WORK_ROOT="$REPO_ROOT/$MPTDC_WORK_ROOT" ;;
esac

if [[ -z "$RUN_DIR" ]]; then
  if [[ -z "$RUN_ID" ]]; then
    echo "ERROR: provide RUN_ID or --run-dir" >&2
    usage >&2
    exit 2
  fi
  RUN_DIR="$MPTDC_WORK_ROOT/genus/$RUN_ID"
fi

case "$RUN_DIR" in
  /*) ;;
  *) RUN_DIR="$REPO_ROOT/$RUN_DIR" ;;
esac

if [[ -z "$RUN_ID" ]]; then
  RUN_ID="$(basename "$RUN_DIR")"
fi

if [[ -z "$DEST_ROOT" ]]; then
  DEST_ROOT="$MPTDC_WORK_ROOT/handoff/genus_typical"
fi
case "$DEST_ROOT" in
  /*) ;;
  *) DEST_ROOT="$REPO_ROOT/$DEST_ROOT" ;;
esac

SUMMARY="$RUN_DIR/SUMMARY.md"
if [[ ! -d "$RUN_DIR" ]]; then
  echo "ERROR: missing run directory: $RUN_DIR" >&2
  exit 2
fi
if [[ ! -f "$SUMMARY" ]]; then
  echo "ERROR: missing SUMMARY.md in run directory: $SUMMARY" >&2
  exit 2
fi

summary_value() {
  local key="$1"
  awk -v key="$key" '
    index($0, key "=") == 1 {
      print substr($0, length(key) + 2)
      exit
    }
    {
      bullet = "- " key ": "
      if (index($0, bullet) == 1) {
        value = substr($0, length(bullet) + 1)
        gsub(/`/, "", value)
        print value
        exit
      }
    }
  ' "$SUMMARY"
}

CHECK_TMP="$(mktemp)"
FAIL_TMP="$(mktemp)"
trap 'rm -f "$CHECK_TMP" "$FAIL_TMP"' EXIT

record_check() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  local status="$4"
  printf "%s\t%s\t%s\t%s\n" "$name" "$expected" "${actual:-MISSING}" "$status" >> "$CHECK_TMP"
  if [[ "$status" != "PASS" ]]; then
    printf "%s expected '%s' actual '%s'\n" "$name" "$expected" "${actual:-MISSING}" >> "$FAIL_TMP"
  fi
}

check_eq() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "${actual:-}" == "$expected" ]]; then
    record_check "$name" "$expected" "$actual" PASS
  else
    record_check "$name" "$expected" "${actual:-MISSING}" FAIL
  fi
}

check_nonnegative() {
  local name="$1"
  local actual="$2"
  if [[ -n "${actual:-}" && "$actual" != "NA" ]] && awk -v v="$actual" 'BEGIN { exit ((v + 0) >= 0 ? 0 : 1) }'; then
    record_check "$name" ">= 0" "$actual" PASS
  else
    record_check "$name" ">= 0" "${actual:-MISSING}" FAIL
  fi
}

FINAL_DECISION="$(summary_value FINAL_DECISION)"
GENUS_STATUS="$(summary_value GENUS_TYPICAL_STATUS)"
INNOVUS_READY="$(summary_value INNOVUS_READY)"
TYPICAL_PACKAGE="$(summary_value TYPICAL_ONLY_TAPEOUT_PACKAGE)"
NOT_MMMC="$(summary_value NOT_MMMC_SIGNOFF)"
FINAL_SIGNOFF="$(summary_value FINAL_SIGNOFF)"
GENUS_RC="$(summary_value "Genus exit code")"
SNAPSHOT_RC="$(summary_value "Snapshot exit code")"
SETUP_WNS_PS="$(summary_value "Setup WNS ps")"
SETUP_VIOLATING_PATHS="$(summary_value "Setup violating path count")"
REAL_TIMED_VIOLATING_PATHS="$(summary_value "Real timed violating path count")"
MAX_TRANSITION="$(summary_value "Max transition violations")"
MAX_CAPACITANCE="$(summary_value "Max capacitance violations")"
MAX_FANOUT="$(summary_value "Max fanout violations")"
PD_PATHS_MATCHED="$(summary_value "PD intentional Vernier paths matched")"
PD_SOURCES_MATCHED="$(summary_value "PD intentional Vernier sources matched")"
PD_EXCEPTION_APPLIED="$(summary_value "PD intentional Vernier exception applied")"
PD_EXCEPTION_OVERMATCH="$(summary_value "PD intentional Vernier overmatch")"
PD_EXCEPTION_UNDERMATCH="$(summary_value "PD intentional Vernier undermatch")"
UNKNOWN_REVIEW_REQUIRED="$(summary_value "UNKNOWN_REVIEW_REQUIRED count")"
SDC_FAILURES="$(summary_value "SDC command failure count")"
HELPERS_STATUS="$(summary_value "Report helpers status")"
FAST_TAG_MAPPING_STATUS="$(summary_value FAST_TAG_MAPPING_STATUS)"
FAST_TAG_TOP_PATHS="$(summary_value FAST_TAG_TOP_PATH_COUNT)"

check_eq "FINAL_DECISION" "GENUS_TYPICAL_CLOSED" "$FINAL_DECISION"
check_eq "GENUS_TYPICAL_STATUS" "GENUS_TYPICAL_CLOSED" "$GENUS_STATUS"
check_eq "INNOVUS_READY" "READY_FOR_O13_INNOVUS_FEASIBILITY" "$INNOVUS_READY"
check_eq "TYPICAL_ONLY_TAPEOUT_PACKAGE" "YES" "$TYPICAL_PACKAGE"
check_eq "NOT_MMMC_SIGNOFF" "YES" "$NOT_MMMC"
check_eq "FINAL_SIGNOFF" "NO" "$FINAL_SIGNOFF"
check_eq "Genus exit code" "0" "$GENUS_RC"
check_eq "Snapshot exit code" "0" "$SNAPSHOT_RC"
check_nonnegative "Setup WNS ps" "$SETUP_WNS_PS"
check_eq "Setup violating path count" "0" "$SETUP_VIOLATING_PATHS"
check_eq "Real timed violating path count" "0" "$REAL_TIMED_VIOLATING_PATHS"
check_eq "Max transition violations" "0" "$MAX_TRANSITION"
check_eq "Max capacitance violations" "0" "$MAX_CAPACITANCE"
check_eq "Max fanout violations" "0" "$MAX_FANOUT"
check_eq "PD intentional Vernier paths matched" "64" "$PD_PATHS_MATCHED"
check_eq "PD intentional Vernier sources matched" "8" "$PD_SOURCES_MATCHED"
check_eq "PD intentional Vernier exception applied" "YES" "$PD_EXCEPTION_APPLIED"
check_eq "PD intentional Vernier overmatch" "NO" "$PD_EXCEPTION_OVERMATCH"
check_eq "PD intentional Vernier undermatch" "NO" "$PD_EXCEPTION_UNDERMATCH"
check_eq "UNKNOWN_REVIEW_REQUIRED count" "0" "$UNKNOWN_REVIEW_REQUIRED"
check_eq "SDC command failure count" "0" "$SDC_FAILURES"
check_eq "Report helpers status" "PASS" "$HELPERS_STATUS"
check_eq "FAST_TAG_MAPPING_STATUS" "PASS" "$FAST_TAG_MAPPING_STATUS"
check_eq "FAST_TAG_TOP_PATH_COUNT" "0" "$FAST_TAG_TOP_PATHS"

if [[ -s "$FAIL_TMP" && "$FORCE" != "1" ]]; then
  echo "ERROR: run is not package-clean. Use --force only for review packages." >&2
  cat "$FAIL_TMP" >&2
  exit 3
fi

DEST_DIR="$DEST_ROOT/$RUN_ID"
STAGING_DIR="$DEST_ROOT/.${RUN_ID}.staging.$$"
if [[ -e "$DEST_DIR" ]]; then
  echo "ERROR: destination already exists: $DEST_DIR" >&2
  echo "Refusing to overwrite an existing handoff package." >&2
  exit 4
fi
if [[ -e "$STAGING_DIR" ]]; then
  echo "ERROR: staging destination already exists: $STAGING_DIR" >&2
  exit 4
fi

cleanup_staging() {
  rm -f "$CHECK_TMP" "$FAIL_TMP"
  if [[ -d "$STAGING_DIR" ]]; then
    rm -rf "$STAGING_DIR"
  fi
}
trap cleanup_staging EXIT

mkdir -p "$STAGING_DIR"
COPY_MAP="$STAGING_DIR/MANIFEST.sources.tsv"
MISSING_OPTIONAL="$STAGING_DIR/MISSING_OPTIONAL.txt"
: > "$COPY_MAP"
: > "$MISSING_OPTIONAL"

copy_file() {
  local src="$1"
  local rel="$2"
  local dst="$STAGING_DIR/$rel"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
    printf "%s\t%s\n" "$rel" "$src" >> "$COPY_MAP"
  else
    printf "%s\n" "$src" >> "$MISSING_OPTIONAL"
  fi
}

copy_glob() {
  local rel_dir="$1"
  shift
  local matched=0
  local src
  shopt -s nullglob
  for src in "$@"; do
    if [[ -f "$src" ]]; then
      copy_file "$src" "$rel_dir/$(basename "$src")"
      matched=1
    fi
  done
  shopt -u nullglob
  if [[ "$matched" == "0" ]]; then
    printf "%s\n" "$rel_dir: no glob matches" >> "$MISSING_OPTIONAL"
  fi
}

copy_dir() {
  local src="$1"
  local rel="$2"
  local dst="$STAGING_DIR/$rel"
  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    cp -a "$src/." "$dst/"
    printf "%s\t%s\n" "$rel/" "$src/" >> "$COPY_MAP"
  else
    printf "%s\n" "$src/" >> "$MISSING_OPTIONAL"
  fi
}

copy_file "$RUN_DIR/SUMMARY.md" "00_decision/SUMMARY.md"
copy_file "$RUN_DIR/final_typical_genus_readiness.md" "00_decision/final_typical_genus_readiness.md"
copy_file "$RUN_DIR/summary_parser_check.rpt" "00_decision/summary_parser_check.rpt"
copy_file "$RUN_DIR/report_helpers_status.rpt" "00_decision/report_helpers_status.rpt"
copy_file "$RUN_DIR/fast_tag_cell_mapping_guardrail.rpt" "00_decision/fast_tag_cell_mapping_guardrail.rpt"
copy_file "$RUN_DIR/run_manifest.txt" "01_inputs/run_manifest.txt"
copy_file "$RUN_DIR/final_filelist_used.f" "01_inputs/final_filelist_used.f"
copy_file "$RUN_DIR/final_sdc_overlay_used.sdc" "01_inputs/final_sdc_overlay_used.sdc"
copy_file "$RUN_DIR/o13_phase_distribution_check.rpt" "01_inputs/o13_phase_distribution_check.rpt"
copy_file "$RUN_DIR/macro_binding_check.rpt" "01_inputs/macro_binding_check.rpt"
copy_file "$RUN_DIR/packet_contract_check.rpt" "01_inputs/packet_contract_check.rpt"
copy_file "$RUN_DIR/pd_vernier_exception_check.rpt" "01_inputs/pd_vernier_exception_check.rpt"
copy_file "$RUN_DIR/pd_vernier_endpoint_discovery.rpt" "01_inputs/pd_vernier_endpoint_discovery.rpt"
copy_file "$RUN_DIR/pd_vernier_source_discovery.rpt" "01_inputs/pd_vernier_source_discovery.rpt"
copy_file "$RUN_DIR/o13_clock_model_check.rpt" "01_inputs/o13_clock_model_check.rpt"
copy_file "$RUN_DIR/o13_clock_model_check.sdc.rpt" "01_inputs/o13_clock_model_check.sdc.rpt"
copy_file "$RUN_DIR/check_timing_intent_post_synth.rpt" "01_inputs/check_timing_intent_post_synth.rpt"
copy_file "$RUN_DIR/report_clocks.rpt" "01_inputs/report_clocks.rpt"
copy_file "$RUN_DIR/report_clocks_generated.rpt" "01_inputs/report_clocks_generated.rpt"
copy_file "$RUN_DIR/report_clock_groups.rpt" "01_inputs/report_clock_groups.rpt"
copy_file "$RUN_DIR/report_exceptions.rpt" "01_inputs/report_exceptions.rpt"
copy_file "$RUN_DIR/sdc_command_failures.md" "01_inputs/sdc_command_failures.md"

copy_file "$RUN_DIR/timing_summary.rpt" "02_timing/timing_summary.rpt"
copy_file "$RUN_DIR/timing_violations.rpt" "02_timing/timing_violations.rpt"
copy_file "$RUN_DIR/timing_pd_capture_hotspots.rpt" "02_timing/timing_pd_capture_hotspots.rpt"
copy_file "$RUN_DIR/timing_clk_sys_violations.rpt" "02_timing/timing_clk_sys_violations.rpt"
copy_file "$RUN_DIR/timing_clk_sys_internal_top100.rpt" "02_timing/timing_clk_sys_internal_top100.rpt"
copy_file "$RUN_DIR/timing_cdc_async_review.rpt" "02_timing/timing_cdc_async_review.rpt"
copy_file "$RUN_DIR/timing_pd_intentional_vernier.rpt" "02_timing/timing_pd_intentional_vernier.rpt"
copy_file "$RUN_DIR/timing_o13_phase_buffer_paths.rpt" "02_timing/timing_o13_phase_buffer_paths.rpt"
copy_file "$RUN_DIR/timing_path_classification.csv" "02_timing/timing_path_classification.csv"
copy_file "$RUN_DIR/timing_path_classification_summary.md" "02_timing/timing_path_classification_summary.md"

copy_file "$RUN_DIR/report_design_rules.rpt" "03_drv_qor/report_design_rules.rpt"
copy_file "$RUN_DIR/report_high_fanout.rpt" "03_drv_qor/report_high_fanout.rpt"
copy_file "$RUN_DIR/report_area.rpt" "03_drv_qor/report_area.rpt"
copy_file "$RUN_DIR/report_qor.rpt" "03_drv_qor/report_qor.rpt"
copy_file "$RUN_DIR/report_power.rpt" "03_drv_qor/report_power.rpt"
copy_file "$RUN_DIR/report_power_hier.rpt" "03_drv_qor/report_power_hier.rpt"
copy_file "$RUN_DIR/reports/drv_transition_root_causes.csv" "03_drv_qor/drv_transition_root_causes.csv"
copy_file "$RUN_DIR/reports/control_drv_root_causes.csv" "03_drv_qor/control_drv_root_causes.csv"

copy_file "$RUN_DIR/final_typical_genus_repair_1.rpt" "04_repair/final_typical_genus_repair_1.rpt"
copy_file "$RUN_DIR/final_genus_fast_tag_to_pd_ts_analysis.md" "04_repair/final_genus_fast_tag_to_pd_ts_analysis.md"
copy_file "$RUN_DIR/helper_tcl_selftest.rpt" "04_repair/helper_tcl_selftest.rpt"
copy_file "$RUN_DIR/reports/fast_tag_cell_mapping.csv" "04_repair/fast_tag_cell_mapping.csv"

copy_file "$RUN_DIR/outputs/mptdc_axis_core.postsyn.v" "05_outputs/mptdc_axis_core.postsyn.v"
copy_file "$RUN_DIR/outputs/mptdc_axis_core.postsyn.sdc" "05_outputs/mptdc_axis_core.postsyn.sdc"
copy_file "$RUN_DIR/outputs/mptdc_axis_core.postsyn.sdf" "05_outputs/mptdc_axis_core.postsyn.sdf"
copy_dir "$RUN_DIR/outputs/post_synth" "06_innovus_import/post_synth"

copy_glob "07_logs" "$RUN_DIR"/genus*.log "$RUN_DIR/logs"/*.log "$MPTDC_WORK_ROOT/logs/${RUN_ID}"*.log

copy_dir "$RUN_DIR/reports/synthesis/post_elaboration" "08_full_reports/synthesis/post_elaboration"
copy_dir "$RUN_DIR/reports/synthesis/post_synthesis" "08_full_reports/synthesis/post_synthesis"

{
  printf "check\texpected\tactual\tstatus\n"
  cat "$CHECK_TMP"
} > "$STAGING_DIR/00_decision/PACKAGE_CHECKS.tsv"

PACKAGE_TIME="$(date -Iseconds)"
BRANCH="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
HEAD_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
SOURCE_SNAPSHOT_DIR="$(awk -F': ' '/^snapshot_dir:/ {print $2; exit}' "$RUN_DIR/run_manifest.txt" 2>/dev/null || true)"

cat > "$STAGING_DIR/00_decision/DECISION_RECORD.md" <<EOF
# MPTDC Genus Typical Handoff Decision

- Run ID: \`$RUN_ID\`
- Source run directory: \`$RUN_DIR\`
- Package created: \`$PACKAGE_TIME\`
- Branch at packaging: \`$BRANCH\`
- HEAD at packaging: \`$HEAD_SHA\`
- Genus run HEAD: \`$(awk -F': ' '/^head:/ {print $2; exit}' "$RUN_DIR/run_manifest.txt" 2>/dev/null || true)\`
- Source snapshot directory: \`${SOURCE_SNAPSHOT_DIR:-not recorded}\`

## Decision

Accept this run as the clean typical-only Genus handoff package for O13 Innovus
feasibility.

This is not MMMC signoff and not final tapeout signoff. It is the accepted
single-view Genus package for the next physical implementation step.

## Why This Run Is Accepted

- \`FINAL_DECISION=$FINAL_DECISION\`
- \`INNOVUS_READY=$INNOVUS_READY\`
- Genus and snapshot exit codes are \`$GENUS_RC\` / \`$SNAPSHOT_RC\`.
- Real timed setup is clean: WNS \`${SETUP_WNS_PS} ps\`, setup violating paths \`$SETUP_VIOLATING_PATHS\`.
- DRV is clean: max transition/capacitance/fanout \`$MAX_TRANSITION/$MAX_CAPACITANCE/$MAX_FANOUT\`.
- O13 phase-clock model is intact and the PD Vernier exception matched \`$PD_PATHS_MATCHED\` paths from \`$PD_SOURCES_MATCHED\` sources.
- PD Vernier exception application is exact: applied \`$PD_EXCEPTION_APPLIED\`, overmatch \`$PD_EXCEPTION_OVERMATCH\`, undermatch \`$PD_EXCEPTION_UNDERMATCH\`.
- Report helpers, summary parsing, raw agreement, and fast-tag mapping guardrails pass.

## Design Decisions Preserved

- Standard-cell family: JIHD D_CELLS, 1.8 V typical Liberty.
- Frequency mode: \`r750_delta5\`.
- Phase topology: \`RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric\`.
- Packet format and \`raw_lfsr_tag\` encoding are unchanged.
- \`FAST_TAG_TO_PD_TS\` remains real timed fast oscillator-domain setup timing;
  it was fixed by targeted tap0 bit 5/6 data-path pressure, not by false-path
  or multicycle relaxation.
- The O13 PD Vernier exception is kept scoped to the intentional slow-to-q1
  Vernier structure.

## Handoff Boundary

Move forward to O13 Innovus feasibility using the copied netlist/SDC and the
Genus Innovus import directory in this package. Do not call this MMMC or final
signoff; post-layout Innovus, route, extraction, DRC/LVS, power, and analog
phase confirmation remain separate gates.
EOF

cat > "$STAGING_DIR/README.md" <<EOF
# MPTDC Genus Typical Handoff Package

Run: \`$RUN_ID\`

This directory is a curated, non-destructive copy of the Genus run needed for
O13 Innovus feasibility. The original source run remains at:

\`$RUN_DIR\`

## Directory Map

- \`00_decision/\`: final summary, acceptance checks, and decision record.
- \`01_inputs/\`: manifests, SDC/filelist evidence, clock/exception checks.
- \`02_timing/\`: timing reports and path classification.
- \`03_drv_qor/\`: DRV, QoR, area, power, and root-cause CSVs.
- \`04_repair/\`: exact tap0 repair evidence and fast-tag guardrails.
- \`05_outputs/\`: exported postsynthesis netlist, SDC, and SDF.
- \`06_innovus_import/\`: Genus \`write_design -innovus\` export for Innovus.
- \`07_logs/\`: Genus and console logs when available.
- \`08_full_reports/\`: full synthesis report subtrees when available.

## Status

\`GENUS_TYPICAL_CLOSED\` for typical-only Genus handoff.

Not MMMC signoff. Not final tapeout signoff.
EOF

cat > "$STAGING_DIR/NEXT_STEPS_INNOVUS.md" <<EOF
# Next Step: O13 Innovus Feasibility

Use this package as the Genus input source for the next physical run.

Key files:

- Netlist: \`05_outputs/mptdc_axis_core.postsyn.v\`
- SDC: \`05_outputs/mptdc_axis_core.postsyn.sdc\`
- Genus Innovus setup: \`06_innovus_import/post_synth/mptdc_axis_core.invs_setup.tcl\`
- Genus MMMC export: \`06_innovus_import/post_synth/mptdc_axis_core.mmmc.tcl\`

Recommended immediate command after packaging:

\`\`\`bash
cd "$REPO_ROOT"
RUN_ID="$RUN_ID"
HANDOFF_DIR="$DEST_ROOT/$RUN_ID"
find "\$HANDOFF_DIR" -maxdepth 2 -type f | sort
\`\`\`

The current stable Innovus wrapper is a feasibility/report-oriented O13 flow.
If it is used before a direct Genus-import implementation wrapper is added,
keep the result labeled as O13 Innovus feasibility, not final signoff.
EOF

{
  echo "# Source File Map"
  echo
  echo "| Package path | Source path |"
  echo "|---|---|"
  awk -F'\t' '{printf "| `%s` | `%s` |\n", $1, $2}' "$COPY_MAP"
} > "$STAGING_DIR/SOURCE_FILE_MAP.md"

{
  echo "# Package File Manifest"
  echo
  echo "Created: \`$PACKAGE_TIME\`"
  echo
  echo "| SHA256 | Bytes | Path |"
  echo "|---|---:|---|"
  (
    cd "$STAGING_DIR"
    find . -type f ! -name 'SHA256SUMS' -printf '%P\n' | sort | while IFS= read -r rel; do
      sum="$(sha256sum "$rel" | awk '{print $1}')"
      bytes="$(wc -c < "$rel" | tr -d ' ')"
      printf '| `%s` | %s | `%s` |\n' "$sum" "$bytes" "$rel"
    done
  )
} > "$STAGING_DIR/MANIFEST.md"

(
  cd "$STAGING_DIR"
  find . -type f ! -name 'SHA256SUMS' -printf '%P\n' | sort | xargs -r sha256sum > SHA256SUMS
)

mkdir -p "$DEST_ROOT"
mv "$STAGING_DIR" "$DEST_DIR"
trap - EXIT
rm -f "$CHECK_TMP" "$FAIL_TMP"

printf "%s\n" "$RUN_ID" > "$DEST_ROOT/LATEST_RUN.txt"

if [[ "$MAKE_TAR" == "1" ]]; then
  (
    cd "$DEST_ROOT"
    tar -czf "${RUN_ID}.tar.gz" "$RUN_ID"
  )
  echo "Tarball written: $DEST_ROOT/${RUN_ID}.tar.gz"
fi

echo "Genus typical handoff package written: $DEST_DIR"
echo "Decision record: $DEST_DIR/00_decision/DECISION_RECORD.md"
echo "Next steps: $DEST_DIR/NEXT_STEPS_INNOVUS.md"
