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
  --genus-run-id <id>     Genus run ID under work/genus/ and/or handoff root.
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

if [[ -n "$RUN_ID" ]]; then
  [[ -z "$RUN_DIR" ]] && RUN_DIR="$MPTDC_GENUS_WORK/$RUN_ID"
  [[ -z "$HANDOFF_DIR" ]] && HANDOFF_DIR="$MPTDC_GENUS_HANDOFF_ROOT/$RUN_ID"
fi

if [[ -n "$RUN_DIR" && -z "$RUN_ID" ]]; then
  RUN_ID="$(basename "$RUN_DIR")"
fi

if [[ -z "$RUN_ID" && -z "$RUN_DIR" && -z "$HANDOFF_DIR" ]]; then
  echo "ERROR: provide --genus-run-id or --genus-run-dir" >&2
  usage >&2
  exit 2
fi

SOURCE_KIND=""
SOURCE_ROOT=""
SUMMARY=""
PACKAGE_CHECKS=""

is_handoff_dir() {
  [[ -f "$1/00_decision/SUMMARY.md" || -f "$1/00_decision/PACKAGE_CHECKS.tsv" ]]
}

if [[ -n "$HANDOFF_DIR" && -d "$HANDOFF_DIR" ]] && is_handoff_dir "$HANDOFF_DIR"; then
  SOURCE_KIND="handoff"
  SOURCE_ROOT="$HANDOFF_DIR"
  SUMMARY="$HANDOFF_DIR/00_decision/SUMMARY.md"
  PACKAGE_CHECKS="$HANDOFF_DIR/00_decision/PACKAGE_CHECKS.tsv"
elif [[ -n "$RUN_DIR" && -d "$RUN_DIR" ]] && is_handoff_dir "$RUN_DIR"; then
  SOURCE_KIND="handoff"
  SOURCE_ROOT="$RUN_DIR"
  SUMMARY="$RUN_DIR/00_decision/SUMMARY.md"
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

check_file() {
  local label="$1"
  local path="$2"
  if [[ -f "$path" ]]; then
    record_check "$label" "file exists" "$path" PASS
  else
    record_check "$label" "file exists" "$path" FAIL
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

if [[ "$SOURCE_KIND" == "handoff" ]]; then
  check_file "handoff netlist" "$SOURCE_ROOT/05_outputs/mptdc_top_asic.postsyn.v"
  check_file "handoff SDC" "$SOURCE_ROOT/05_outputs/mptdc_top_asic.postsyn.sdc"
  check_file "handoff Innovus setup" "$SOURCE_ROOT/06_innovus_import/post_synth/mptdc_top_asic.invs_setup.tcl"
else
  check_file "source netlist" "$SOURCE_ROOT/outputs/mptdc_top_asic.postsyn.v"
  check_file "source SDC" "$SOURCE_ROOT/outputs/mptdc_top_asic.postsyn.sdc"
  check_file "source Innovus setup" "$SOURCE_ROOT/outputs/post_synth/mptdc_top_asic.invs_setup.tcl"
fi

if [[ -n "$PACKAGE_CHECKS" && -f "$PACKAGE_CHECKS" ]]; then
  package_failures="$(awk -F'\t' 'NR > 1 && $4 != "PASS" {bad++} END {print bad+0}' "$PACKAGE_CHECKS")"
  check_eq "PACKAGE_CHECKS.tsv failures" "0" "$package_failures"
fi

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
    echo "PRE_PNR_GATE_FAILURES:"
    cat "$FAIL_TMP"
    exit 0
  fi
  echo "PRE_PNR_GATE=FAIL"
  echo "PRE_PNR_GATE_SOURCE=$SOURCE_ROOT"
  echo "PRE_PNR_GATE_FAILURES:"
  cat "$FAIL_TMP"
  exit 4
fi

echo "PRE_PNR_GATE=PASS"
echo "PRE_PNR_GATE_SOURCE=$SOURCE_ROOT"
echo "PRE_PNR_GATE_KIND=$SOURCE_KIND"
