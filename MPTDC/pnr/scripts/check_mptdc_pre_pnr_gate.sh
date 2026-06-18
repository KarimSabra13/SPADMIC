#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID=""
RUN_DIR=""
HANDOFF_DIR=""

usage() {
  cat <<'USAGE'
Usage:
  check_mptdc_pre_pnr_gate.sh --genus-run-id <RUN_ID>
  check_mptdc_pre_pnr_gate.sh --genus-run-dir <PATH>

Options:
  --genus-run-id <id>     Genus run ID under work/genus/.
  --genus-run-dir <path>  Explicit Genus run directory or handoff package.
  --handoff-dir <path>    Explicit handoff package directory.
  -h, --help              Show this help.

Environment:
  MPTDC_WORK_ROOT                    Default: work
  MPTDC_GENUS_WORK                   Default: $MPTDC_WORK_ROOT/genus
  MPTDC_GENUS_HANDOFF_ROOT           Default: $MPTDC_WORK_ROOT/handoff/genus_typical
  MPTDC_PRE_PNR_GATE_REQUIRE_HANDOFF Set to 1 to reject source-run-only checks.
  MPTDC_PRE_PNR_GATE_ALLOW_REVIEW    Set to 1 to exit 0 with REVIEW_OVERRIDE.
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
    --genus-run-id)
      RUN_ID="${2:?missing --genus-run-id value}"
      shift 2
      ;;
    --genus-run-dir)
      RUN_DIR="$(abs_path "${2:?missing --genus-run-dir value}")"
      shift 2
      ;;
    --handoff-dir)
      HANDOFF_DIR="$(abs_path "${2:?missing --handoff-dir value}")"
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
      if [[ -z "$RUN_ID" && -z "$RUN_DIR" ]]; then
        if [[ -d "$1" ]]; then
          RUN_DIR="$(abs_path "$1")"
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

MPTDC_WORK_ROOT="$(abs_path "${MPTDC_WORK_ROOT:-work}")"
MPTDC_GENUS_WORK="$(abs_path "${MPTDC_GENUS_WORK:-$MPTDC_WORK_ROOT/genus}")"
MPTDC_GENUS_HANDOFF_ROOT="$(abs_path "${MPTDC_GENUS_HANDOFF_ROOT:-$MPTDC_WORK_ROOT/handoff/genus_typical}")"
DEFAULT_CLOSED_HANDOFF="$MPTDC_GENUS_HANDOFF_ROOT/mptdc_genus_typical_closed"

if [[ -n "$RUN_ID" ]]; then
  [[ -z "$RUN_DIR" ]] && RUN_DIR="$MPTDC_GENUS_WORK/$RUN_ID"
  if [[ -z "$HANDOFF_DIR" && -d "$DEFAULT_CLOSED_HANDOFF" ]]; then
    HANDOFF_DIR="$DEFAULT_CLOSED_HANDOFF"
  elif [[ -z "$HANDOFF_DIR" ]]; then
    HANDOFF_DIR="$MPTDC_GENUS_HANDOFF_ROOT/$RUN_ID"
  fi
fi

if [[ -n "$RUN_DIR" && -z "$RUN_ID" ]]; then
  RUN_ID="$(basename "$RUN_DIR")"
fi

if [[ -z "$RUN_ID" && -z "$RUN_DIR" && -z "$HANDOFF_DIR" ]]; then
  echo "ERROR: provide --genus-run-id or --genus-run-dir" >&2
  usage >&2
  exit 2
fi

select_summary() {
  local root="$1"
  for rel in 00_decision/SUMMARY.md SUMMARY.md; do
    if [[ -f "$root/$rel" ]]; then
      printf '%s/%s\n' "$root" "$rel"
      return 0
    fi
  done
  return 1
}

is_handoff_dir() {
  [[ -f "$1/HANDOFF_MANIFEST.md" || -f "$1/00_decision/SUMMARY.md" || -f "$1/SUMMARY.md" ]]
}

SOURCE_KIND=""
SOURCE_ROOT=""
SUMMARY=""
PACKAGE_CHECKS=""

if [[ -n "$HANDOFF_DIR" && -d "$HANDOFF_DIR" ]] && is_handoff_dir "$HANDOFF_DIR" && SUMMARY="$(select_summary "$HANDOFF_DIR")"; then
  SOURCE_KIND="handoff"
  SOURCE_ROOT="$HANDOFF_DIR"
  PACKAGE_CHECKS="$HANDOFF_DIR/00_decision/PACKAGE_CHECKS.tsv"
elif [[ -n "$RUN_DIR" && -d "$RUN_DIR" ]] && is_handoff_dir "$RUN_DIR" && SUMMARY="$(select_summary "$RUN_DIR")"; then
  SOURCE_KIND="handoff"
  SOURCE_ROOT="$RUN_DIR"
  PACKAGE_CHECKS="$RUN_DIR/00_decision/PACKAGE_CHECKS.tsv"
elif [[ "${MPTDC_PRE_PNR_GATE_REQUIRE_HANDOFF:-0}" == "1" ]]; then
  echo "ERROR: required handoff package not found for run: ${RUN_ID:-unknown}" >&2
  echo "Tried: ${HANDOFF_DIR:-unset}" >&2
  PRE_PNR_GATE=FAIL
  export PRE_PNR_GATE
  exit 3
elif [[ -n "$RUN_DIR" && -d "$RUN_DIR" ]]; then
  SOURCE_KIND="source_run"
  SOURCE_ROOT="$RUN_DIR"
  SUMMARY="$RUN_DIR/SUMMARY.md"
else
  echo "ERROR: Genus run or handoff package not found for run: ${RUN_ID:-unknown}" >&2
  echo "Tried source: ${RUN_DIR:-unset}" >&2
  echo "Tried handoff: ${HANDOFF_DIR:-unset}" >&2
  PRE_PNR_GATE=FAIL
  export PRE_PNR_GATE
  exit 3
fi

if [[ ! -f "$SUMMARY" ]]; then
  echo "ERROR: missing Genus summary: $SUMMARY" >&2
  PRE_PNR_GATE=FAIL
  export PRE_PNR_GATE
  exit 3
fi

summary_value() {
  local key="$1"
  local files=("$SUMMARY")
  [[ -f "$SOURCE_ROOT/HANDOFF_MANIFEST.md" ]] && files+=("$SOURCE_ROOT/HANDOFF_MANIFEST.md")
  [[ -f "$SOURCE_ROOT/00_decision/HANDOFF_MANIFEST.md" ]] && files+=("$SOURCE_ROOT/00_decision/HANDOFF_MANIFEST.md")
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
      plain = key ": "
      if (index($0, plain) == 1) {
        print clean(substr($0, length(plain) + 1))
        exit
      }
    }
  ' "${files[@]}"
}

first_nonempty() {
  local value
  for value in "$@"; do
    if [[ -n "${value:-}" ]]; then
      printf '%s\n' "$value"
      return 0
    fi
  done
  printf '\n'
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
  if [[ "$status" != "PASS" && "$status" != "WARN" ]]; then
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

check_in() {
  local name="$1"
  local expected_label="$2"
  local actual="$3"
  shift 3
  local allowed
  for allowed in "$@"; do
    if [[ "${actual:-}" == "$allowed" ]]; then
      record_check "$name" "$expected_label" "$actual" PASS
      return
    fi
  done
  record_check "$name" "$expected_label" "${actual:-MISSING}" FAIL
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

check_zero_number() {
  local name="$1"
  local actual="$2"
  if [[ -n "${actual:-}" && "$actual" != "NA" ]] && awk -v v="$actual" 'BEGIN { exit ((v + 0) == 0 ? 0 : 1) }'; then
    record_check "$name" "0" "$actual" PASS
  else
    record_check "$name" "0" "${actual:-MISSING}" FAIL
  fi
}

check_file_any() {
  local label="$1"
  shift
  local rel path
  for rel in "$@"; do
    path="$SOURCE_ROOT/$rel"
    if [[ -f "$path" ]]; then
      record_check "$label" "file exists" "$path" PASS
      return
    fi
  done
  record_check "$label" "file exists" "$SOURCE_ROOT/${1:-}" FAIL
}

check_contains_any() {
  local name="$1"
  local expected="$2"
  shift 2
  local file pattern
  local files=("$SUMMARY")
  for file in "$SOURCE_ROOT/run_manifest.txt" "$SOURCE_ROOT/HANDOFF_MANIFEST.md" "$SOURCE_ROOT/00_decision/HANDOFF_MANIFEST.md"; do
    [[ -f "$file" ]] && files+=("$file")
  done
  for pattern in "$@"; do
    if grep -Eiq -- "$pattern" "${files[@]}"; then
      record_check "$name" "$expected" "$pattern" PASS
      return
    fi
  done
  record_check "$name" "$expected" "MISSING" FAIL
}

FINAL_DECISION="$(summary_value FINAL_DECISION)"
GENUS_STATUS="$(summary_value GENUS_TYPICAL_STATUS)"
READY_LABEL="$(summary_value INNOVUS_READY)"
READY_FOR_TYPICAL="$(summary_value READY_FOR_INNOVUS_TYPICAL_CLOSURE)"
if [[ -z "$READY_FOR_TYPICAL" && "$READY_LABEL" == "READY_FOR_INNOVUS_TYPICAL_CLOSURE" ]]; then
  READY_FOR_TYPICAL="YES"
fi
if [[ -z "$READY_FOR_TYPICAL" && "$FINAL_DECISION" == "GENUS_TYPICAL_CLOSED" && "$GENUS_STATUS" == "GENUS_TYPICAL_CLOSED" ]]; then
  READY_FOR_TYPICAL="YES"
fi
TYPICAL_PACKAGE="$(summary_value TYPICAL_ONLY_TAPEOUT_PACKAGE)"
NOT_MMMC="$(summary_value NOT_MMMC_SIGNOFF)"
FINAL_SIGNOFF="$(summary_value FINAL_SIGNOFF)"
GENUS_RC="$(summary_value "Genus exit code")"
SNAPSHOT_RC="$(summary_value "Snapshot exit code")"
FREQUENCY_MODE="$(summary_value "Frequency mode")"
PHASE_TOPOLOGY="$(summary_value "Phase buffer topology")"
PACKET_FORMAT="$(summary_value "Packet format")"
RAW_LFSR_TAG="$(summary_value raw_lfsr_tag)"
SETUP_WNS_PS="$(summary_value "Setup WNS ps")"
SETUP_TNS_PS="$(summary_value "Setup TNS ps")"
SETUP_VIOLATING_PATHS="$(summary_value "Setup violating path count")"
REAL_TIMED_WNS_PS="$(summary_value "Real timed WNS ps")"
REAL_TIMED_TNS_PS="$(summary_value "Real timed TNS ps")"
REAL_TIMED_VIOLATING_PATHS="$(summary_value "Real timed violating path count")"
MAX_TRANSITION="$(summary_value "Max transition violations")"
MAX_CAPACITANCE="$(summary_value "Max capacitance violations")"
MAX_FANOUT="$(summary_value "Max fanout violations")"
RO_TUNE4_COUNT="$(summary_value "RO_tune4 instance count")"
OSC_STUB_COUNT="$(summary_value "mptdc_osc_stub residue count")"
BUHDX4_COUNT="$(summary_value "BUHDX4 instance count")"
BUHDX12_COUNT="$(summary_value "BUHDX12 instance count")"
BUJIHDX4_COUNT="$(summary_value "BUJIHDX4 instance count")"
BUJIHDX12_COUNT="$(summary_value "BUJIHDX12 instance count")"
RAW_RO_CLOCKS_FOUND="$(summary_value RAW_RO_CLOCKS_FOUND)"
BUFFER_PHASE_CLOCKS_FOUND="$(summary_value BUFFER_PHASE_CLOCKS_FOUND)"
BUFFER_PHASE_CLOCKS_EXPECTED="$(summary_value BUFFER_PHASE_CLOCKS_EXPECTED)"
BUFFER_PHASE_ASYNC="$(summary_value BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP)"
CLK_SYS_ASYNC="$(summary_value CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS)"
PD_PATHS_MATCHED="$(summary_value "PD intentional Vernier paths matched")"
PD_SOURCES_MATCHED="$(summary_value "PD intentional Vernier sources matched")"
PD_EXCEPTION_APPLIED="$(summary_value "PD intentional Vernier exception applied")"
PD_EXCEPTION_OVERMATCH="$(summary_value "PD intentional Vernier overmatch")"
PD_EXCEPTION_UNDERMATCH="$(summary_value "PD intentional Vernier undermatch")"
UNKNOWN_REVIEW_REQUIRED="$(summary_value "UNKNOWN_REVIEW_REQUIRED count")"
SDC_FAILURES="$(summary_value "SDC command failure count")"
ACTIVE_SDC_FAILURES="$(first_nonempty "$(summary_value ACTIVE_SDC_FAILURE_COUNT)" "$SDC_FAILURES")"
HELPERS_STATUS="$(summary_value "Report helpers status")"
SUMMARY_RAW_AGREEMENT="$(first_nonempty "$(summary_value "Summary/raw agreement status")" "$(summary_value SUMMARY_RAW_AGREEMENT_STATUS)")"
FAST_TAG_MAPPING_PARSE_STATUS="$(summary_value FAST_TAG_MAPPING_PARSE_STATUS)"
FAST_TAG_MAPPING_STATUS="$(summary_value FAST_TAG_MAPPING_STATUS)"
EXACT_REPAIR_STATUS="$(summary_value EXACT_FAST_TAG_REPAIR_STATUS)"
EXACT_SOURCE_CELL_REQUESTED="$(summary_value FAST_TAG_EXACT_SOURCE_CELL_REQUESTED)"
EXACT_SOURCE_CELL_RESULT="$(summary_value FAST_TAG_EXACT_SOURCE_CELL_RESULT)"

check_eq "FINAL_DECISION" "GENUS_TYPICAL_CLOSED" "$FINAL_DECISION"
check_eq "GENUS_TYPICAL_STATUS" "GENUS_TYPICAL_CLOSED" "$GENUS_STATUS"
check_eq "READY_FOR_INNOVUS_TYPICAL_CLOSURE" "YES" "$READY_FOR_TYPICAL"
check_eq "TYPICAL_ONLY_TAPEOUT_PACKAGE" "YES" "$TYPICAL_PACKAGE"
check_eq "NOT_MMMC_SIGNOFF" "YES" "$NOT_MMMC"
check_eq "FINAL_SIGNOFF" "NO" "$FINAL_SIGNOFF"
check_eq "Genus exit code" "0" "$GENUS_RC"
check_eq "Snapshot exit code" "0" "$SNAPSHOT_RC"
check_eq "Frequency mode" "r750_delta5" "$FREQUENCY_MODE"
check_eq "Packet format" "unchanged" "$PACKET_FORMAT"
check_eq "raw_lfsr_tag" "unchanged" "$RAW_LFSR_TAG"
check_contains_any "MPTDC_OPT_MODE" "STRIDE2 active" "MPTDC_OPT_MODE[=:][[:space:]]*STRIDE2" "mptdc_opt_mode:[[:space:]]*STRIDE2" "spadmic_test_stride2"
check_in "Phase buffer topology" "BUJIHDX4 -> BUJIHDX12" "$PHASE_TOPOLOGY" "BUJIHDX4 -> BUJIHDX12 per tap" "BUJIHDX4 -> BUJIHDX12"
check_nonnegative "Setup WNS ps" "$SETUP_WNS_PS"
check_zero_number "Setup TNS ps" "$SETUP_TNS_PS"
check_eq "Setup violating path count" "0" "$SETUP_VIOLATING_PATHS"
check_nonnegative "Real timed WNS ps" "$REAL_TIMED_WNS_PS"
check_zero_number "Real timed TNS ps" "$REAL_TIMED_TNS_PS"
check_eq "Real timed violating path count" "0" "$REAL_TIMED_VIOLATING_PATHS"
check_eq "Max transition violations" "0" "$MAX_TRANSITION"
check_eq "Max capacitance violations" "0" "$MAX_CAPACITANCE"
check_eq "Max fanout violations" "0" "$MAX_FANOUT"
check_eq "RO_tune4 instance count" "2" "$RO_TUNE4_COUNT"
check_eq "mptdc_osc_stub residue count" "0" "$OSC_STUB_COUNT"
check_eq "BUHDX4 instance count" "0" "$BUHDX4_COUNT"
check_eq "BUHDX12 instance count" "0" "$BUHDX12_COUNT"
check_eq "BUJIHDX4 instance count" "8" "$BUJIHDX4_COUNT"
check_eq "BUJIHDX12 instance count" "8" "$BUJIHDX12_COUNT"
check_eq "RAW_RO_CLOCKS_FOUND" "16" "$RAW_RO_CLOCKS_FOUND"
check_eq "BUFFER_PHASE_CLOCKS_FOUND" "16" "$BUFFER_PHASE_CLOCKS_FOUND"
check_eq "BUFFER_PHASE_CLOCKS_EXPECTED" "16" "$BUFFER_PHASE_CLOCKS_EXPECTED"
check_eq "BUFFER_PHASE_CLOCKS_IN_ASYNC_GROUP" "YES" "$BUFFER_PHASE_ASYNC"
check_eq "CLK_SYS_ASYNC_TO_BUFFER_PHASE_CLOCKS" "YES" "$CLK_SYS_ASYNC"
check_eq "PD intentional Vernier paths matched" "64" "$PD_PATHS_MATCHED"
check_eq "PD intentional Vernier sources matched" "8" "$PD_SOURCES_MATCHED"
check_eq "PD intentional Vernier exception applied" "YES" "$PD_EXCEPTION_APPLIED"
check_eq "PD intentional Vernier overmatch" "NO" "$PD_EXCEPTION_OVERMATCH"
check_eq "PD intentional Vernier undermatch" "NO" "$PD_EXCEPTION_UNDERMATCH"
check_eq "UNKNOWN_REVIEW_REQUIRED count" "0" "$UNKNOWN_REVIEW_REQUIRED"
check_eq "ACTIVE_SDC_FAILURE_COUNT" "0" "$ACTIVE_SDC_FAILURES"
check_eq "Report helpers status" "PASS" "$HELPERS_STATUS"
check_eq "Summary/raw agreement status" "PASS" "$SUMMARY_RAW_AGREEMENT"
check_eq "FAST_TAG_MAPPING_PARSE_STATUS" "PASS" "$FAST_TAG_MAPPING_PARSE_STATUS"
check_eq "FAST_TAG_MAPPING_STATUS" "PASS" "$FAST_TAG_MAPPING_STATUS"
check_eq "EXACT_FAST_TAG_REPAIR_STATUS" "PASS" "$EXACT_REPAIR_STATUS"

if [[ "$EXACT_SOURCE_CELL_REQUESTED" == "NO" || -z "$EXACT_SOURCE_CELL_REQUESTED" ]]; then
  record_check "FAST_TAG_EXACT_SOURCE_CELL_REQUESTED" "not required for Repair8" "${EXACT_SOURCE_CELL_REQUESTED:-MISSING}" WARN
else
  check_in "FAST_TAG_EXACT_SOURCE_CELL_RESULT" "PASS_FINAL_VERIFIED or not requested" "$EXACT_SOURCE_CELL_RESULT" "PASS_FINAL_VERIFIED"
fi

check_file_any "netlist" \
  mptdc_axis_core.postsyn.v \
  outputs/mptdc_axis_core.postsyn.v \
  05_outputs/mptdc_axis_core.postsyn.v
check_file_any "SDC" \
  mptdc_axis_core.postsyn.sdc \
  outputs/mptdc_axis_core.postsyn.sdc \
  05_outputs/mptdc_axis_core.postsyn.sdc
check_file_any "final SDC overlay" \
  final_sdc_overlay_used.sdc \
  02_constraints/final_sdc_overlay_used.sdc
check_file_any "final filelist" \
  final_filelist_used.f \
  02_constraints/final_filelist_used.f
check_file_any "timing summary" \
  timing_summary.rpt \
  03_reports/timing_summary.rpt
check_file_any "design rules" \
  report_design_rules.rpt \
  03_reports/report_design_rules.rpt

if [[ -n "$PACKAGE_CHECKS" && -f "$PACKAGE_CHECKS" ]]; then
  package_failures="$(awk -F'\t' 'NR > 1 && $4 != "PASS" {bad++} END {print bad+0}' "$PACKAGE_CHECKS")"
  check_eq "PACKAGE_CHECKS.tsv failures" "0" "$package_failures"
fi

GENUS_WNS_MARGIN_LOW="UNKNOWN"
if [[ -n "${SETUP_WNS_PS:-}" && "$SETUP_WNS_PS" != "NA" ]] && awk -v v="$SETUP_WNS_PS" 'BEGIN { exit ((v + 0) < 20.0 ? 0 : 1) }'; then
  GENUS_WNS_MARGIN_LOW="YES"
else
  GENUS_WNS_MARGIN_LOW="NO"
fi
record_check "GENUS_WNS_MARGIN_LOW" "warn if WNS < 20 ps" "$GENUS_WNS_MARGIN_LOW" WARN

{
  echo "# MPTDC Pre-PNR Gate"
  echo "run_id=${RUN_ID:-$(basename "$SOURCE_ROOT")}"
  echo "source_kind=$SOURCE_KIND"
  echo "source_root=$SOURCE_ROOT"
  echo "summary=$SUMMARY"
  echo
  printf "check\texpected\tactual\tstatus\n"
  cat "$CHECK_TMP"
} >&2

if [[ -s "$FAIL_TMP" ]]; then
  if [[ "${MPTDC_PRE_PNR_GATE_ALLOW_REVIEW:-0}" == "1" ]]; then
    echo "PRE_PNR_GATE=REVIEW_OVERRIDE"
    echo "PRE_PNR_GATE_SOURCE=$SOURCE_ROOT"
    echo "PRE_PNR_GATE_KIND=$SOURCE_KIND"
    echo "GENUS_WNS_MARGIN_LOW=$GENUS_WNS_MARGIN_LOW"
    echo "PRE_PNR_GATE_FAILURES:"
    cat "$FAIL_TMP"
    exit 0
  fi
  echo "PRE_PNR_GATE=FAIL"
  echo "PRE_PNR_GATE_SOURCE=$SOURCE_ROOT"
  echo "PRE_PNR_GATE_KIND=$SOURCE_KIND"
  echo "GENUS_WNS_MARGIN_LOW=$GENUS_WNS_MARGIN_LOW"
  echo "PRE_PNR_GATE_FAILURES:"
  cat "$FAIL_TMP"
  exit 4
fi

echo "PRE_PNR_GATE=PASS"
echo "PRE_PNR_GATE_SOURCE=$SOURCE_ROOT"
echo "PRE_PNR_GATE_KIND=$SOURCE_KIND"
echo "GENUS_WNS_MARGIN_LOW=$GENUS_WNS_MARGIN_LOW"
